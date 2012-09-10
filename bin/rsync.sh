#!/bin/bash

organization=$1
host=$2

rsync -zavx root@${host}.${organization}.opinsys.fi:/home /backup/$organization/$host &> /dev/null
returncode=$?

if (( $returncode != 0 )); then
     logger "RSYNC BACKUP process interrupted abnormally! host: ${host} organization: ${organization} return code: $returncode"
fi

