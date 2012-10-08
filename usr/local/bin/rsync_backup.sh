#!/bin/bash

. /root/.keychain/$HOSTNAME-sh

# We read host list and strip "opinsys.fi" off from each hostname
logger "RSYNC BACKUP: Started."

backup () {

   hostorg=$1
   # hostorg = ltspN.kunta
   # we split contents of hostorg into two variables (host, organization)
   organisaatio=${hostorg##*.}
   host=${hostorg%%.*}

   # We create backup directory if it does not exist
   if [ ! -d /backup/$organisaatio/$host ]; then
       mkdir -p /backup/$organisaatio/$host
   fi

   # Start rsync process and continue
   /usr/local/bin/rsync.sh $organisaatio $host &

   # Sleeping a bit to make the start a little bit lighter for our cpu
   sleep 40

   # Sleep (and don't start more rsyncs) if there are already enough rsync processes running
   number_of_rsyncs=$(ps axuc | grep rsync | grep -v rsync.*sh | wc -l)
   while (( number_of_rsyncs > 40 )); do
       sleep 20
       number_of_rsyncs=$(ps axuc | grep rsync | grep -v rsync.sh | wc -l)
   done
}

# Flush list of failed hosts and daily report
echo -n '' > /var/run/failed_backup_hosts.txt
echo -n '' > /var/run/daily_backup_report

# Go through the host list and do backup
sed 's/.opinsys.fi//' /etc/opinsys/customers_ltsp_servers.txt | grep -v -f /etc/opinsys/excluded_backup_hosts.txt  | while read ho; do 
   backup $ho
done

# Retry failed hosts
cat /var/run/failed_backup_hosts.txt  | while read ho; do 
   backup $ho
done

logger "RSYNC BACKUP: Finished."
