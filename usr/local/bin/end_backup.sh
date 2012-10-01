#!/bin/bash

# Read settings
. /etc/opinsys/backup.conf

ps xw | grep /usr/local/bin/rsync.sh | grep -v grep | sed 's/.*rsync.sh //' | awk "{print \$2,\$1,\"3 Failed: FORCE KILLED `date --rfc-3339=seconds`\"}" | sed 's/ /./'  >> /var/run/daily_backup_report

pkill -f rsync && sleep 3 && pkill -f rsync

/usr/local/bin/report.pl $HTTP_SERVER_IP_ADDR | mail -s "Daily backup report" $REPORT_EMAIL_ADDRS
