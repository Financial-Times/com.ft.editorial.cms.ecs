#!/usr/bin/env bash
#
# Configure autofs for nasfs12.ad.ft.com Samba shares
#
# Maintainer: jussi.heinonen@ft.com
# Date: 27.3.2018

. $(dirname $0)/functions.sh

credstashLookup() {
  credstash_key="$1"
  credstash_table="cms-methode-credential-store"
  credstash_region="eu-west-1"
  RESPONSE=$(credstash -r ${credstash_region} -t ${credstash_table} get ${credstash_key})
  if [[ "${RESPONSE}"  =~ "An error occurred" ]]; then
    echo "credstash look up failed. QUERY: credstash -r ${credstash_region} -t ${credstash_table} get ${credstash_key}. Exit 1."
    exit 1
  else
    echo ${RESPONSE}
  fi

}

addCron() {
  # $1 is the directory to mount, e.g. /var/lib/eomfs/wires
  MOUNTPOINT="$1"
  # CRON_MIN is is SMB_TIMEOUT in minutes plus 1 minute, allow autofs mount to timeout before remounting
  CRON_MIN=$(expr ${SMB_TIMEOUT} / 60 + 1)
  # Append on crontab
  (crontab -l ; echo "*/${CRON_MIN} * * * * (cd ${MOUNTPOINT})") | crontab -
}

SMB_TIMEOUT="300"
AUTOFS_MASTER="/etc/auto.master.d/nasfs12.autofs"
declare -A SMB_BARCODE
SMB_BARCODE[dev]="://nasfs12.ad.ft.com/Int/Barcode"
SMB_BARCODE[int]="://nasfs12.ad.ft.com/Int/Barcode"
SMB_BARCODE[test]="://nasfs12.ad.ft.com/Test/Barcode"
SMB_BARCODE[prod]="://nasfs12.ad.ft.com/Production/Barcode"
declare -A SMB_OUTPUT
SMB_OUTPUT[dev]="://nasfs12.ad.ft.com/Development/Methode_Input"
SMB_OUTPUT[int]="://nasfs12.ad.ft.com/Int/Methode_Input"
SMB_OUTPUT[test]="://nasfs12.ad.ft.com/Test/Methode_Input"
SMB_OUTPUT[prod]="://nasfs12.ad.ft.com/Production/Methode_Input"


# Set environment dev in case it's not been set
test -z $ENV && export ENV="dev"
info "environment is $ENV"

USER=$(credstashLookup com.ft.editorial.methode.samba.username)
PASS=$(credstashLookup com.ft.editorial.methode.samba.password)

# Bailout if user unset
test -z ${#USER} && errorAndExit "No Samba username set. Exit 1." 1
# Bailout if pass unset
test -z ${#PASS} && errorAndExit "No Samba password set. Exit 1." 1

info "$0: Configuring Samba shares ${SMB_BARCODE[${ENV}]} and ${SMB_OUTPUT[${ENV}]}"
mkdir -p /var/lib/output /var/lib/barcode
echo "/- /etc/auto.master.d/auto.output --verbose" > ${AUTOFS_MASTER}
echo "/- /etc/auto.master.d/auto.barcode --verbose" >> ${AUTOFS_MASTER}
echo "/var/lib/output -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${SMB_OUTPUT[${ENV}]}" > /etc/auto.master.d/auto.output
echo "/var/lib/barcode -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${SMB_BARCODE[${ENV}]}" > /etc/auto.master.d/auto.barcode

addCron /var/lib/barcode
addCron /var/lib/output
createInitScriptForNetworkShare /var/lib/barcode
createInitScriptForNetworkShare /var/lib/output

info "$0: Restarting autofs"
service autofs restart
