[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

# SON-GKEEPER
This is [SONATA](http://www.sonata-nfv.eu)'s Service Platform Gatekeeper's repository.

The Gatekeeper is the component that implements all the **Northbound Interface** (NBI) of the Servive Platform.
 
This NBI provides systems like the [son-push](http://github.com/sonata-nfv/son-push), [son-gui](http://github.com/sonata-nfv/son-gui) and [son-bss](http://github.com/sonata-nfv/son-bss) access to the **Service Platform**, for features like:

 * **accepting new developers**' to be part of the contributors of new developed services;
 * **accepting new services** to be deployed in the platform;
 * **accepting new service instance requests** from customers interested in instantiating a service;
 * etc..

## Development
(if applicable)

### Building
Describe briefly how to build the software.

### Dependencies
Name all the dependencies needed by the software, including version, license (!), and a link. For example

* [pyaml](https://pypi.python.org/pypi/pyaml) >=15.8.2 (WTFPL)

### Contributing
(if applicable) Description (encouraging) how to contribute to this project/repository.

## Installation
(if applicable) Describe briefly how to install the software. You may want to put a link to son-install instead:

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

* José Bonnet (jbonnet)
* Name of lead developer (GitHub-username)

#### Feedback-Chanel

* Mailing list
* GitHub issues
----

# Repository organization
This repository is organized by **micro-service**.

Micro-services currently implemented are the following:

1. [`son-gtkapi`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkapi): the only 'door' to the Gatekeeper, where the API is exposed;
1. [`son-gtkpkg`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkpkg): where all Packages features are implemented;
1. [`son-gtksrv`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtksrv): where all Services features are implemented;
1. [`son-gtkvim`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkvim): where all Vims features are implemented;

The remaining micro-services ([`son-gtkusr`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkusr), [`son-gtklic`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtklic) and [`son-gtkkpi`](https://github.com/sonata-nfv/son-gkeeper/tree/master/son-gtkkpi), and eventually others), will be implemented in the course of the project.

# Testing strategies
For testing the code provided you should check each of the the `README.md` files of each of the folders below this one. 
