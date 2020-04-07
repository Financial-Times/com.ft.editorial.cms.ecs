#!/usr/bin/env bash
#
# Configure autofs for nasfs12.ad.ft.com / FSx Samba shares
# 
# NOTE: After updating this file upload it to 
# https://s3.console.aws.amazon.com/s3/buckets/cms-tech-s3/ECS-bootstrap/?region=eu-west-1
# Bucket lives in ft-tech-editorial-prod account
# Then re-run bootstrap process by rebuilding cluster
#
# Maintainer: jussi.heinonen@ft.com
# Date: 27.3.2018
# Updated: 20.3.2020

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
  CRON_MIN=$(expr ${SMB_TIMEOUT} / 60)
  # Append on crontab
  (crontab -l ; echo "*/${CRON_MIN} * * * * (cd ${MOUNTPOINT})") | crontab -
}

SMB_TIMEOUT="300"
AUTOFS_MASTER="/etc/auto.master.d/nasfs12.autofs"
declare -A SMB_BARCODE
SMB_BARCODE[int]="://nasfs12.ad.ft.com/Int/Barcode"
SMB_BARCODE[test]="://nasfs12.ad.ft.com/Test/Barcode"
SMB_BARCODE[prod]="://nasfs12.ad.ft.com/Production/Barcode"
declare -A FSX_BARCODE
FSX_BARCODE[int]="://amznfsxon2iuvfb.ad.ft.com/share/Int/Barcode"
FSX_BARCODE[test]="://amznfsxon2iuvfb.ad.ft.com/share/Test/Barcode"
FSX_BARCODE[prod]="://amznfsxon2iuvfb.ad.ft.com/share/Production/Barcode"
declare -A SMB_OUTPUT
SMB_OUTPUT[int]="://nasfs12.ad.ft.com/Int/Methode_Input"
SMB_OUTPUT[test]="://nasfs12.ad.ft.com/Test/Methode_Input"
SMB_OUTPUT[prod]="://nasfs12.ad.ft.com/Production/Methode_Input"
declare -A FSX_OUTPUT
FSX_OUTPUT[int]="://amznfsxon2iuvfb.ad.ft.com/share/Int/Methode_Input"
FSX_OUTPUT[test]="://amznfsxon2iuvfb.ad.ft.com/share/Test/Methode_Input"
FSX_OUTPUT[prod]="://amznfsxon2iuvfb.ad.ft.com/share/Production/Methode_Input"
declare -A FSX_FT
FSX_FT[int]="://amznfsxnw7oucfb.ad.ft.com/share/Dev"
FSX_FT[test]="://amznfsxnw7oucfb.ad.ft.com/share/Test"
FSX_FT[prod]="://amznfsxnw7oucfb.ad.ft.com/share/Production"

# Set environment int in case it's not been set
test -z $ENV && export ENV="int"
info "environment is $ENV"

USER=$(credstashLookup com.ft.editorial.methode.samba.username)
PASS=$(credstashLookup com.ft.editorial.methode.samba.password)

# Bailout if user unset
test -z ${#USER} && errorAndExit "No Samba username set. Exit 1." 1
# Bailout if pass unset
test -z ${#PASS} && errorAndExit "No Samba password set. Exit 1." 1

info "$0: Configuring Samba shares ${SMB_BARCODE[${ENV}]}, ${FSX_BARCODE[${ENV}]}, ${SMB_OUTPUT[${ENV}]} and ${FSX_OUTPUT[${ENV}]}"
mkdir -p /var/lib/output /var/lib/outputfsx /var/lib/barcode /var/lib/barcodefsx /var/lib/ftfsx
echo "/- /etc/auto.master.d/auto.output --verbose" > ${AUTOFS_MASTER}
echo "/- /etc/auto.master.d/auto.barcodefsx --verbose" >> ${AUTOFS_MASTER}
echo "/- /etc/auto.master.d/auto.barcode --verbose" >> ${AUTOFS_MASTER}
echo "/- /etc/auto.master.d/auto.outputfsx --verbose" >> ${AUTOFS_MASTER}
echo "/- /etc/auto.master.d/auto.ftfsx --verbose" >> ${AUTOFS_MASTER}
echo "/var/lib/output -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${SMB_OUTPUT[${ENV}]}" > /etc/auto.master.d/auto.output
echo "/var/lib/barcode -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${SMB_BARCODE[${ENV}]}" > /etc/auto.master.d/auto.barcode
echo "/var/lib/barcodefsx -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${FSX_BARCODE[${ENV}]}" > /etc/auto.master.d/auto.barcodefsx
echo "/var/lib/outputfsx -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${FSX_OUTPUT[${ENV}]}" > /etc/auto.master.d/auto.outputfsx
echo "/var/lib/ftfsx -fstype=cifs,rw,sec=ntlmssp,gid=15025,uid=57456,user=${USER},pass=${PASS},vers=2.1 ${FSX_FT[${ENV}]}" > /etc/auto.master.d/auto.ftfsx

addCron /var/lib/barcode
addCron /var/lib/barcodefsx
addCron /var/lib/output
addCron /var/lib/outputfsx
addCron /var/lib/ftfsx
createInitScriptForNetworkShare /var/lib/barcode
createInitScriptForNetworkShare /var/lib/barcodefsx
createInitScriptForNetworkShare /var/lib/output
createInitScriptForNetworkShare /var/lib/outputfsx
createInitScriptForNetworkShare /var/lib/ftfsx

info "$0: Restarting autofs"
service autofs restart
