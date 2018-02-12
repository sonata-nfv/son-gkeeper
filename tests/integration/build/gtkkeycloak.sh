#!/bin/bash
# Building son-keycloak
echo "SON-KEYCLOAK"
docker build -f ../../../son-keycloak/Dockerfile -t registry.sonata-nfv.eu:5000/son-keycloak:v3.1 ../../../son-keycloak/
