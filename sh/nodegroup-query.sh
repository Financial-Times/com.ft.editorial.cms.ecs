#!/usr/bin/env bash

#USAGE
#./nodegroup-query.sh





LIVE_HOSTS="0"
IW_HOSTS="0"
PR_HOSTS="0"
AMZ_HOSTS="0"
SRDF_HOSTS="0"
UNK_HOSTS="0"
DEAD_HOSTS="0"
UNKNOWN_STATUS="0"
TOTAL_HOSTS="0"
TOTAL_NODEGROUPS="0"


doTheActualRun() {

  PPM_ENDPOINT="http://ftppm${PPM}-lvuk-uk-p/hds/nodegroup"
  if [ -f /etc/puppet/puppet.conf ] || [ ${PPM} -gt 509 ]; then
    FTPLATFORM=2
  else
    FTPLATFORM=1
  fi
  if [ "$FTPLATFORM" == "1" ]; then
    NODEGROUPS=$(curl -s "http://ftppm${PPM}-lvuk-uk-p/api/nodegroups/" | jq '.[]|.name|@text'| sed 's/"//g')
  else
    NODEGROUPS=$(curl -s "https://ftppm${PPM}-lvuk-uk-p/api/nodegroups/" --insecure| jq '.[].url'|wc -l)
  fi

  i=0
  for nodegroup in $NODEGROUPS; do
    # echo "============================================"
    # echo -e "\e[34mProcessing nodegroup: $nodegroup\e[0m"
    (( TOTAL_NODEGROUPS++ ))
    if [ "$FTPLATFORM" == "1" ]; then
      NODES=$(curl -s ${PPM_ENDPOINT}/${nodegroup}/|jq '.hosts'|jq 'keys|@csv'|tr -d '"'|tr -d '\' 2> /dev/null|tr ',' '
')
    else
      TOTAL_NODEGROUPS=$NODEGROUPS
      NODES=$(curl -s https://ftppm${PPM}-lvuk-uk-p/api/nodes/ --insecure| jq '.[]|[.nodegroup, .static_instance.name, .ec2_instance.instance_name]|@csv'| sed -e 's/"//g;s/\\//g;s/,,/,/g;s/,$//g;'|tr ',' '\n')
    fi


    while read line; do
      # line=$(echo ${line} | tr -d '"')
      if [[ ${line} == "https://"* ]]; then
        last_ppm=${line}
        continue
      fi
      isHostName ${line}
      if [[ "$?" -eq "1" ]]; then
        echo -ne '\e[31mDECOM\e[0m '
      else
        echo -ne '\e[34mFOUND\e[0m '
      fi
      if [ "$FTPLATFORM" == "1" ]; then
        echo ${nodegroup} ${line}
      else
        echo ${last_ppm} ${line}
      fi
    done < <(echo "$NODES")
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
  echo $1 | egrep "^ft*.\-*.\-*.|compute.internal|^ip-" >/dev/null
  if [[ "$?" -eq "0" ]]; then
    # echo "Match found: $(echo $1 | tr -d ':')"
    isLiveHost $(echo $1 | tr -d ':') $(echo $1 |sed -e 's/ip-//;s/\.compute\.internal//g;s/\..*$//g;s/-/./g;')
    if [[ "$?" -eq "1" ]]; then
      return 1
    else
      return 0
    fi
  else
    (( TOTAL_HOSTS++ ))
    (( UNK_HOSTS++ ))
    (( UNKNOWN_STATUS++ ))
    return 1
  fi
}

isLiveHost() {
  (( TOTAL_HOSTS++ ))
  HOST=$1
  echo $1 | egrep "compute.internal|^ip-" >/dev/null
  if [[ "$?" -eq "0" ]]; then
    HOST=$2
  fi
  ping -c 2 $HOST &>/dev/null
  if [[ "$?" -eq "0" ]]; then
    # echo -e "\e[34m$1 is live\e[0m"
    (( LIVE_HOSTS++ ))
    if [[ $1 == *"iw-uk"* ]]; then
      (( IW_HOSTS++ ))
    elif [[ $1 == *"pr-uk"* ]]; then
      (( PR_HOSTS++ ))
    elif [[ $1 == *"uk-uk"* ]]; then
      (( SRDF_HOSTS++ ))
    elif [[ $1 == *"compute.internal"* ]]; then
      (( AMZ_HOSTS++ ))
    else
      (( UNK_HOSTS++ ))
    fi
    return 0
  elif [[ "$?" -eq "1" ]]; then
    #echo -e "\e[31mUnknown host $1\e[0m"
    (( DEAD_HOSTS++ ))
    return 1
  else
    #echo "Unknown return code $? for host $1"
    (( UNKNOWN_STATUS++ ))
    return 1
  fi
}

reportSummary() {
  echo "============================================"
  echo -e "\e[34m${TOTAL_NODEGROUPS} nodegroups \e[0m"
  echo -e "\e[34mPR=${PR_HOSTS} IW=${IW_HOSTS} SRDF=${SRDF_HOSTS} AMZ=${AMZ_HOSTS} UNK=${UNK_HOSTS} live hosts \e[0m"
  echo -e "\e[34m${LIVE_HOSTS}/${TOTAL_HOSTS} hosts are live \e[0m"
  echo -e "\e[31m${DEAD_HOSTS}/${TOTAL_HOSTS} hosts are dead\e[0m"
  echo "${UNKNOWN_STATUS}/${TOTAL_HOSTS} hosts reporting unknown status"
  echo "============================================"
}

usage() {
  echo "USAGE: $0 file.name"
  exit 1
}

if [[ ${#@} -eq "0" ]]; then
  echo "Didn't get file as an argument, doing actual run"
  PPM=509
  doTheActualRun
elif [[ ${1} -gt 509 ]] && [[ ${1} -lt 530 ]]; then
  PPM=${1}
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
