#!/bin/bash

# We read host list and strip "opinsys.fi" off from each hostname
logger "RSYNC BACKUP: Started."
sed 's/.opinsys.fi//' /etc/opinsys/customers_ltsp_servers.txt | while read hostorg; do 

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

   # Sleep (and don't start more rsyncs) if there are already enought rsyncs running
   number_of_rsyncs=$(ps axuc | grep rsync | grep -v rsync.sh | wc -l)
   while (( number_of_rsyncs > 30 )); do
       sleep 30
       number_of_rsyncs=$(ps axuc | grep rsync | grep -v rsync.sh | wc -l)
   done
done
logger "RSYNC BACKUP: Finished."
