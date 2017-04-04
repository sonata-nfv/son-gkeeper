#!/bin/bash


KEYCLOAK_PORT=5601
KEYCLOAK_USER=admin
KEYCLOAK_PASSWORD=admin
KEYCLOAK_URL=http://localhost:$KEYCLOAK_PORT
KEYCLOAK_OPENID_TOKEN_ENDPOINT=$KEYCLOAK_URL/auth/realms/sonata/protocol/openid-connect/token
ADAPTER_URL=http://son-gtkusr:5600/api/v1/config
KCADMIN_SCRIPT=/opt/jboss/keycloak/bin/kcadm.sh

SONATA_REALM=sonata
ADAPTER_CLIENT=adapter

# Param: $1 = realm name
function create_realm() {
	$KCADMIN_SCRIPT create realms -s realm=$1 -s enabled=true -s sslRequired=none -i > /dev/null
	ret=$?
	if [ $ret -eq 0 ]; then
        	echo "Created realm [$1]"
	fi
	return $ret
}

# Params: $1 = realm, $2 = client name, $3 = redirect URI
function create_client() {
	cid=$($KCADMIN_SCRIPT create clients -r $1 -s clientId=$2 -s "redirectUris=[\"$3\"]" -s serviceAccountsEnabled=true -s authorizationServicesEnabled=true -s directAccessGrantsEnabled=true -i)
	ret=$?
	if [ $ret -eq 0 ]; then
        	echo "Created client [$2] for realm [$1] id=$cid"
		# /opt/jboss/keycloak/bin/kcadm.sh update clients/$cid -r sonata -s serviceAccountsEnabled=true -s authorizationServicesEnabled=true
	fi
	return $ret
}

# Params: $1 = realm, $2 = role name, $3 = role description
function create_realm_role() {
	$KCADMIN_SCRIPT create roles -r $1 -s name=$2 -s description="$3" -i > /dev/null
	ret=$?
	if [ $ret -eq 0 ]; then
        	echo "Created role [$2] for realm [$1]"
	fi
	return $ret
}

# Param: $1 = realm, $2 = group name
function create_group() {
	$KCADMIN_SCRIPT create groups -r $1 -s name=$2 -i > /dev/null
	ret=$?
	if [ $ret -eq 0 ]; then
        	echo "Created group [$2] for realm [$1]"
	fi
	return $ret
}

# Params: $1 = realm, $2 = client id
function get_client_secret() {
# Attempt to retrieve the client secret
        secret=$($KCADMIN_SCRIPT get clients/$2/installation/providers/keycloak-oidc-keycloak-json -r $1 | grep secret | sed 's/"//g' | awk '{print $3}' 2>/dev/null)
        ret=$?
        if [ $ret -eq 0 ]; then
        	echo "$secret"
        fi
	return $ret
}

echo
echo "------------------------------------------------------------------------"
echo "*** Verifying if Keycloak server is up and listening on $KEYCLOAK_URL"
retries=0
until [ $(curl --connect-timeout 15 --max-time 15 -k -s -o /dev/null -I -w "%{http_code}" $KEYCLOAK_URL) -eq 200 ]; do
    	#printf '.'
    	sleep 20
    	let retries="$retries+1"
    	if [ $retries -eq 12 ]; then
		echo "Timeout waiting for Keycloak on $KEYCLOAK_URL"
		exit 1
	fi
done

echo "Keycloak server detected! Creating predefined entities..."

# Log in to create session:
$KCADMIN_SCRIPT config credentials --server $KEYCLOAK_URL/auth --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD -o

if [ $? -ne 0 ]; then 
	echo "Unable to login as admin"
	exit 1
fi

# Creating a realm:
create_realm $SONATA_REALM
 
# Creating a client:
create_client_out=$(create_client $SONATA_REALM $ADAPTER_CLIENT "http://localhost:8081/adapter")
echo $create_client_out
adapter_cid=$(echo $create_client_out | awk -F id= '{print $2}')
#echo "adapter_cid=$adapter_cid"

# Creating a realm role:
create_realm_role $SONATA_REALM son-gkeeper "\${role_access-catalogue},\${role_access-repositories}"
create_realm_role $SONATA_REALM son-catalogues ""
create_realm_role $SONATA_REALM son-repositories "\${role_read-catalogue}"
create_realm_role $SONATA_REALM customer "\${role_read-repositories},\${role_write-repositories},\${role_execute-catalogue}"
create_realm_role $SONATA_REALM developer "\${role_read-catalogue},\${role_write-catalogue}"

# Creating realm groups:
create_group $SONATA_REALM developers
create_group $SONATA_REALM customers
#create_group $SONATA_REALM admins

# Capture the adapter client secret for the next set of operations
adapter_secret=$(get_client_secret $SONATA_REALM $adapter_cid)

# Attempt to get access and ID tokens. This serves two purposes:
# 1. it tests the endpoint: we make sure that the adapter client was created correctly and we have the adapter client secret, and 
# 2. it has the side effect of creating the adapter "service account" user, upon which we would like to assign roles that allow us to create users.
echo "Testing adapter client token endpoint: $KEYCLOAK_OPENID_TOKEN_ENDPOINT"
curl -k -s -o /dev/null -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials&client_id=$ADAPTER_CLIENT&client_secret=$adapter_secret" "$KEYCLOAK_OPENID_TOKEN_ENDPOINT"
#if [ $endpoint_ret -ne 200 ]; then
#	echo "Got $endpoint_ret instead of 200 OK"
#	return 1
#fi

# Add the realm-admin role to the service account associated with the adapter client
echo Adding realm-admin role to adapter service account...
$KCADMIN_SCRIPT add-roles -r $SONATA_REALM --uusername service-account-$ADAPTER_CLIENT --cclientid realm-management --rolename realm-admin

if [ "$ADAPTER_URL" ]; then 
    echo
    echo "------------------------------------------------------------------------"
    echo "*** Waiting for Adapter server is up and listening on $ADAPTER_URL"
    retries=0
    until [ $(curl -X POST -o /dev/null -s -w "%{http_code}" -d "secret=$adapter_secret" $ADAPTER_URL) -eq 200 ]; do
	sleep 20
	let retries="$retries+1"
	if [ $retries -eq 12 ]; then
	    echo "Timeout waiting for Keycloak on $ADAPTER_URL"
	    exit 1
	fi
    done
    echo "Secret of client [$ADAPTER_CLIENT] successfully POSTed to $ADAPTER_URL"
fi
