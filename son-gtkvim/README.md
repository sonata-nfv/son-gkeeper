# [SONATA](http://www.sonata-nfv.eu)'s Gatekeeper VIM Management micro-service
[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

# Tests

## Obtain a list of available VIMs
The full list of VIMs can be obtained with

```curl -X GET -H "Content-Type:application/json" http://sp.int3.sonata-nfv.eu:32001/vim```

**Note:** For this version, no user authentication/authorization is being done. In the future, with authentication/authorization mechanisms in place, this list will be adequately filtered.


## Add a VIM 
To add a VIM you can do this:

```curl -X POST --data-binary @vim.json -H "Content-Type:application/json" http://sp.int3.sonata-nfv.eu:5700/vim```

  where the content of vim.json in this test is:
  {"wr_type":"compute","tenant_ext_net":"ext-subnet","tenant_ext_router":"ext-router","vim_type":"Mock","vim_address":"http://localhost:9999","username":"Eve","pass":"Operator","tenant":"op_sonata"} 


## Obtain the status of a vim create/get request by its uuid
To obtain the status of the request with uuid 7dfbb948-144d-41d7-839c-256cc242201b you can do:

```curl -X GET -H "Content-Type:application/json" http://sp.int3.sonata-nfv.eu:32001/vim_request/7dfbb948-144d-41d7-839c-256cc242201b```


