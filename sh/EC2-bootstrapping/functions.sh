
info() {
  echo -e "\e[34mINFO: ${1}\e[0m"
  logger $1
}

errorAndExit() {
  logger $1
  echo $1
  exit $2
}

createInitScriptForNetworkShare() {
  # ARG1 mountpoint, eg. /var/lib/eomfs/wires

  TARGET_DIR="/etc/init.d"
  INIT_TEMPLATE='#!/bin/bash

  # chkconfig: - 99 00
  # description: Mount network share at boot time
  # processname: %s

  ### BEGIN INIT INFO
  # Provides         : %s
  # Required-Start   : $local_fs $remote_fs $network $time $named
  # Required-Stop    : $local_fs $remote_fs $network $time $named
  # Default-Start    : 2 3 4 5
  # Default-Stop     : 0 1 6
  # Short-Description: Mount network share at boot time
  # Description      : See Short-Description
  ### END INIT INFO


  PNAME="%s"
  MOUNTPOINT="%s"
  LOCKFILE=touch /var/lock/subsys/${PNAME}


  function stop () {
    rm -f ${LOCKFILE}
    info "$0/${FUNCNAME}: deleted lock file ${LOCKFILE}"
  }

  function start () {
    touch ${LOCKFILE}
    (cd ${MOUNTPOINT})
    info "$0/${FUNCNAME}: ${MOUNTPOINT} mounted"
  }
  case "$1" in
    stop)
      stop
    ;;
    start)
      start
    ;;
    status)
      if [[ -f "${LOCKFILE}" ]]; then
        info ${PNAME} running on host $(hostname)
        exit 0
      else
        info ${PNAME} stopped on host $(hostname)
        exit 2
      fi;;
    restart)
      stop
      start
      ;;
      *)
      echo "usage: service ${PNAME} {start|stop|status|restart}"
      exit 1;;
  esac'

  if [[ "$#" -gt "0" ]]; then # Check that function is called with at least 1 argument
    MOUNTPOINT="$1"
    PNAME="mount$(echo ${MOUNTPOINT} | tr '/' '-')"
    printf "${INIT_TEMPLATE}" ${PNAME} ${PNAME} ${PNAME} ${MOUNTPOINT} > ${TARGET_DIR}/${PNAME}
    chmod 755 ${TARGET_DIR}/${PNAME}
    chkconfig ${PNAME} on
  else
    info "$0/${FUNCNAME}: Please provide mountpoint as an argument"
  fi
}
