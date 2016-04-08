FROM registry:2

MAINTAINER Georgi Dimitrov <georgi.dimitrov>

# always try to install openssl and create a directory /root/openssl
RUN apt-get install -y openssl
RUN mkdir -p /data/

#ENV SOMEVAR

# always add theese files
COPY ./resources/configs/openssl_root.cnf /bin/openssl_root.cnf
COPY ./resources/configs/openssl_intermediate.cnf /bin/openssl_intermediate.cnf
COPY ./resources/scripts/startup.sh /bin/startup.sh
COPY ./resources/configs/openssl.cnf /tmp/openssl.cnf

ENV COUNTRY GB
ENV STATE England
ENV LOCALITY London
ENV ORGANIZATION ADOP
ENV UNIT ADOP
ENV ROOT_COMMON_NAME REGISTRY-ROOT-CA
ENV INTERMEDIATE_COMMON_NAME REGISTRY-INTER-CA
ENV EMAIL example@example.com
ENV PASS_ROOT ADOPROOT
ENV PASS_INTERMEDIATE ADOPINTER
ENV PASS_REGISTRY ADOPREG
ENV REGISTRY_IP X.X.X.X

#ADD config.yml /etc/docker/registry/config.yml

RUN chmod 700 /bin/startup.sh && \
    rm -f /etc/ssl/openssl.cnf && \
    cp /tmp/openssl.cnf /etc/ssl/openssl.cnf

# always execute this script that checks and does the rest    
# RUN /root/openssl/openssl.sh

#ENV CERTS_PATH=/path/to/certs

ENTRYPOINT ["/bin/bash"]
CMD ["/bin/startup.sh"]