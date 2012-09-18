#!/bin/bash

ps xw | grep /usr/local/bin/rsync.sh | grep -v grep | sed 's/.*rsync.sh //' | awk "{print \$2,\$1,\"3 `date --rfc-3339=seconds`\"}" | sed 's/ /./'  >> /var/run/daily_backup_report

sort /var/run/daily_backup_report | mail -s "Daily backup report" 'tuki@opinsys.fi'

pkill -f rsync && sleep 3 && pkill -f rsync




