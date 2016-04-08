#Supported tags and respective Dockerfile links

- [`0.0.1`](https://github.com/Accenture/adop-registry/blob/master/Dockerfile.md)

# What is adop-registry?

adop-registry is a wrapper for the registry image. It has primarily been built to perform extended configuration.
Registry is an open source Docker Registry tool.

# How to use this image

The easiest way to run adop-registry image is as follow:
```
docker run --name <your-container-name> -d -p 5500:5000 gogodi91/adop-registry:VERSION
```
After the above registry will be available at: http://localhost:5500

Additional environment variables that allow to fine tune the Docker Registry runtime configuration are:

* The usual options for a docker registry (found in docker documentation https://docs.docker.com/registry/overview/)
* REGISTRY_HTTP_TLS_CERTIFICATE, Set registry certifficate
* REGISTRY_HTTP_TLS_KEY, Set registry certifficate key
* REGISTRY_IP, Public IP address of registry host
* PASS_ROOT, Root CA password
* PASS_INTERMEDIATE, Intermediate CA password
* PASS_REGISTRY, Certifficate password
* COUNTRY, Certifficates and CA country
* STATE, Certifficates and CA state
* LOCALITY, Certifficates and CA locality
* ORGANIZATION, Certifficates and CA organization
* UNIT, Certifficates and CA organizational unit
* ROOT_COMMON_NAME, Root CA common name (CN)
* INTERMEDIATE_COMMON_NAME, Intermediate CA common name (CN)
* EMAIL, Certifficates and CA email address

## Run adop-registry with slef-signed certifficates

The following command will run adop-registry with slef-signed certifficates (generated at runtime)
```
  docker run \
  --name registry \
  -p 5500:5000 \
  --restart=always \
  --entrypoint /bin/bash \
  -v /data/registry/:/data \
  -v "/etc/docker:/certs" \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/registry_certs/registry.crt \
  -e REGISTRY_HTTP_TLS_KEY=/registry_certs/registry.key \
  -d gogodi91/adop-registry:0.0.1 \
  /bin/startup.sh
```

# License
Please view [licence information](LICENCE.md) for the software contained on this image.

#Supported Docker versions

This image is officially supported on Docker version 1.10.3.
Support for older versions (down to 1.6) is provided on a best-effort basis.

# User feedback

## Documentation
Documentation for this image is available in the [Docker Registry documentation page](https://docs.docker.com/registry/overview/). 
Additional documentaion can be found under the [`docker/distribution-library-image` GitHub repo](https://github.com/docker/distribution-library-image).

## Issues
If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/Accenture/adop-registry/issues).

## Contribute
You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/Accenture/adop-registry/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.