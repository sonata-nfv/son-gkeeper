# [SONATA](http://www.sonata-nfv.eu)'s Gatekeeper Package Management micro-service
[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

# Supported user stories

# Micro-service API
The Package Management API is te following:

1. 

# Tests

## Uploading a package

Assuming the package file (`sonata-demo.son`) is in the current folder, just do like

```$ curl -vi -X POST -F "package=@sonata-demo.son" http://sp.int.sonata-nfv.eu:32001/packages```

## Downloading packages

