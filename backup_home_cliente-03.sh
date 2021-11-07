#!/bin/bash

dt=`date +'%FT%T.%2NZ'`

if [ ! -d "./logs" ]; then
  mkdir logs
fi

touch ./logs/backup_home_cliente-03.sh_${dt}.log
archivoLog="./logs/backup_home_cliente-03.sh_${dt}.log"

ping -c 1 -W 1 192.168.20.3
if [ "$?" = 0 ]
then
  
	rsync -avzrh -stats -e ssh --delete --no-perms --exclude '.cache' jason@192.168.20.3:/home /media/disco_backups/ --log-file=$archivoLog
  
else
  echo "El servidor destino está offline" >> $archivoLog
fi

