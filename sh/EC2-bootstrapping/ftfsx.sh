#!/usr/bin/env bash
#
# Configure autofs for FSx Samba shares
# 
# NOTE: After updating this file upload it to 
# https://s3.console.aws.amazon.com/s3/buckets/cms-tech-s3/ECS-bootstrap/?region=eu-west-1
# Bucket lives in ft-tech-editorial-prod account
# Then re-run bootstrap process by rebuilding cluster
#
# Maintainer: jussi.heinonen@ft.com
# Date: 25.6.2020

. $(dirname $0)/functions.sh

addCron() {
  # $1 is the directory to mount, e.g. /var/lib/eomfs/wires
  MOUNTPOINT="$1"
  # CRON_MIN is is SMB_TIMEOUT in minutes plus 1 minute, allow autofs mount to timeout before remounting
  CRON_MIN=$(expr ${SMB_TIMEOUT} / 60)
  # Append on crontab
  (crontab -l ; echo "*/${CRON_MIN} * * * * (cd ${MOUNTPOINT})") | crontab -
}

SMB_TIMEOUT="300"
AUTOFS_MASTER="/etc/auto.master.d/ftfsx.autofs"
ECS_CLUSTER=$(grep ECS_CLUSTER /etc/ecs/ecs.config | cut -d '=' -f 2)

declare -A FSX_FT
FSX_FT[dev]="://amznfsxnw7oucfb.ad.ft.com/share/Dev"
FSX_FT[test]="://amznfsxnw7oucfb.ad.ft.com/share/Test"
FSX_FT[prod]="://amznfsxnw7oucfb.ad.ft.com/share/Production"

# Set environment int in case it's not been set
test -z $ENV && export ENV="dev"
info "environment is $ENV"

USER=$(aws secretsmanager get-secret-value --secret-id ${ECS_CLUSTER} --query SecretString | jq -r '.' | jq -r .fsx_username)
PASS=$(aws secretsmanager get-secret-value --secret-id ${ECS_CLUSTER} --query SecretString | jq -r '.' | jq -r .fsx_password)

# Bailout if user unset
test -z ${#USER} && errorAndExit "No Samba username set. Exit 1." 1
# Bailout if pass unset
test -z ${#PASS} && errorAndExit "No Samba password set. Exit 1." 1

info "$0: Configuring Samba shares ${FSX_FT[${ENV}]}"
mkdir -p /var/lib/ftfsx

echo "/- /etc/auto.master.d/auto.ftfsx --verbose" >> ${AUTOFS_MASTER}
echo "/var/lib/ftfsx -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${FSX_FT[${ENV}]}" > /etc/auto.master.d/auto.ftfsx

addCron /var/lib/ftfsx

createInitScriptForNetworkShare /var/lib/ftfsx

info "$0: Restarting autofs"
service autofs restart
