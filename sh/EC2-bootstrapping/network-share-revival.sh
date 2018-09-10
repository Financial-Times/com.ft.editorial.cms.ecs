#!/usr/bin/env bash
#
# Detect hanging network shares and recover them.
# MOre info https://jira.ft.com/browse/CMT-2159
#
# USAGE: ./network-share-revival.sh

info() {
  echo -e "\e[34m${0}: ${1}\e[0m"
  logger ${0}: ${1}
}

error() {
  echo -e "\e[31m${0}: $1\e[0m"
  logger ${0}: ${1}
}

checkForHangingShares() {
  # Check process list and identify hanging cd commands for network shares
  PATTERN="/bin/bash -c (cd /var/lib"
  PROC_COUNT="$(ps -ef | grep "${PATTERN}" | grep -v grep | wc -l)"
  if [[ "${PROC_COUNT}" -gt "0" ]]; then
    for each in $(ps -ef | grep "${PATTERN}" | grep -v grep | awk '{print $11}' | tr -d ')' | sort | uniq ); do
      info "Trying to recover network share ${each}"
      unmountShare ${each}
      killHangingProcesses ${each}
      /etc/init.d/autofs restart && info "Autofs service restarted"
      (cd ${each})
    done
  else
    info "No hanging network shares detected"
  fi
}

killHangingProcesses() {
  SHARE="$1"
  ps -ef | grep "/bin/bash -c (${SHARE}" | grep -v grep | awk '{print $2}' | xargs kill -9
}

unmountShare() {
  # Lookup share type (nfs4 or cifs) and unmount it
  SHARE="$1"
  SHARE_TYPE="$(mount | grep ${SHARE} | grep -v autofs | awk '{print $5}')"
  if [[ -z "${SHARE_TYPE}" ]]; then
    info "Unable to resolve mount type for share ${SHARE}. Assuming it is nfs"
    SHARE_TYPE="nfs"
  fi
  umount -f -a -t ${SHARE_TYPE} -l ${SHARE} && umount -i -f -l ${SHARE}
  info "umount commands issued for share ${SHARE}"

}

# ENTRYPOINT
sleep $(( ( RANDOM % 10 )  + 1 )) # Add a few random sleep seconds to avoid clash with mounting tasks
checkForHangingShares

# Checking for gone away mounts

for m in barcode archive staging wires output
do
  mount_test=$(grep -c $m /proc/mounts)
  if [ "$mount_test" -eq 0 ]
  then
    info "$m mount gone away, restarting autofs"
    /etc/init.d/autofs restart && info "Autofs service restarted"
    exit 0
  else
    info "$m mount seems fine"
  fi
done

