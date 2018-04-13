#!/usr/bin/env bash

#USAGE
#./nodegroup-query.sh

PPM_ENDPOINT="http://ftppm509-lvuk-uk-p/hds/nodegroup"

LIVE_HOSTS="0"
DEAD_HOSTS="0"
UNKOWN_STATUS="0"
TOTAL_HOSTS="0"

NODEGROUPS='
prod_mms_nagios
methode_webclient
test_nagios_reuters_iw
int_nagios_reuters
eominstall_server_v6
prod_imagelibrary
edtech_jenkins
prod_getty_iw
prod_getty
test_getty
dev_getty
staging_methode_dev_temp_binary
archive_methode_prod_servlets
methodetests_prod
archive_methode_test_servlets
archive_methode_int_servlets
archive_methode_dev_servlets
archive_methode_prod_binary
archive_methode_test_binary
archive_methode_int_binary
archive_methode_dev_binary
staging_methode_int_temp_binary
staging_methode_dev_temp_search
staging_methode_int_temp_search
staging_methode_cmsdev_servlets
staging_methode_cmsdev_binary
staging_methode_cmsdev_search
archive_methode_prod_search
archive_methode_test_search
archive_methode_int_search
archive_methode_dev_search
mpsrender_methode_prod_search
mpsrender_methode_test_search
mpsrender_methode_prod_binary
mpsrender_methode_test_binary
mpsrender_methode_int_binary
mpsrender_methode_prod_servlets
netapp_srm_test
mpsrender_methode_test_servlets
mpsrender_methode_int_servlets
netapp_srm_prod
mpsrender_methode_int_search
wires_methode_tran_servlets
wires_methode_tran_binary
wires_methode_tran_search
netapp_poc_prod
staging_methode_tran_search
staging_methode_tran_binary
staging_methode_tran_servlets
staging_methode_prod_binary
staging_methode_test_binary
staging_methode_prod_search
staging_methode_test_search
staging_methode_prod_servlets
methode_prod_webclient
methode_test_webclient
methode_int_webclient
staging_methode_test_servlets
methode_dev_webclient
staging_methode_int_servlets
staging_methode_int_binary
render_methode_int_search
staging_methode_int_search
staging_methode_dev_servlets
wires_methode_test_binary_lnxTest
wires_methode_prod_search
int_mms
wires_methode_prod_servlets
wires_methode_test_binary
wires_methode_prod_binary
wires_methode_test_servlets
wires_methode_dev_servlets
wires_methode_int_servlets
wires_methode_test_search
staging_methode_dev_binary
staging_methode_dev_search
methode_toolbox_prod
wires_methode_dev_large_binary
wires_methode_int_binary
wires_methode_int_search
wires_methode_dev_search
wires_methode_dev_binary
methode_wires_ci
toolbox_prod
mrs_dev
mrs_prod
mrs_test
mrs_int
mrs_int_dev
prod_nagios_reuters_pr
prod_nagios_reuters_iw
development_reuters
prod_reuters
test_reuters
int_reuters
prod_mms
test_mms
dev_mms
prod_nagios_iw
tran_claro
prod_nagios
test_nagios
int_nagios
dev_nagios
ci_nagios
prod_claro
test_claro
int_claro
dev_claro
ci_claro
toolbox'

doTheActualRun() {
  i=0
  for nodegroup in $NODEGROUPS; do
    echo "============================================"
    echo -e "\e[34mProcessing nodegroup: $nodegroup\e[0m"
    while read line; do
      line=$(echo ${line} | tr -d '"')
      isHostName ${line}
    done <  <(curl -s http://ftppm509-lvuk-uk-p/hds/nodegroup/${nodegroup}/)
  done
}

whileMockRun() {
  i=0
  while read line; do
    line=$(echo ${line} | tr -d '"')
    isHostName ${line}
  done <  <(cat $1)
}

dumpAll() {
  for nodegroup in $NODEGROUPS; do
    curl -s ${PPM_ENDPOINT}/${nodegroup}/
  done
}

isHostName() {
  echo $1 | grep "^ft*.\-*.\-*." >/dev/null
  if [[ "$?" -eq "0" ]]; then
    #echo "Match found: $(echo $1 | tr -d ':')"
    isLiveHost $(echo $1 | tr -d ':')
  fi
}

isLiveHost() {
  (( TOTAL_HOSTS++ ))
  ping -c 1 $1 &>/dev/null
  if [[ "$?" -eq "0" ]]; then
    echo -e "\e[34m$1 is live\e[0m"
    (( LIVE_HOSTS++ ))
  elif [[ "$?" -eq "1" ]]; then
    echo -e "\e[31mUnknown host $1\e[0m"
    (( DEAD_HOSTS++ ))
  else
    echo "Unknown return code $? for host $1"
    (( UNKNOWN_STATUS++ ))
  fi
}

reportSummary() {
  echo "============================================"
  echo -e "\e[34m${LIVE_HOSTS}/${TOTAL_HOSTS} hosts are live \e[0m"
  echo -e "\e[31m${DEAD_HOSTS}/${TOTAL_HOSTS} hosts are dead\e[0m"
  echo "${UNKOWN_STATUS}/${TOTAL_HOSTS} hosts reporting unknown status"
  echo "============================================"
}

usage() {
  echo "USAGE: $0 file.name"
  exit 1
}

if [[ ${#@} -eq "0" ]]; then
  echo "Didn't get file as an argument, doing actual run"
  #exit
  doTheActualRun
elif [[ "${1}" == "dumpall" ]]; then
  dumpAll
elif [[ -f "$1" ]]; then
  echo "Passing file $1 to function doTheMockRun"
  whileMockRun "$1"
else
  echo "Unknown option $1"
fi

reportSummary
