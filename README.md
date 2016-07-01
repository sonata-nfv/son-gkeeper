# SONATA's Service Platform Gatekeeper
[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)

This is [SONATA](http://www.sonata-nfv.eu)'s Service Platform Gatekeeper's repository.

Communication Service Providers (CSPs) in the 5G era will have to be able to open their infrastructures to Service Providers (SPs) that may not have any kind of close relationship with them, but a Supplier one: the SPs gets some amount of money, according to the agreed business model, from the CSPs. This is a radically distinct model from the one we are used to, in which SPs may, when allowed to, have to spend weeks (or sometimes even months) testing and integrating their services into the CSP’s infrastructure, with the CSP’s personnel having time to look into every aspect of the (new) proposed service, namely security, reliability, etc. In this new model, CSPs will have to:

 * **accept new services**’ descriptions (or updates on existing ones), according to a pre-defined and agreed format;
 * **validate** those descriptions, to guarantee that they’re both correct and do not seem to introduce any obvious threat to the quality of service that is expected the CSP to provide;
 * automatically **validate** the new service, namely in areas such as integration with authorized resources, these resources’ consumption and performance;
 * make the new service **available on its catalogue**, so that other SPs can use it to build new and more complex services.

When **automatic service scaling** is taken into account, adequately describing it in a service description is not a trivial task, and current service descriptions do not cover it in general. Validating the rest of the service description also poses very interesting difficulties when one goes beyond a simple description of URLs and ports. When the supporting infrastructure is not completely SDN based, or some integration with Physical Network Functions (PNFs) is needed, interfacing to OSS/BSS systems shall have to be considered. Special attention will be paid to the integration with legacy systems of the CSP. This Gatekeeper task deals exactly with this part of the problem, which can generically be called on-boarding. 

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
