#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# Print the usage message
function printHelp() {
  USAGE="$1"
  println "Usage: "
  println "  network.sh <Mode> [Flags]"
  println "    Modes:"
  println "      \033[0;32mcreateOrg\033[0m - Create orgs' crypto materials with fabric-ca."
  println "      \033[0;32mextendOrg\033[0m - Extend orgs' crypto materials with fabric-ca."
  println "      \033[0;32mcleanOrg\033[0m - Clean orgs' crypto materials"
  println "      \033[0;32mcleanAll\033[0m - Clean all orgs' crypto materials"
  println
  println "    Flags:"
  println "    Used with \033[0;32mnetwork.sh up\033[0m, \033[0;32mnetwork.sh createChannel\033[0m:"
  println "    -cai <ca_imagetag> - Docker image tag of Fabric CA to deploy (defaults to \"${CA_IMAGETAG}\")"
  println "    -o <org> - org name: org1"
  println "    -t <orgType> - org type: orderer | peer"
  println "    -d <domain> - domain name: org1.example.com"
  println "    -c <nodeCount> - org node count (defaults to $NODE_COUNT)"
  println "    -h - Print this message"
  println
}

# println echos string
function println() {
  echo -e "$1"
}

# errorln echos i red color
function errorln() {
  println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

export -f errorln
export -f successln
export -f infoln
export -f warnln
