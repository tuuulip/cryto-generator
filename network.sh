#!/bin/bash

# prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx

# certificate authorities compose file
COMPOSE_FILE_CA_PEER=configs/docker-compose-ca.yaml

# import scripts
. scripts/utils.sh
. scripts/registerEnroll.sh

#  generate organization materials
function createOrg() {
  if [ -d "${ORG_TYPE}Organizations/$DOMAIN" ]; then
    rm -Rf ${ORG_TYPE}Organizations/$DOMAIN
  fi

  # Create ca server config
  serverHome=fabric-ca/$ORG
  mkdir -p $serverHome
  cp configs/fabric-ca-server-config.yaml $serverHome
  sed -i -e "s/{{caname}}/${ORG}CA/g" $serverHome/fabric-ca-server-config.yaml
  sed -i -e "s/{{domain}}/${DOMAIN}/g" $serverHome/fabric-ca-server-config.yaml

  # Create crypto material using Fabric CA
  infoln "Generating certificates using Fabric CA"
  ORG=$ORG IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA_PEER up -d 2>&1

  while :
    do
      if [ ! -f "fabric-ca/$ORG/tls-cert.pem" ]; then
        sleep 1
      else
        break
      fi
    done
  registerEnroll $ORG $ORG_TYPE $DOMAIN $NODE_COUNT

  # bring down containers
  ORG=$ORG IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA_PEER down 2>&1
}

# extend node's material, like cryptogen extend
function extendOrg() {
  infoln "Extend org nodes" 
  # Bring down containers
  ORG=$ORG IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA_PEER up -d 2>&1
  sleep 5
  infoln "add org node" 
  addOrdererNode $ORG $ORG_TYPE $DOMAIN $NODE_COUNT
  # Bring down containers
  ORG=$ORG IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA_PEER down 2>&1
}

# clean all materials
function cleanAll() {
  if [ -d "peerOrganizations" ]; then
    rm -Rf peerOrganizations
  fi

  if [ -d "ordererOrganizations" ]; then
    rm -Rf ordererOrganizations
  fi

  if [ -d "fabric-ca" ]; then
    rm -Rf fabric-ca
  fi
  infoln "All material cleaned"
}

# clean organization materials
function cleanOrg() {
  if [ ! "$DOMAIN" ]; then
    errorln "use -d to setup domain field"
    exit 1
  fi

  if [ ! "$ORG" ]; then
    errorln "use -o to setup org field"
    exit 1
  fi

  cryptoHome="peerOrganizations/$DOMAIN"
  infoln "Cleaning $cryptoHome"
  if [ -d $cryptoHome ]; then
    rm -Rf $cryptoHome
  fi

  cryptoHome="ordererOrganizations/$DOMAIN"
  infoln "Cleaning $cryptoHome"
  if [ -d $cryptoHome ]; then
    rm -Rf $cryptoHome
  fi

  cryptoHome="fabric-ca/$ORG"
  infoln "Cleaning $cryptoHome"
  if [ -d $cryptoHome ]; then
    rm -Rf $cryptoHome
  fi
}

# Using crpto vs CA. default is cryptogen
# default ca image tag
CA_IMAGETAG="1.5.3"
ORG=""
ORG_TYPE="orderer"
DOMAIN=""
NODE_COUNT=3


## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# parse flags
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp $MODE
    exit 0
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -o )
    ORG="$2"
    shift
    ;;
  -t )
    ORG_TYPE="$2"
    shift
    ;;
  -d )
    DOMAIN="$2"
    shift
    ;;
  -c )
    NODE_COUNT="$2"
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

if [ "${MODE}" == "createOrg" ]; then
  createOrg
elif [ "${MODE}" == "extendOrg" ]; then
  extendOrg
elif [ "${MODE}" == "cleanOrg" ]; then
  cleanOrg
elif [ "${MODE}" == "cleanAll" ]; then
  cleanAll
else
  printHelp
  exit 1
fi
