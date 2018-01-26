#!/usr/bin/env bash
#
# Set FT DNS nameservers wih Quad9 fallback
#
# Script requires valid resolv.conf source file set in variable RESOLV_CONF_SOURCE
#
# Maintainer: jussi.heinonen@ft.com
# Date: 19.1.2018

RESOLV_CONF_SOURCE="s3://cms-tech-s3/ECS-bootstrap/files/resolv.conf"
RESOLV_CONF_TARGET="/etc/resolv.conf"

# Source common functions
. $(dirname $0)/functions.sh

disablePeerdns() {
  # Set PEERDNS=no in /etc/sysconfig/network-scripts/ifcfg-eth0
  IFCFG="/etc/sysconfig/network-scripts/ifcfg-$(route | grep default | awk '{print $8}')" || errorAndExit "$0/${FUNCNAME}: Failed to resolve network-script for default interface" 1
  test -f ${IFCFG} || errorAndExit "$0/${FUNCNAME}: File ${IFCFG} not found" 1
  sed -ie 's/PEERDNS=yes/PEERDNS=no/g' ${IFCFG} || errorAndExit "$0/${FUNCNAME}: Failed to set PEERDNS=no" 1
}

copyResolvConf() {
  aws s3 ls ${RESOLV_CONF_SOURCE} >/dev/null || errorAndExit "$0/${FUNCNAME}: File ${RESOLV_CONF_SOURCE} not found" 1
  aws s3 cp ${RESOLV_CONF_SOURCE} ${RESOLV_CONF_TARGET}
}

disablePeerdns
copyResolvConf
