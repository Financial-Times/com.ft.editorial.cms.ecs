#!/bin/bash

# Bootstrap routine for ECS instance
#
# When script has been modified upload it https://s3-eu-west-1.amazonaws.com/cms-tech-s3/ECS-bootstrap/cms-ecs-bootstrap.sh

#Workout enviroment name
case $1 in
	"p")
		export ENV="prod"
		export EFSIP=254
		;;
	"int")
		export ENV="int"
		export EFSIP=252
		;;
	"t")
		export ENV="test"
		export EFSIP=253
		;;
	"d")
		export ENV="dev"
		export EFSIP=251
		;;
	"*")
		export ENV="dev"
		;;
esac

#Adding tomcat user (CMT-1909)
echo "Adding tomcat user"
adduser -c "Tomcat user" -d /var/log/apps -M -s /sbin/nologin -u 57456 -U tomcat
id tomcat
echo

#Adding container logging locations (CMT-1910)
echo "Adding container logs locations"
for s in restapi wires-mis staging-mis wires-mfm staging-mfm rhelper preview webclient checkin formats mfm image datasource prodarch portalpub postprint eventhandler adorder mms mss msis outputmanager claro
do
  mkdir -v /var/log/apps/methode-$s
  chown -v tomcat. /var/log/apps/methode-$s
	chmod -v 777 /var/log/apps/methode-$s
done
echo

#Adding logging drivers to ECS config (CMT-1949)
echo "Adding logging drivers to ECS config"
echo 'ECS_AVAILABLE_LOGGING_DRIVERS= ["json-file","awslogs","splunk"]' >> /etc/ecs/ecs.config
cat /etc/ecs/ecs.config
echo
stop ecs && start ecs

#Updating Splunk collector configuration (CMT-1890)
echo "Updating Splunk collector configuration"
cp -v /opt/splunkforwarder/etc/system/local/props.conf{,.bck}
echo -e "\n[source::.../log/apps/*/tomcat_access_*.log]\nsourcetype = access_combined_time\npriority = 99" >> /opt/splunkforwarder/etc/system/local/props.conf
diff -U0 /opt/splunkforwarder/etc/system/local/props.conf{.bck,}
echo
cp -v /opt/splunkforwarder/etc/system/local/inputs.conf{,.bck}
sed -i -e "\#\[monitor:///var/log/apps\]#,+4s/\(index = \).*/\1cms-ecs_$ENV/" /opt/splunkforwarder/etc/system/local/inputs.conf
diff -U0 /opt/splunkforwarder/etc/system/local/inputs.conf{.bck,}
echo

#Restaring Splunk collector
/etc/init.d/splunk restart
echo

#Pull common functions
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/functions.sh ./

#Set FT nameservers
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/nameservers.sh ./
. ./nameservers.sh

if [[ "${ENV}" != "int" ]]; then # EOMFS decommissioned in INT so no point of adding this
	#Configure autofs for NFS shares
	aws s3 cp s3://cms-tech-s3/ECS-bootstrap/eomfs.sh ./
	. ./eomfs.sh
fi

#Configure autofs for Samba
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/nasfs12.sh ./
. ./nasfs12.sh

aws s3 cp s3://cms-tech-s3/ECS-bootstrap/network-share-revival.sh ./
(crontab -l ; echo "*/2 * * * * bash /network-share-revival.sh") | crontab -

#Download docker-kill.sh script
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/docker-kill.sh ./

echo

#CMT-2375 - Add local dir and cron job for lookup.xml file
mkdir -v /var/lib/eomfs/CCMS
(crontab -l ; echo "*/10 * * * * /usr/bin/rsync -achv --timeout=2 /var/lib/eomfs/staging/CCMS/lookup.xml /var/lib/eomfs/CCMS/") | crontab -

#Mounting CMS EFS
IP_ADDR=$(/usr/bin/curl -sS http://169.254.169.254/latest/meta-data/local-ipv4)
EFS_MOUNT_IP="${IP_ADDR%\.[0-9]*}.$EFSIP"
echo "ESF mount point IP: $EFS_MOUNT_IP"
mkdir -pv /var/lib/efs
echo "## CMS EFS" >> /etc/fstab
echo -e "$EFS_MOUNT_IP:/\t/var/lib/efs\tnfs4\trw,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport\t0\t0" >> /etc/fstab

mount -v /var/lib/efs

for mapp in archive staging wires
do
	mkdir -pv /var/lib/efs/$mapp
	chown -v 57456:15025 /var/lib/efs/$mapp
	chmod -v 775 /var/lib/efs/$mapp
done

echo "CMS ECS customisation DONE"
