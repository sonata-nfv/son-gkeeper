# [SONATA](http://www.sonata-nfv.eu)'s Gatekeeper KPI Management micro-service
[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

This is the folder of the **KPI Management** micro-service. This micro-service is used by the [`Gatekeeper API`](https://github.com/sonata-nfv/son-gkeeper/son-gtkapi). It's based on the [Prometheus Ruby Client](https://github.com/prometheus/client_ruby).

## Configuration
The configuration of the Gatekeeper's KPI Management micro-service is done mostly by defining `ENV` variables:

* `PUSHGATEWAY_HOST` : the prometheus host where is deployed the pushgateway component
* `PUSHGATEWAY_PORT` : the port used by the prometheus' pushgateway componentpost

## Usage
To use this application, we write
```sh
$ foreman start
```

[`Foreman`](https://github.com/ddollar/foreman) is a `ruby gem` for managing applications based on a [`Procfile`](https://github.com/sonata-nfv/son-gkeeper/blob/master/son-gtkrec/Procfile).

### Implemented API
The implemented API of the Gatekeeper's KPI module is the following:

* `/kpi`:    
    * `POST`: increment the value of an existing prometheus metric counter. If it doesn't exist, this module creates a new metric counter with value '1'

**Note 1:** Example:
```
$ curl -H "Content-Type: application/json" -X POST -d '{"job":"job-name","instance":"instance-name","name":"counter_name","docstring":"metric counter description","base_labels": {"label1":"value1","label2":"value2"}}' http://<PUSHGATEWAY_HOST>:<PUSHGATEWAY_PORT>/kpi
```

## Tests
At the module level, we only do **automated unit tests**, using the `RSpec` framework (see the `./spec/`folder). For the remaining tests please see the repositorie's [`README`](https://github.com/sonata-nfv/son-gkeeper/blob/master/README.md) file.
