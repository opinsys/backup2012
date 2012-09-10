#!/bin/bash

organization=$1
host=$2
excluded_dirs="/home/opinsys,/home/siirto"

logger "Rsyncing target ${host}.${organization} ..."
rsync -zavx --exclude-from "/root/backup2012/excluded.txt" root@${host}.${organization}.opinsys.fi:/home /backup/$organization/$host &> /dev/null
returncode=$?

if (( $returncode != 0 )); then
     logger "RSYNC BACKUP process interrupted abnormally! host: ${host} organization: ${organization} return code: $returncode"
else
     logger "Rsync backup for target ${host}.${organization} finished OK."
fi

