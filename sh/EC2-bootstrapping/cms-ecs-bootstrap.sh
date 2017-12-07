#!/bin/bash

#Workout enviroment name
case $1 in
	"p")
		export ENV="prod"
		;;
	"int")
		export ENV="prod"
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
adduser -c \"Tomcat user\" -d /var/log/apps -M -s /sbin/nologin -u 1000 -U tomcat

#Adding container logging locations (CMT-1910)
for s in restapi mis rhelper preview webclient checkin formats mfm image datasource prodarch portalpub postprint eventhandler adorder mms mss msis
do
  mkdir /var/log/apps/methode-$s
  chown tomcat. /var/log/apps/methode-$s
done

#Adding logging drivers to ECS config (CMT-1949)
echo 'ECS_AVAILABLE_LOGGING_DRIVERS= ["json-file","awslogs","splunk"]' >> /etc/ecs/ecs.config

#Updating Splunk collector configuration (CMT-1890)
cp /opt/splunkforwarder/etc/system/local/props.conf{,bck}
sed -i -e '\#\[source::.../log/(apps|apps/...|restricted/\*/apps|restricted/\*/apps/...)/\*\.log\]#{n; s/\(sourcetype = \)log4j/\1access_combined_time/}' /opt/splunkforwarder/etc/system/local/props.conf
cp /opt/splunkforwarder/etc/system/local/inputs.conf{,.bck}
sed -i -e '\#\[monitor:///var/log/apps\]#,+4s/\(whitelist = \).*/\1tomcat_access_.\*\\.log\$/' /opt/splunkforwarder/etc/system/local/inputs.conf
sed -i -e "\#\[monitor:///var/log/apps\]#,+4s/\(index = \).*/\1cms-ecs_$ENV/" /opt/splunkforwarder/etc/system/local/inputs.conf

