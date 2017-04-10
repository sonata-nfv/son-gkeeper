#!/bin/bash
sleep 2
son-keycloak=$(cat /etc/hosts | grep openig | awk '{print $1}')

export KEYCLOAK_ADDRESS=$son-keycloak
