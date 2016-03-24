# SONATA demo package 

The SONATA demo package contains all the information and data needed for the first demo. To this end, it comprises the Network Service Descriptor that constitutes the demo service, comprising the different Virtual Network Functions. Within the package, the NSD can be found at:

 - service_descriptors/sonata-demo.yml

In addition the package contains the Virtual Network Function Descriptors for an iperf VNF, a firewall VNF based on open-vswitch, and a tcpdump VNF. Within the package, the VNFDs can be found at:

 - function_descriptors/iperf-vnfd.yml
 - function_descriptors/firewall-vnfd.yml
 - function_descriptors/tcpdump-vnfd.yml

Each of the VNFs uses a Docker container to actual provide and run the network function. Thus, the package contains the Docker files that define the Docker containers. Within the package, the Docker files are located at:

 - docker_files/iperf/Dockerfile
 - docker_files/firewall/Dockerfile
 - docker_files/tcpdump/Dockerfile

Finally, the packages contains a package descriptor that provides additional information on the strucuture of the package and the contained data. By definition, the package descriptor is located at:

 - META-INF/MANIFEST.MF
