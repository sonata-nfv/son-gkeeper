[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

# SON-GKEEPER
This is [SONATA](http://www.sonata-nfv.eu)'s Service Platform Gatekeeper's repository.

The Gatekeeper is the component that implements all the **Northbound Interface** (NBI) of the Servive Platform.
 
This NBI provides systems like the [son-push](http://github.com/sonata-nfv/son-push), [son-gui](http://github.com/sonata-nfv/son-gui) and [son-bss](http://github.com/sonata-nfv/son-bss) access to the **Service Platform**, for features like:

 * **accepting new developers**' to be part of the contributors of new developed services;
 * **accepting new services**, in the **package format**, to be deployed in the platform;
 * **validating submited packages**, both in terms of file format and developer submitting the package;
 * **accepting new service instance requests** from customers interested in instantiating a service;
 * **following a service performance** through automatically monitoring each on-boarded service or function;
 * etc..

## Development
This section details what is needed for developing the Gatekeeper.
This repository is organized by **micro-service**.

Micro-services currently implemented are the following:

1. [`son-gtkapi`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkapi): the only 'door' to the Gatekeeper, where the API is exposed;
1. [`son-gtkpkg`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkpkg): where all Packages features are implemented;
1. [`son-gtksrv`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtksrv): where all Services features are implemented;
1. [`son-gtkfcnt`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkfcnt): where all Functions features are implemented;
1. [`son-gtkvim`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkvim): where all Vims features are implemented;
1. [`son-gtkrec`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkrec): where all Records§ features are implemented;

The remaining micro-services ([`son-gtkusr`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkusr), [`son-gtklic`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtklic) and [`son-gtkkpi`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkkpi), and eventually others), will be implemented in the course of the project.

### Building
Describe briefly how to build the software.

### Dependencies
Name all the dependencies needed by the software, including version, license (!), and a link. For example

* [activerecord]
* [addressable]
* [bunny], >= 2.3.0
* [ci_reporter_rspec]
* [foreman]
* [pg]
* [pry]
* [puma]
* [rack-parser], require: rack/parser
* [rack-test], require: rack/test
* [rake]
* [rest-client]
* [rspec-its]
* [rspec-mocks]
* [rspec]
* [rubocop-checkstyle_formatter], require: false
* [rubocop]
* [ruby]
* [rubyzip], >= 1.0.0
* [sinatra-active-model-serializers], ~> 0.2.0
* [sinatra-activerecord]
* [sinatra-contrib], ~> 1.4.1, require: false
* [sinatra-cross_origin]
* [sinatra-logger]
* [sinatra], ~> 1.4.3, require: sinatra/base



* [pyaml](https://pypi.python.org/pypi/pyaml) >=15.8.2 (WTFPL)

### Contributing
Contributing to the Gatekeeper is really easy. You must:

1. Clone [this repository](http://github.com/sonata-nfv/son-gkeeper);
1. Work on your proposed changes, preferably through submiting [issues](https://github.com/sonata-nfv/son-gkeeper/issues);
1. Submit a Pull Request;
1. Follow/answer related [issues](https://github.com/sonata-nfv/son-gkeeper/issues) (see Feedback-Chanel, below).

## Installation
Installing the Gatekeeper is really easy. You'll need:

1. the [ruby](http://www.ruby-lang.org) programming language: we prefer doing this by using a version manager tool such as [rvm](https://rvm.io) or [rbenv](http://rbenv.org) (we are using version **2.2.3**);
1. in each one of the subfolders, just run:
  1. `bundle install`
  1. please follow each specific folder's instructions on which environment variables to set
1. ...

The installation of this component can be done using the [son-install](https://github.com/sonata-nfv/son-install) script.

## Usage
(if applicable) Describe briefly how to use the software.

## License

#### Useful Links

* Any useful link and brief description. For example:
* http://www.google/ Don't be evil.

---
#### Lead Developers

The following lead developers are responsible for this repository and have admin rights. They can, for example, merge pull requests.

* José Bonnet ([jbonnet](https://github.com/jbonnet))
* Name of lead developer (GitHub-username)

#### Feedback-Chanel

* Mailing list
* [GitHub issues](https://github.com/sonata-nfv/son-gkeeper/issues)

