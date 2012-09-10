#!/bin/bash

organization=$1
host=$2

logger "Rsyncing target ${host}.${organization} ..."
rsync -zavx root@${host}.${organization}.opinsys.fi:/home /backup/$organization/$host &> /dev/null
returncode=$?

if (( $returncode != 0 )); then
     logger "RSYNC BACKUP process interrupted abnormally! host: ${host} organization: ${organization} return code: $returncode"
else
     logger "Rsync backup for target ${host}.${organization} finished OK."
fi

