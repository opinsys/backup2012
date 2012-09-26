#!/bin/bash

organization=$1
host=$2
logger "Rsyncing target ${host}.${organization} ..."
echo "$host.$organization 0 started `date --rfc-3339=seconds`" >> /var/run/daily_backup_report
rsync --stats -hzax --exclude-from "/etc/opinsys/excluded_backup_dirs.txt" root@${host}.${organization}.opinsys.fi:/home /backup/$organization/$host | sed 's/^/;/' | grep Total | xargs | sed "s/^/${host}.${organization} 1 /" >> /var/run/daily_backup_report
returncode=${PIPESTATUS[0]}
echo "$host.$organization 2 ended `date --rfc-3339=seconds`" >> /var/run/daily_backup_report

if (( $returncode != 0 )); then
     logger "RSYNC BACKUP process interrupted abnormally! host: ${host} organization: ${organization} return code: $returncode"
     echo "$host.$organization 3 STATUS FAIL $returncode" >> /var/run/daily_backup_report
     echo ${host}.${organization} >> /var/run/failed_backup_hosts.txt
else
     echo "$host.$organization 3 STATUS OK $returncode" >> /var/run/daily_backup_report
     logger "Rsync backup for target ${host}.${organization} finished OK."
fi

