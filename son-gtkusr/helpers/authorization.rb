##
## Copyright (c) 2015 SONATA-NFV
## ALL RIGHTS RESERVED.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
## Neither the name of the SONATA-NFV
## nor the names of its contributors may be used to endorse or promote
## products derived from this software without specific prior written
## permission.
##
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through
## the Horizon 2020 and 5G-PPP programmes. The authors would like to
## acknowledge the contributions of their colleagues of the SONATA
## partner consortium (www.sonata-nfv.eu).

require 'json'
require 'sinatra'
require 'net/http'
require_relative '../helpers/init'

# Adapter-Keycloak API class
class Keycloak < Sinatra::Application

  # code, user_info = userinfo(user_token)
  # if code != '200'
  #  halt code.to_i, {'Content-type' => 'application/json'}, user_info
  # end
  # logger.debug "Adapter: User info: #{user_info}"

  # Role check; Allows total authorization to admin roles
  def admin_check(token_content)
    realm_roles = token_content['realm_access']['roles']
    if token_content['resource_access'].include?('realm-management')
      resource_roles = token_content['resource_access']['realm-management']['roles']
      true if (realm_roles.include?('admin')) && (resource_roles.include?('realm-admin'))
    end
    false
  end

  def process_request(uri, method)
    # Parse uri path
    path = URI(uri).path.split('/')[1]
    data = URI(uri).path.split('/')[2]
    p "PATH=#{path}"
    p "DATA=#{data}"

    # Find mapped resource to path
    # TODO: CHECK IF IS A VALID RESOURCE FROM DATABASE
    # resources = @@auth_mappings['resources']
    # p "RESOURCES", resources

    # Gather database resources
    begin
      resource = Sp_resource.find_by({'resources.URI' => path }) #'resources.resource_name' => new_ns['name'],
      p "resource=#{resource}"
        # Continue
    rescue Mongoid::Errors::DocumentNotFound => e
      # 'The resource is not found or available'
      p 'Resource not found'
      return nil
    end

    resource = resource.to_json
    p "RESOURCE_JSON=#{resource}"
    resource, errors = parse_json(resource)
    p "RESOURCE_STRING=#{resource}"
    resource_data = resource['resources'].find {|resource_data| resource_data['URI'] == path }
    p "resource_data=#{resource_data}"

    operation = nil
    resource_data['associated_permissions'].each {|permission|
      operation = permission if permission['action'] == method
    }

    return if operation.nil?
    # json_error(403, 'The resource operation is not available')
    p "FOUND_OPERATION=#{operation}"
    request = {"resources" => resource_data, "policies" => resource['policies'], "operation" => operation}
  end

  def get_token_claims(token_content)
    claims = {}
    claims['name'] = token_content['name']
    claims['preferred_username'] = token_content['preferred_username']
    claims['username'] = token_content['username']
    claims['email'] = token_content['email']
    claims['realm_access'] = token_content['realm_access']
    claims['resource_access'] = token_content['resource_access']
    claims
  end

  def authorize?(user_token, request)
    refresh_adapter
    # Obtain SP Public Key
    @@sp_public_key = get_public_key if @@sp_public_key.nil?

    # Check token
    token_payload, token_header = decode_token(user_token, @@sp_public_key)

    # Evaluate request
    # 1. Get 'apply-policy' allowed roles
    # 2. Check 'policies' for allowed roles
    # 3. Check access token claims

    log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    STDOUT.reopen(log_file)
    STDOUT.sync = true
    logger.debug "Adapter: Token Payload: #{token_payload.to_s}, Token Header: #{token_header.to_s}"

    # requested_action = request['operation']['action']
    allowed_roles = request['operation']['apply_policy']

    # logger.debug "Adapter: Requested Action: #{requested_action}"
    logger.debug "Adapter: Required Role: #{allowed_roles}"

    # Check access token claims
    begin
      logger.debug "Adapter: Token Payload: #{token_payload.to_s}, Token Header: #{token_header.to_s}"
      logger.debug "Adapter: Token Name=#{token_payload['name']},
      Preferred_username=#{token_payload['preferred_username']},
      Username=#{token_payload['username']}"
      # token_payload['email']
      # token_payload['realm_access']
      # token_payload['resource_access']

      token_realm_access_roles = token_payload['realm_access']['roles']
      p 'token_realm_access_roles', token_realm_access_roles
    rescue
      token_realm_access_roles = nil
    end
    # Resource access roles (client based roles)
    begin
      token_resource_access_roles = token_payload['resource_access']
      p 'token_payload', token_resource_access_roles
    rescue
      token_resource_access_roles = nil
      p 'token_payload', token_resource_access_roles
    end

    authorized = nil
    if allowed_roles.is_a?(Array)
      p 'required_roles', allowed_roles
      allowed_roles.each { |role|
        p "role", role
        authorized = token_realm_access_roles.include?(role)
        p "authorized", authorized
        if authorized
          policy_data = request['policies'].find {|policy| policy['name'] == role}
          p "policy_data", policy_data
          authorized = false if policy_data['logic'] != 'positive'
          break
        end
      }
      p "authorized2", authorized

      unless authorized
        allowed_roles.each { |role|
          p "role", role
          token_resource_access_roles.each { |resource_access, values|
            p "resource_access", resource_access
            authorized = values['roles'].include?(role)
            p "authorized3", authorized
            if authorized
              policy_data = request['policies'].find {|policy| policy['name'] == role}
              p "policy_data", policy_data
              authorized = false if policy_data['logic'] != 'positive'
              break
            end
          }
          p "authorized4", authorized
          break if authorized
        }
        p "authorized5", authorized
      end
    end
    STDOUT.sync = false

    # Response => 20X or 40X
    case authorized
      when true
        return 200, 'Authorized'
      else
        return 403, 'Not authorized'
    end
  end

  # DEPRECATED
  def authenticate(client_id, username, password, grant_type)
    http_path = "http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/realms/#{@@realm_name}/protocol/openid-connect/token"
    # puts `curl -X POST --data "client_id=#{client_id}&username=#{usrname}"&password=#{pwd}&grant_type=#{grt_type} #{http_path}`

    uri = URI(http_path)
    res = nil
    case grant_type
      when 'password' # -> user
        res = Net::HTTP.post_form(uri, 'client_id' => client_id,
                                  'client_secret' => password,
                                  'grant_type' => grant_type)

      when 'client_credentials' # -> service
        res = Net::HTTP.post_form(uri, 'client_id' => client_id,
                                  'username' => username,
                                  'password' => password,
                                  'grant_type' => grant_type)
      else
        halt 400
    end

    if res.body['id_token']
      parsed_res, code = parse_json(res.body)
      id_token = parsed_res['id_token']
      # puts "ID_TOKEN RECEIVED"# , parsed_res['access_token']
    else
      halt 401, "ERROR: ACCESS DENIED!"
    end
  end

  # DEPRECATED
  def old_process_request(uri, method)
    log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    STDOUT.reopen(log_file)
    STDOUT.sync = true

    # Parse uri path
    path = URI(uri).path.split('/')[1]
    p "path", path

    # Find mapped resource to path
    # TODO: CHECK IF IS A VALID RESOURCE FROM DATABASE
    resources = @@auth_mappings['resources']
    p "RESOURCES", resources

    # Gather database resources
    # Check if NS already exists in the catalogue by name, vendor and version
    # begin
    #  resource = Sp_resource.find_by({ 'resources.resource_name' => new_ns['name'],
    #                             'resources.URI' => path })
    # Continue
    #rescue Mongoid::Errors::DocumentNotFound => e
    #  json_return 401, 'Resource not found'
    #end

    resource = nil
    # p "PATHS", @@auth_mappings['paths']
    @@auth_mappings['paths'].each { |k, v|
      puts "k, v", k, v
      v.each { |kk, vv|
        puts "kk, vv", kk, vv
        if kk == path
          p "Resource found", k, kk
          resource = [k, kk]
          break
        end
      }
      p "FOUND_RESOURCE", resource
      break if resource
    }
    json_error(403, 'The resource is not available') unless resource

    # resource_data = resource['resources']

    unless @@auth_mappings['paths'][resource[0]][resource[1]].key?(method)
      json_error(403, 'The resource operation is not available')
    else
      operation = @@auth_mappings['paths'][resource[0]][resource[1]][method]
      puts "FOUND_OPERATION", operation
      STDOUT.sync = false
      request = {"resource" => resource[0], "type" => resource[1], "operation" => operation}
    end
  end

  # DEPRECATED
  def old_authorize?(user_token, request)
    refresh_adapter
    # => Check token
    public_key = get_public_key
    # p "SETTINGS", settings.keycloak_pub_key
    token_payload, token_header = decode_token(user_token, public_key)
    # puts "payload", token_payload

    # => evaluate request
    # Find mapped resource to path
    # required_role is build following next pattern:
    # operation
    # operation_resource
    # operation_resource_type

    log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    STDOUT.reopen(log_file)
    STDOUT.sync = true

    logger.debug "Adapter: Token Payload: #{token_payload.to_s}, Token Header: #{token_header.to_s}"

    required_role = 'role_' + request['operation'] + '-' + request['resource']
    # p "REQUIRED ROLE", required_role
    logger.debug "Adapter: Required Role: #{required_role}"

    # => Check token roles
    begin
      token_realm_access_roles = token_payload['realm_access']['roles']
    rescue
      json_error(403, 'No permissions')
    end

    # TODO: Resource access roles (services) will be implemented later
    token_resource_access_resources = token_payload['resource_access']
    # .
    # .
    # .
    # TODO: Evaluate special roles (customer,developer,etc...)
    # .
    # .
    # .

    p "realm_access_roles", token_realm_access_roles
    code, realm_roles = get_realm_roles

    p "realm_roles", realm_roles
    parsed_realm_roles, errors = parse_json(realm_roles)
    # p "Realm_roles_PARSED", parsed_realm_roles

    authorized = false
    token_realm_access_roles.each { |role|
      # puts "ROLE TO INSPECT", role

      token_role_repr = parsed_realm_roles.find {|x| x['name'] == role}
      unless token_role_repr
        json_error(403, 'No permissions')
      end

      puts "ROLE_DESC", token_role_repr['description']
      role_perms = token_role_repr['description'].tr('${}', '').split(',')
      puts "ROLE_PERM", role_perms

      if role_perms.include?(required_role)
        authorized = true
      end
    }

    STDOUT.sync = false

    #=> Response => 20X or 40X
    case authorized
      when true
        return 200, nil
      else
        return 403, 'User is not authorized'
    end
  end
=begin
  def _route_authorization
    logger.info 'Authorization request received at /authorize'
    # Return if content-type is not valid
    # log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    # STDOUT.reopen(log_file)
    # STDOUT.sync = true
    # puts "Content-Type is " + request.content_type
    if request.content_type
      logger.info "Request Content-Type is #{request.content_type}"
    end
    # halt 415 unless (request.content_type == 'application/x-www-form-urlencoded' or request.content_type == 'application/json')
    # We will accept both a JSON file, form-urlencoded or query type
    # Compatibility support
    case request.content_type
      when 'application/x-www-form-urlencoded'
        # Validate format
        # form_encoded, errors = request.body.read
        # halt 400, errors.to_json if errors

        # p "FORM PARAMS", form_encoded
        # form = Hash[URI.decode_www_form(form_encoded)]
        # mat
        # p "FORM", form
        # keyed_params = keyed_hash(form)
        # halt 401 unless (keyed_params[:'path'] and keyed_params[:'method'])

        # Request is a QUERY TYPE
        # Get request parameters
        logger.info "Request parameters are #{params}"
        # puts "Input params", params
        keyed_params = keyed_hash(params)
        # puts "KEYED_PARAMS", keyed_params
        # params examples: {:path=>"catalogues", :method=>"GET"}
        # Halt if 'path' and 'method' are not included
        json_error(401, 'Parameters "path=" and "method=" not found') unless (keyed_params[:path] and keyed_params[:method])

      when 'application/json'
        # Compatibility support for JSON content-type
        # Parses and validates JSON format
        form, errors = parse_json(request.body.read)
        halt 400, errors.to_json if errors
        # p "FORM", form
        logger.info "Request parameters are #{form.to_s}"
        keyed_params = keyed_hash(form)
        json_error(401, 'Parameters "path=" and "method=" not found') unless (keyed_params[:path] and keyed_params[:method])
      else
        # Request is a QUERY TYPE
        # Get request parameters
        logger.info "Request parameters are #{params}"
        keyed_params = keyed_hash(params)
        # puts "KEYED_PARAMS", keyed_params
        # params examples: {:path=>"catalogues", :method=>"GET"}
        # Halt if 'path' and 'method' are not included
        json_error(401, 'Parameters "path=" and "method=" not found') unless (keyed_params[:path] and keyed_params[:method])
      # halt 401, json_error("Invalid Content-type")
    end

    # puts "PATH", keyed_params[:'path']
    # puts "METHOD",keyed_params[:'method']
    # Check the provided path to the resource and the HTTP method, then build the request
    request = process_request(keyed_params[:path], keyed_params[:method])

    logger.info 'Evaluating Authorization request'
    # Authorization process
    auth_code, auth_msg = authorize?(user_token, request)
    if auth_code.to_i == 200
      halt auth_code.to_i
    else
      json_error(auth_code, auth_msg)
    end
    # STDOUT.sync = false
  end
=end
end