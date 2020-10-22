#!/bin/bash

# Bootstrap routine for ECS instance
#
# When script has been modified upload it https://s3-eu-west-1.amazonaws.com/cms-tech-s3/ECS-bootstrap/cms-integration-bootstrap.sh

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

#Add app specific log directories
mkdir -p /var/log/apps/claro /var/log/apps/reuters /var/log/apps/ap

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

#Set up FSx mount
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/ftfsx.sh ./
. ./ftfsx.sh

#Add hanging network share revival script on cron
aws s3 cp s3://cms-tech-s3/ECS-bootstrap/network-share-revival-ftfsx.sh ./
(crontab -l ; echo "*/2 * * * * bash /network-share-revival-ftfsx.sh") | crontab -

echo "ECS customisation DONE"
