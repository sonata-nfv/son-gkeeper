# [SONATA](http://www.sonata-nfv.eu)'s Gatekeeper Service Management micro-service
[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

# Tests

## Obtain a list of available services
The full list of services registered in the Catalogues can be obrained with

```curl -vi http://sp.int.sonata-nfv.eu:32001/services```

**Note:** For this version, no user authentication/authorization is being done. In the future, with authentication/authorization mechanisms in place, this list will be adequately filtered.

## Obtain a list of services with specific attribute values
To obtain only the list of services that have specific values for some of the attributes (e.g., `status=Active`), you can do this:

```curl -vi http://sp.int.sonata-nfv.eu:32001/services?status=Active```

## Obtain specific attributes on a list of services
To obtain only specific attributes (e.g., only `uuid`, `vendor`, `name` and `version`), you can do this:

```curl -vi http://sp.int.sonata-nfv.eu:32001/services?fields=uuid,vendor,name,version```

**Note:** We are assuming there aren't any attributes of the entity called `fields`.

## Check directly in the Catalogue

```curl -vi -H "Content-Type: application/json" http://sp.int.sonata-nfv.eu:4002/catalogues/network-services```
