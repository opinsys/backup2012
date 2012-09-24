#!/bin/bash

# This script lists first the running rsync processes and logs them as force killed before killing them
ps xw | grep /usr/local/bin/rsync.sh | grep -v grep | sed 's/.*rsync.sh //' | awk "{print \$2,\$1,\"3 `date --rfc-3339=seconds`\"}" | sed 's/ /./'  >> /var/run/daily_backup_report

sort /var/run/daily_backup_report | mail -s "Daily backup report" 'tuki@opinsys.fi'

pkill -f -USR1 rsync && sleep 5 && pkill -9 -f rsync




