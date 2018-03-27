#!/bin/bash

# Bootstrap routine for ECS instance
#
# When script has been modified upload it https://s3-eu-west-1.amazonaws.com/cms-tech-s3/ECS-bootstrap/cms-ecs-bootstrap.sh

#Workout enviroment name
case $1 in
	"p")
		export ENV="prod"
		;;
	"int")
		export ENV="int"
		;;
	"t")
		export ENV="test"
		;;
	"d")
		export ENV="dev"
		;;
	"*")
		export ENV="dev"
		;;
esac

#Adding tomcat user (CMT-1909)
echo "Adding tomcat user"
adduser -c "Tomcat user" -d /var/log/apps -M -s /sbin/nologin -u 1000 -U tomcat
id tomcat
echo

#Adding container logging locations (CMT-1910)
echo "Adding container logs locations"
for s in restapi wires-mis staging-mis rhelper preview webclient checkin formats mfm image datasource prodarch portalpub postprint eventhandler adorder mms mss msis
do
  mkdir -v /var/log/apps/methode-$s
  chown -v tomcat. /var/log/apps/methode-$s
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

#Configure autofs for NFS shares
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/eomfs.sh ./
. ./eomfs.sh

#Configure autofs for Samba
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/nasfs12.sh ./
. ./nasfs12.sh


echo

echo "CMS ECS customisation DONE"
