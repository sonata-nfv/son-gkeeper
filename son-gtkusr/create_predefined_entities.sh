#!/bin/bash


KEYCLOAK_PORT=8080
KEYCLOAK_USER=admin
KEYCLOAK_PASSWORD=admin
KEYCLOAK_URL=http://localhost:$KEYCLOAK_PORT
ADAPTER_URL=http://adapter:4021/api/v1/config

# Param: $1 = realm name
function create_realm() {
	/opt/jboss/keycloak/bin/kcadm.sh create realms -s realm=$1 -s enabled=true -s sslRequired=none -i > /dev/null
	ret=$?
	if [ $ret -eq 0 ]; then
        	echo "Created realm [$1]"
	fi
	return $ret
}

# Params: $1 = realm, $2 = client name, $3 = redirect URI
function create_client() {
	cid=$(/opt/jboss/keycloak/bin/kcadm.sh create clients -r $1 -s clientId=$2 -s "redirectUris=[\"$3\"]" -s serviceAccountsEnabled=true -s authorizationServicesEnabled=true -i)
	ret=$?
	if [ $ret -eq 0 ]; then
        	echo "Created client [$2] for realm [$1] id=$cid"
		# /opt/jboss/keycloak/bin/kcadm.sh update clients/$cid -r sonata -s serviceAccountsEnabled=true -s authorizationServicesEnabled=true
	fi
	return $ret
}

# Params: $1 = realm, $2 = role name, $3 = role description
function create_realm_role() {
	/opt/jboss/keycloak/bin/kcadm.sh create roles -r $1 -s name=$2 -s description="$3" -i > /dev/null
	ret=$?
	if [ $ret -eq 0 ]; then
        	echo "Created role [$2] for realm [$1]"
	fi
	return $ret
}

# Params: $1 = realm, $2 = client id
function get_client_secret() {
# Attempt to retrieve the client secret
        secret=$(keycloak/bin/kcadm.sh get clients/$2/installation/providers/keycloak-oidc-keycloak-json -r $1 | grep secret | sed 's/"//g' | awk '{print $3}' 2>/dev/null)
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
/opt/jboss/keycloak/bin/kcadm.sh config credentials --server $KEYCLOAK_URL/auth --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD -o

if [ $? -ne 0 ]; then 
	echo "Unable to login as admin"
	exit 1
fi

# Creating a realm:
create_realm sonata
 
# Creating a client:
create_client_out=$(create_client sonata adapter "http://localhost:8081/adapter")
echo $create_client_out
adapter_cid=$(echo $create_client_out | awk -F id= '{print $2}')
#echo "adapter_cid=$adapter_cid"

# Creating a realm role:
create_realm_role sonata GK "see_catalogues, see_repositories"
create_realm_role sonata Catalogues "see_gatekeeper"
create_realm_role sonata Repositories "see_gatekeeper"
create_realm_role sonata Customer "read_repositories, write_repositories, run_repositories, run_catalogues"
create_realm_role sonata Developer "read_catalogues, write_catalogues"

if [ "$ADAPTER_URL" ]; then 
	adapter_secret=$(get_client_secret sonata $adapter_cid)
	echo "adapter_secret=$adapter_secret"
	if [ $(curl -X POST -o /dev/null -s -w "%{http_code}" -d "secret=$adapter_secret" $ADAPTER_URL) -eq 200 ]; then
		echo "Secret of client [adapter] successfully POSTed to $ADAPTER_URL"
	else
		echo "Unable to POST secret to $ADAPTER_URL"
	fi
fi
