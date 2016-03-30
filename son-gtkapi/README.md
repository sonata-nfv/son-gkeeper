# Gatekeeper's API
This folder has the code and tests for the Gatekeeper's API.

## Configuration

## Tests
Testing is done with the ```RSpec``` framework.

To support ```XML``` reports, the ```[ci_reporter](https://github.com/ci-reporter/ci_reporter)``` ```gem``` was used. You can run tests by invoking

```sh
$ bundle exec rake ci:all
```

###Manual testing
Manual testing of the current version of the ```API``` can be done either using a web browser or the ```curl``` command, using the **Integration** environment (for now), with the Athens Testbed coonected and using the following ```IP``` adrress:

```
http://sp.int.sonata-nfv.eu:32001/
```

####GET '/'

```
http://sp.int.sonata-nfv.eu:32001/
```

###GET '/api-docs'

```
http://sp.int.sonata-nfv.eu:32001/api-docs
```

###GET '/packages/:uuid'

An example of a valid ```UUID``` is 

```
dcfb1a6c-770b-460b-bb11-3aa863f84fa0
```

```
http://sp.int.sonata-nfv.eu:32001/packages/dcfb1a6c-770b-460b-bb11-3aa863f84fa0
```

###POST '/packages'
This manual test has to be executed by using ```curl``` (or some browser plugin allowing the execution of POSTs):

```sh
$ curl -F "package=@simplest-example.son" localhost:5000/packages
```

## Usage
To use this application, we write
```sh
$ foreman start
```

```[Foreman](https://github.com/ddollar/foreman)``` is a ```ruby gem``` for managing applications based on a ```Procfile```. In our case, this file has, at the moment of writing, the following content:

```sh
web: bundle exec rackup -p $PORT
```

If the environment variable ```PORT``` is not defined, the ```5000``` value is assumed for it.