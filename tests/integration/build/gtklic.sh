#!/bin/bash
# Building son-gtklic
echo "SON-GTKLIC"
docker build -f ../../../son-gtklic/Dockerfile -t registry.sonata-nfv.eu:5000/son-gtklic:v3.1 ../../../son-gtklic/
