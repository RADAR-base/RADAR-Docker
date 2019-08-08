#!/bin/bash

raw_subject=${1}
#echo $HOME
if [[ $raw_subject = 'help' ]];then
	sudo docker-compose -f ../xmpp-server/docker-compose.yml exec hsqldb sh -c "java -jar /opt/hsqldb/lib/sqltool.jar --help"
else
	match="-"
	repl="\\002d"
	subject=${raw_subject//$match/$repl}
#	echo $subject
	java -jar ./hsqldb/sqltool.jar --rcFile=/home/ubuntu/sqltool.rc --debug --sql="
	select status_info.subject_id, notification_info.title, notification_info.ttl_seconds, notification_info.message, notification_info.execution_time from notification_info inner join status_info on notification_info.notification_task_uuid = status_info.notification_task_uuid where status_info.subject_id=U&'${subject}';" db
fi
