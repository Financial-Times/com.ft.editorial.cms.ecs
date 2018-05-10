#!/usr/bin/env bash
#
# Process task names and run docker kill against it
#
# USAGE: ./docker-kill.sh methode-rhelper-wires-int methode-rhelper-staging-int
#
#
# Maintainer: jussi.heinonen@ft.com
# Date: 10.5.2018

info() {
  logger "$0: $1"
  echo $1
}

for each in $*; do
  info "Looking for tasks with name ${each} to kill"
  while read CONTAINER_ID; do
    info "Killing container id ${CONTAINER_ID} (${each})"
    docker kill --signal=SIGHUP ${CONTAINER_ID}
  done <  <(docker ps | grep ${each} | awk '{print $1}')
done
