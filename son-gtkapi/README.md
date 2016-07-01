# [SONATA](http://www.sonata-nfv.eu)'s Gatekeeper API micro-service
[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

This folder has the code and tests for the Gatekeeper's API.

## Configuration

## Tests
Testing is done with the `RSpec` framework.

To support `XML` reports, the `[ci_reporter](https://github.com/ci-reporter/ci_reporter)` `gem` was used. You can run tests by invoking

```sh
$ bundle exec rake ci:all
```

###Manual testing
Manual testing of the current version of the `API` can be done either using a web browser or the `curl` command, using the **Integration** environment (for now), with the Athens Testbed coonected and using the following `IP` adrress:

```
http://sp.int.sonata-nfv.eu:32001/
```

####GET '/'

```
http://sp.int.sonata-nfv.eu:32001/
```

###GET '/api-doc'

```
http://sp.int.sonata-nfv.eu:32001/api-doc
```

###GET '/packages/:uuid'

An example of a valid `UUID` is 

```
dcfb1a6c-770b-460b-bb11-3aa863f84fa0
```

So, getting a package with that UUID is done by

```
http://sp.int.sonata-nfv.eu:32001/packages/dcfb1a6c-770b-460b-bb11-3aa863f84fa0
```

**Note:** the current implementation simply returns the `UUID` passed as a parameter, together with the `simplest-example.son` meta-data.

###POST '/packages'
This manual test has to be executed by using `curl` (or some browser plugin allowing the execution of POSTs):

```sh
$ curl -F "package=@simplest-example.son" localhost:5000/packages
```

###GET '/vims'
The full list of VIMs can be obtained with

```sh
& curl -X GET -H "Content-Type:application/json" http://sp.int3.sonata-nfv.eu:32001/vims
```

**Note:** For this version, no user authentication/authorization is being done. In the future, with authentication/authorization mechanisms in place, this list will be adequately filtered.


###POST '/vims' 
To add a VIM you can do this:

```sh
curl -X POST --data-binary @vim.json -H "Content-Type:application/json" http://sp.int3.sonata-nfv.eu:5700/vims
```

  where the content of vim.json in this test is:
```
  {"wr_type":"compute","tenant_ext_net":"ext-subnet","tenant_ext_router":"ext-router","vim_type":"Mock","vim_address":"http://localhost:9999","username":"Eve","pass":"Operator","tenant":"op_sonata"} 
```

###GET '/vim_requests/:uuid'
To obtain the status of the request with uuid 7dfbb948-144d-41d7-839c-256cc242201b you can do:

```sh
curl -X GET -H "Content-Type:application/json" http://sp.int3.sonata-nfv.eu:32001/vim_requests/7dfbb948-144d-41d7-839c-256cc242201b```
```

## Usage
To use this application, we write
```sh
$ foreman start
```

[`Foreman`](https://github.com/ddollar/foreman) is a `ruby gem` for managing applications based on a `Procfile`. In our case, this file has, at the moment of writing, the following content:

```sh
web: bundle exec rackup -p $PORT
```

If the environment variable `PORT` is not defined, the `5000` value is assumed for it.


