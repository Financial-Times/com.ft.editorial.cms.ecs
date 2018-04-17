#!/usr/bin/env bash
#
# Configure autofs for eomfs NFS shares
#
# Maintainer: jussi.heinonen@ft.com
# Date: 17.4.2018

. $(dirname $0)/functions.sh

NFS_TIMEOUT="300"
AUTOFS_MASTER="/etc/auto.master.d/eomfs.autofs"
declare -A NFS_SERVER
NFS_SERVER[dev]="methode.dev.internal.ft.com"
NFS_SERVER[int]="methode.int.internal.ft.com"
NFS_SERVER[test]="methode.test.internal.ft.com"
NFS_SERVER[prod]="methode.internal.ft.com"

declare -a APPS=( "wires" "staging" "archive" )

# Set environment dev in case it's not been set
test -z $ENV && export ENV="dev"

addCron() {
  # $1 is the directory to mount, e.g. /var/lib/eomfs/wires
  MOUNTPOINT="$1"
  # CRON_MIN is is NFS_TIMEOUT in minutes plus 1 minute, allow autofs mount to timeout before remounting
  CRON_MIN=$(expr ${NFS_TIMEOUT} / 60 + 1)
  # Append on crontab
  (crontab -l ; echo "*/${CRON_MIN} * * * * (cd ${MOUNTPOINT})") | crontab -
}

info "environment is $ENV"

# Reset master file
> ${AUTOFS_MASTER}

for each in ${APPS[*]}; do
  info "$0: Configuring NFS share ${each}.${NFS_SERVER[${ENV}]}"
  mkdir -p /var/lib/eomfs/${each}
  echo "/- /etc/auto.master.d/auto.eomfs.${each} --timeout=${NFS_TIMEOUT} --verbose" >> ${AUTOFS_MASTER}
  echo "/var/lib/eomfs/${each} -rw,soft,intr,bg,retrans=1,retry=0,noatime,nodiratime,timeo=${NFS_TIMEOUT} ${each}.${NFS_SERVER[${ENV}]}:/var/lib/eomfs" > /etc/auto.master.d/auto.eomfs.${each}
  addCron /var/lib/eomfs/${each}
done

info "$0: Restarting autofs"
service autofs restart
