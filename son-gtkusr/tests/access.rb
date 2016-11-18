require 'json'

def parse_json(message)
  # Check JSON message format
  begin
    parsed_message = JSON.parse(message) # parse json message
  rescue JSON::ParserError => e
    # If JSON not valid, return with errors
    logger.error "JSON parsing: #{e}"
    return message, e.to_s + "\n"
  end

  return parsed_message, nil
end

def userbased
  # curl -d "client_id=admin-cli" -d "username=user1" -d "password=1234" -d "grant_type=password" "http://localhost:8081/auth/realms/SONATA/protocol/openid-connect/token"
  client_id = "register"
  @usrname = "user"
  pwd = "1234"
  grt_type = "password"
  http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
  # puts `curl -X POST --data "client_id=#{client_id}&username=#{usrname}"&password=#{pwd}&grant_type=#{grt_type} #{http_path}`

  uri = URI(http_path)
  res = Net::HTTP.post_form(uri, 'client_id' => client_id,
                            'username' => @usrname,
                            'password' => pwd,
                            'grant_type' => grt_type)
  #puts "RES.BODY: ", res.body


  if res.body['access_token']
    #if env['HTTP_AUTHORIZATION']
    # puts "env: ", env['HTTP_AUTHORIZATION']
    # access_token = env['HTTP_AUTHORIZATION'].split(' ').last
    # puts "access_token: ", access_token
    # {"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiJjYzY3MmUzYS1mZTVkLTQ4YjItOTQ4My01ZTYxZDNiNGJjMGEiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiYWRtaW4tY2xpIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiNTkwYzlhNGUtYzljNC00OTU1LTg1NDAtYTViOTM2ODM5NjEzIiwiYWNyIjoiMSIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwiYWxsb3dlZC1vcmlnaW5zIjpbXSwicmVzb3VyY2VfYWNjZXNzIjp7fSwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.T_GB_kBtZk-gmFNJ5rC2sJpNl4V3TUyhixq76hOi5MbgDbo_FfuKRomxviAeQi-RdJPIEffdzrVmaYXZVQHufpaYx9p90GQd3THQWMyZD50zMY40j-XlungaGKjizWNxaywvGXBMvDE_qYp0hr4Uewm4evO_NRRI1bWQLeaeJ3oHr1_p9vFZf5Kh8tZYR-dQSWuESvHhZrJAqHTzXlYYMRBqfjDyAgUhm8QbbtmDtPr0kkkIh1TmXevkZbm91mrS-9jWrS4zGZE5LiT5KdWnMs9P8FBR1p3vywwIu_z-0MF8_DIMJWa7ApZAXjtrszXAYVfCKsaisjjD9HacgpE-4w","expires_in":300,"refresh_expires_in":1800,"refresh_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiIyOTRmZjc5Yy01ZWIxLTQwNDgtYmM1NS03NjcwOGU1Njg1YzMiLCJleHAiOjE0NzY0NDYwOTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiUmVmcmVzaCIsImF6cCI6ImFkbWluLWNsaSIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjU5MGM5YTRlLWM5YzQtNDk1NS04NTQwLWE1YjkzNjgzOTYxMyIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwicmVzb3VyY2VfYWNjZXNzIjp7fX0.WGHvTiVc08xuVCDM5YLlvIzvBgz0aJ3OY3-VGmKSyI-fDLfbp9LSLkPsIqiKO9mDjybSfEkrNmPBd60lWecUC43DacVhVbiLEU9cJdMnjQjrU0P3wg1HFQmcG8exylJMzWoAbJzm893SP-kgKVYCnbQ55Os1-oT1ClHr3Ts6BHVgz5FWrc3dk6DqOrGAxmoJLQUgNJ5jdF-udt-j81OcBTtC3b-RXFXlRu3AyJ0p-UPiu4_HkKBVdg0pmycuN0v0it-TxR_mlM9lhvdVMGXLD9_-PUgklfc6XisdCrGa_b9r06aQCiekXGWptLoFF1Oz__g2_v4Gsrzla5YKBZzGfA","token_type":"bearer","id_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiI5NWVmMGY0Yi1lODIyLTQwMTAtYWU1NS05N2YyYTEzZWViMzkiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiSUQiLCJhenAiOiJhZG1pbi1jbGkiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI1OTBjOWE0ZS1jOWM0LTQ5NTUtODU0MC1hNWI5MzY4Mzk2MTMiLCJhY3IiOiIxIiwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.FrwYdv1S8mqivHjsyA93ycl10z2tisVJraUGcBJzle060nCO69ZEa0fzrMMCbSkjY1JAwjP92d7_ixuWpcUVvQLkesxKOgcBc8LVhClyh3__8p46kIwfrJYMZQt0cJ6f6nASX1yaySE9sDgl3ElkW0vz-i9vhEXkIh6m-EuC7lH0ZIIL-39-occssq7G5hDleDUMThno8sEsl8rgtV-GdAfjKIwi-yOB0X8K1RrfDarccwA3XB0R8nHAbInZGsrF114KsBuaEvWjKki4m86xFkfPPuSlvWaVRtCziiTBqrBZ_Qna6wI9FfAOiTzPXE5AfFtDowih6d-26kT_jd_7GA","not-before-policy":0,"session_state":"590c9a4e-c9c4-4955-8540-a5b936839613"}

    parsed_res, code = parse_json(res.body)
    @access_token = parsed_res['access_token']
    puts "ACCESS_TOKEN RECEIVED", parsed_res['access_token']
  else
    401
  end
end

def clientbased
  # curl -d "client_id=admin-cli" -d "username=user1" -d "password=1234" -d "grant_type=password" "http://localhost:8081/auth/realms/SONATA/protocol/openid-connect/token"
  http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
  auth = "Basic YWRhcHRlcjpkZjdlODE2ZC0wMzM3LTRmYmUtYTNmNC03YjUyNjNlYWJhOWY=\n"
  # puts `curl -X POST --data "client_id=#{client_id}&username=#{usrname}"&password=#{pwd}&grant_type=#{grt_type} #{http_path}`

  uri = URI(http_path)
  res = Net::HTTP.post_form(uri, 'client_id' => 'adapter',
                            'client_secret' => 'df7e816d-0337-4fbe-a3f4-7b5263eaba9f',
                            'grant_type' => 'client_credentials'
                            )
  puts "RES.HEADER: ", res.header
  puts "RES.BODY: ", res.body


  if res.body['access_token']
    #if env['HTTP_AUTHORIZATION']
    # puts "env: ", env['HTTP_AUTHORIZATION']
    # access_token = env['HTTP_AUTHORIZATION'].split(' ').last
    # puts "access_token: ", access_token
    # {"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiJjYzY3MmUzYS1mZTVkLTQ4YjItOTQ4My01ZTYxZDNiNGJjMGEiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiYWRtaW4tY2xpIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiNTkwYzlhNGUtYzljNC00OTU1LTg1NDAtYTViOTM2ODM5NjEzIiwiYWNyIjoiMSIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwiYWxsb3dlZC1vcmlnaW5zIjpbXSwicmVzb3VyY2VfYWNjZXNzIjp7fSwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.T_GB_kBtZk-gmFNJ5rC2sJpNl4V3TUyhixq76hOi5MbgDbo_FfuKRomxviAeQi-RdJPIEffdzrVmaYXZVQHufpaYx9p90GQd3THQWMyZD50zMY40j-XlungaGKjizWNxaywvGXBMvDE_qYp0hr4Uewm4evO_NRRI1bWQLeaeJ3oHr1_p9vFZf5Kh8tZYR-dQSWuESvHhZrJAqHTzXlYYMRBqfjDyAgUhm8QbbtmDtPr0kkkIh1TmXevkZbm91mrS-9jWrS4zGZE5LiT5KdWnMs9P8FBR1p3vywwIu_z-0MF8_DIMJWa7ApZAXjtrszXAYVfCKsaisjjD9HacgpE-4w","expires_in":300,"refresh_expires_in":1800,"refresh_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiIyOTRmZjc5Yy01ZWIxLTQwNDgtYmM1NS03NjcwOGU1Njg1YzMiLCJleHAiOjE0NzY0NDYwOTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiUmVmcmVzaCIsImF6cCI6ImFkbWluLWNsaSIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjU5MGM5YTRlLWM5YzQtNDk1NS04NTQwLWE1YjkzNjgzOTYxMyIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwicmVzb3VyY2VfYWNjZXNzIjp7fX0.WGHvTiVc08xuVCDM5YLlvIzvBgz0aJ3OY3-VGmKSyI-fDLfbp9LSLkPsIqiKO9mDjybSfEkrNmPBd60lWecUC43DacVhVbiLEU9cJdMnjQjrU0P3wg1HFQmcG8exylJMzWoAbJzm893SP-kgKVYCnbQ55Os1-oT1ClHr3Ts6BHVgz5FWrc3dk6DqOrGAxmoJLQUgNJ5jdF-udt-j81OcBTtC3b-RXFXlRu3AyJ0p-UPiu4_HkKBVdg0pmycuN0v0it-TxR_mlM9lhvdVMGXLD9_-PUgklfc6XisdCrGa_b9r06aQCiekXGWptLoFF1Oz__g2_v4Gsrzla5YKBZzGfA","token_type":"bearer","id_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiI5NWVmMGY0Yi1lODIyLTQwMTAtYWU1NS05N2YyYTEzZWViMzkiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiSUQiLCJhenAiOiJhZG1pbi1jbGkiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI1OTBjOWE0ZS1jOWM0LTQ5NTUtODU0MC1hNWI5MzY4Mzk2MTMiLCJhY3IiOiIxIiwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.FrwYdv1S8mqivHjsyA93ycl10z2tisVJraUGcBJzle060nCO69ZEa0fzrMMCbSkjY1JAwjP92d7_ixuWpcUVvQLkesxKOgcBc8LVhClyh3__8p46kIwfrJYMZQt0cJ6f6nASX1yaySE9sDgl3ElkW0vz-i9vhEXkIh6m-EuC7lH0ZIIL-39-occssq7G5hDleDUMThno8sEsl8rgtV-GdAfjKIwi-yOB0X8K1RrfDarccwA3XB0R8nHAbInZGsrF114KsBuaEvWjKki4m86xFkfPPuSlvWaVRtCziiTBqrBZ_Qna6wI9FfAOiTzPXE5AfFtDowih6d-26kT_jd_7GA","not-before-policy":0,"session_state":"590c9a4e-c9c4-4955-8540-a5b936839613"}

    parsed_res, code = parse_json(res.body)
    @access_token = parsed_res['access_token']
    puts "ACCESS_TOKEN RECEIVED", parsed_res['access_token']
  else
    401
  end
end

# clientbased