#requires the docker run command to have --entrypoint /bin/bash
# Check if the config file exists
if ! ls /bin | grep "openssl_root.cnf" || ! ls /bin | grep "openssl_intermediate.cnf" ; then
    return 1
else
    echo "Both Configs Exist. Moving On"
fi

######################### FIND THE REGISTRY PUBLIC IP #########################
if REGISTRY_IP==X.X.X.X; then
    echo "Retrieving Registry Public IP"
    apt-get update
    apt-get install -y dnsutils
    apt-get autoclean
    rm -rf /var/lib/apt/lists/*
    REGISTRY_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
else
    echo "Using Supplied Public IP"
fi
######################### FIND THE REGISTRY PUBLIC IP #########################)


####################################################    GENERATE A CA AND USE THAT TO SIGN A CERTIFFICATE   #################################################
function Create_Root_Directories {
    mkdir -p /data/ca/{certs,crl,newcerts,private}
    chmod 700 /data/ca/private
    touch /data/ca/index.txt
    echo 1000 > /data/ca/serial
    cp /bin/openssl_root.cnf /data/ca/openssl.cnf
}

function Create_Root_Pair {
    cd /data/ca
    openssl genrsa -passout pass:${PASS_ROOT} -aes256 -out private/ca.key.pem 4096
    chmod 400 private/ca.key.pem
    # Create Root Certifficate
    openssl req -config openssl.cnf -passin pass:${PASS_ROOT} -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${ROOT_COMMON_NAME}/emailAddress=${EMAIL}" -key private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out certs/ca.cert.pem
    chmod 444 certs/ca.cert.pem
}

function Create_Intermediate_Directories {
    mkdir /data/ca/intermediate/
    mkdir /data/ca/intermediate/{certs,crl,csr,newcerts,private}
    chmod 700 /data/ca/intermediate/private
    touch /data/ca/intermediate/index.txt
    echo 1000 > /data/ca/intermediate/serial
    echo 1000 > /data/ca/intermediate/crlnumber
    cp /bin/openssl_intermediate.cnf /data/ca/intermediate/openssl.cnf
}

function Create_Intermediate_Pair {
    cd /data/ca
    openssl genrsa -passout pass:${PASS_INTERMEDIATE} -aes256 -out intermediate/private/intermediate.key.pem 4096
    chmod 400 intermediate/private/intermediate.key.pem
    openssl req -config intermediate/openssl.cnf -passin pass:${PASS_INTERMEDIATE} -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${INTERMEDIATE_COMMON_NAME}/emailAddress=${EMAIL}" -new -sha256 -key intermediate/private/intermediate.key.pem -out intermediate/csr/intermediate.csr.pem
    cd /data/ca
    echo -e "y\ny" > response
    < response openssl ca -config openssl.cnf -passin pass:${PASS_ROOT} -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in intermediate/csr/intermediate.csr.pem -out intermediate/certs/intermediate.cert.pem
    rm response
    chmod 444 intermediate/certs/intermediate.cert.pem
}

function Check_Chain {
    if openssl verify -CAfile /data/ca/certs/ca.cert.pem /data/ca/intermediate/certs/intermediate.cert.pem | grep "OK"; then
        echo "Intact"
    else
        return 1
    fi
}

function Create_Cetrifficate_Chain {
    cd /data/ca
    cat intermediate/certs/intermediate.cert.pem certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
    chmod 444 intermediate/certs/ca-chain.cert.pem
}

function Create_Server_Certs {
    cd /data/ca
    echo -e "\n\nBUILDING SERVER KEY\n"
    openssl genrsa -aes256 -passout pass:${PASS_REGISTRY} -out intermediate/private/registry.key.pem 4096
    chmod 400 intermediate/private/registry.key.pem
    openssl req -config intermediate/openssl.cnf -passin pass:${PASS_REGISTRY} -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${REGISTRY_IP}/emailAddress=${EMAIL}" -key intermediate/private/registry.key.pem -new -sha256 -out intermediate/csr/registry.csr.pem
    echo -e "y\ny" > response
    echo -e "\n\nBUILDING SERVER CERTIFFICATE\n"
    < response openssl ca -config intermediate/openssl.cnf -passin pass:${PASS_INTERMEDIATE} -extensions server_cert -days 375 -notext -md sha256 -in intermediate/csr/registry.csr.pem -out intermediate/certs/registry.cert.pem
    rm response
    chmod 444 intermediate/certs/registry.cert.pem
}

function Prepare_Registry_Keys {
    mkdir /certs
    openssl rsa -in /data/ca/intermediate/private/registry.key.pem -out /certs/registry.key -passin pass:${PASS_REGISTRY}
    cp /data/ca/intermediate/certs/registry.cert.pem /certs/registry.crt
}
####################################################    GENERATE A CA AND USE THAT TO SIGN A CERTIFFICATE   #################################################

####################################################    SIMPLE CERT GENERATION  ############################################################

function Simple_Cert_Generator {
    mkdir -p /data/ca && openssl req \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${REGISTRY_IP}/emailAddress=${EMAIL}" \
        -newkey rsa:4096 -nodes -sha256 -keyout /data/ca/registry.key \
        -x509 -days 365 -out /data/ca/registry.crt
}

function Configure_Openssl {
    PRIVATE_IP=$(ip addr | grep eth0 | awk '/inet / {sub(/\/.*/, "", $2); print $2}')
    sed -i -e "s/52.16.63.143/${REGISTRY_IP},IP:${PRIVATE_IP}/g" /etc/ssl/openssl.cnf

}

function Copy_Certs {
    mkdir -p /certs/certs.d/${REGISTRY_IP}\:5500/
    mkdir -p /certs/certs.d/${PRIVATE_IP}\:5500/
    mkdir -p /registry_certs
    cp /data/ca/registry.crt /registry_certs/registry.crt
    cp /data/ca/registry.key /registry_certs/registry.key
    cp /data/ca/registry.crt /certs/certs.d/${REGISTRY_IP}\:5500/ca.crt
    cp /data/ca/registry.crt /certs/certs.d/${PRIVATE_IP}\:5500/ca.crt
}



if ! ls /data | grep "ca"; then
                                            ##########  CREATE ROOT PAIR        ##########
    #Create_Root_Directories         # Setup Directory Structure
    #Create_Root_Pair                # Create Root Key
    
                                            ########## CREATE INTERMEDIATE PAIR ##########
    #Create_Intermediate_Directories
    #Create_Intermediate_Pair
    #Check_Chain
    #Create_Cetrifficate_Chain
    #Create_Server_Certs
    #Prepare_Registry_Keys
    Configure_Openssl
    Simple_Cert_Generator
    Copy_Certs
else
    echo "CA already exists"
    if ! ls /certs | grep "registry.crt"; then
        echo "Certifficate not in the expected directory"
        if ! ls /data/ca | grep "registry.crt"; then
            echo "Certifficate never created and not supplied. Creating new certifficate"
            Configure_Openssl
            Simple_Cert_Generator
        fi
        Copy_Certs
    fi
    echo "Using Existing Certifficate"       
fi

# Execute the standard command
/bin/registry /etc/docker/registry/config.yml