#!/bin/bash

ps xw | grep /usr/local/bin/rsync.sh | grep -v grep | sed 's/.*rsync.sh //' | awk "{print \$2,\$1,\"3 Failed: FORCE KILLED `date --rfc-3339=seconds`\"}" | sed 's/ /./'  >> /var/run/daily_backup_report

YRMON=$(date +%Y-%m)
DAY=$(date +%Y-%m-%d-%a)
DIR=/var/www/backup/report/$YRMON
mkdir -p $DIR
FILENAME=$DIR/report-$DAY

sort /var/run/daily_backup_report | sed 's/ 1 $/ 1 UNKNOWN ERROR/' > $FILENAME
cat $FILENAME | mail -s "Daily backup report" 'tuki@opinsys.fi'

pkill -f rsync && sleep 3 && pkill -f rsync




