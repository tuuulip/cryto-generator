#!/bin/bash

## registerEnroll orgName orgType orgDomain nodeCount
## For example:
## registerEnroll org1 peer org1.example.com 3
## registerEnroll org2 orderer org2.example.com 2
function registerEnroll() {
    orgName=$1
    orgType=$2
    orgDomain=$3
    nodeCount=$4
    infoln "inputs: $orgName, $orgType, $orgDomain, $nodeCount"

    caName="ca-$orgName"
    orgHome=${PWD}/${orgType}Organizations/$orgDomain
    caHome=${PWD}/fabric-ca/$orgName
    infoln "envs: $caName, $orgHome, $caHome"

    ## set fabric client home env
    mkdir -p $orgHome
    export FABRIC_CA_CLIENT_HOME=$orgHome

    ## enroll admin
    set -x
    fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname $caName --tls.certfiles "${caHome}/tls-cert.pem"
    { set +x; } 2>/dev/null

    ## create nodeOUs file
    nodeOUsFile="${orgHome}/msp/config.yaml"
    echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
      Certificate: cacerts/localhost-7054-ca-org1.pem
      OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
      Certificate: cacerts/localhost-7054-ca-org1.pem
      OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
      Certificate: cacerts/localhost-7054-ca-org1.pem
      OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
      Certificate: cacerts/localhost-7054-ca-org1.pem
      OrganizationalUnitIdentifier: orderer' > $nodeOUsFile

    sed -i -e "s/ca-org1.pem/ca-$orgName.pem/g" $nodeOUsFile
    
    ## register and enroll nodes
    for i in $(seq 1 $nodeCount) 
    do
        index=$[i-1]
        creatNodes $orgHome $orgName $orgType $orgDomain $caName $index
    done

    ## register and enroll user1
    infoln "Registering user"
    set -x
    fabric-ca-client register --caname $caName --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${caHome}/tls-cert.pem"
    { set +x; } 2>/dev/null

    infoln "Generating the user msp"
    set -x
    fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname $caName -M "${orgHome}/users/User1@$orgDomain/msp" --tls.certfiles "${caHome}/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${orgHome}/msp/config.yaml" "${orgHome}/users/User1@$orgDomain/msp/config.yaml"
    
    ## register and enroll admin
    infoln "Registering the org admin"
    set -x
    fabric-ca-client register --caname $caName --id.name ${orgName}admin --id.secret ${orgName}adminpw --id.type admin --tls.certfiles "${caHome}/tls-cert.pem"
    { set +x; } 2>/dev/null

    infoln "Generating the org admin msp"
    set -x
    fabric-ca-client enroll -u https://${orgName}admin:${orgName}adminpw@localhost:7054 --caname $caName -M "${orgHome}/users/Admin@$orgDomain/msp" --tls.certfiles "${caHome}/tls-cert.pem"
    { set +x; } 2>/dev/null

    cp "${orgHome}/msp/config.yaml" "${orgHome}/users/Admin@$orgDomain/msp/config.yaml"

}

## addOrdererNode  orgName orgType orgDomain nodeCount
function addOrdererNode() {
    orgName=$1
    orgType=$2
    orgDomain=$3
    nodeCount=$4

    caName="ca-$orgName"
    orgHome=${PWD}/${orgType}Organizations/$orgDomain
    
    export FABRIC_CA_CLIENT_HOME=$orgHome

    for i in $(seq 1 $nodeCount) 
    do
        index=$[i-1]
        creatNodes $orgHome $orgName $orgType $orgDomain $caName $index
    done 
}

## creatNodes orgHome orgName orgType orgDomain caName index
function creatNodes() {
    orgHome=$1
    orgName=$2
    orgType=$3
    orgDomain=$4
    caName=$5
    index=$6

    NODE_ID="${orgType}${index}"
    nodeHome="${orgHome}/${orgType}s/${NODE_ID}.$orgDomain"

    # only execute when dir not exist
    # so we can extend node count
    if [ ! -d $nodeHome ]; then
        infoln "Registering ${NODE_ID}"
        set -x
        fabric-ca-client register --caname $caName --id.name ${NODE_ID} --id.secret ${NODE_ID}pw --id.type ${orgType} --tls.certfiles "${PWD}/fabric-ca/$orgName/tls-cert.pem"
        { set +x; } 2>/dev/null
    
        infoln "Generating the ${NODE_ID} msp"
        set -x
        fabric-ca-client enroll -u https://${NODE_ID}:${NODE_ID}pw@localhost:7054 --caname $caName -M "${nodeHome}/msp" --csr.hosts ${NODE_ID}.$orgDomain --tls.certfiles "${PWD}/fabric-ca/${orgName}/tls-cert.pem"
        { set +x; } 2>/dev/null
    
        cp "${orgHome}/msp/config.yaml" "${nodeHome}/msp/config.yaml"
    
        infoln "Generating the ${NODE_ID}-tls certificates"
        set -x
        fabric-ca-client enroll -u https://${NODE_ID}:${NODE_ID}pw@localhost:7054 --caname $caName -M "${nodeHome}/tls" --enrollment.profile tls --csr.hosts ${NODE_ID}.$orgDomain --csr.hosts localhost --tls.certfiles "${PWD}/fabric-ca/${orgName}/tls-cert.pem"
        { set +x; } 2>/dev/null
    
        cp "${nodeHome}/tls/tlscacerts/"* "${nodeHome}/tls/ca.crt"
        cp "${nodeHome}/tls/signcerts/"* "${nodeHome}/tls/server.crt"
        cp "${nodeHome}/tls/keystore/"* "${nodeHome}/tls/server.key"
    
        mkdir -p "${orgHome}/msp/tlscacerts"
        cp "${nodeHome}/tls/tlscacerts/"* "${orgHome}/msp/tlscacerts/ca.crt"
    
        mkdir -p "${orgHome}/tlsca"
        cp "${nodeHome}/tls/tlscacerts/"* "${orgHome}/tlsca/tlsca.$orgDomain-cert.pem"
    
        mkdir -p "${orgHome}/ca"
        cp "${nodeHome}/msp/cacerts/"* "${orgHome}/ca/ca.$orgDomain-cert.pem"
    else
        warnln "Skip generate node material beccause $nodeHome already exist."
    fi
}