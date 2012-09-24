#!/bin/bash

ps xw | grep /usr/local/bin/rsync.sh | grep -v grep | sed 's/.*rsync.sh //' | awk "{print \$2,\$1,\"3 Failed: FORCE KILLED `date --rfc-3339=seconds`\"}" | sed 's/ /./'  >> /var/run/daily_backup_report

pkill -f rsync && sleep 3 && pkill -f rsync

/usr/local/bin/report.pl | mail -s "Daily backup report" 'mvuori@opinsys.fi'





