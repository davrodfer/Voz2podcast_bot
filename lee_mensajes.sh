#!/bin/bash

. `dirname $0`/bot.config
source ${BASEDIR}/funciones.sh

UPDATES=${TMPDIR}/${TOKENHASH}_updates
OFFSETF=${TMPDIR}/${TOKENHASH}_offset

while true; do
  if [ -s "${OFFSETF}" ] ; then
    OFFSET=`cat -- ${OFFSETF}`
    if [ -z "$OFFSET" ]; then
       OFFSET=1
    fi
  else
    OFFSET=1
  fi


    curl -q -s -X POST ${TGURLUPDATES} -F offset=$((${OFFSET}+1)) -o ${UPDATES}
    NMSGS=$(cat ${UPDATES}  | jq -c '.result|.[]' | wc -l)  

    echo Numero de mensajes: ${NMSGS}

  if [ ${NMSGS} -gt 0 ] ; then
    echo Procesando Mensajes
    for mensaje in `cat ${UPDATES} | jq -cr '.result|.[]| @base64'`; do 
      update_id=`echo $mensaje | tr -d '"' | base64 --decode | jq -rc '.update_id'`
      chat_id=$(echo $mensaje | tr -d '"' | base64 --decode | jq -rc '.message.chat.id')
      ARCHIVO=${TMPDIR}/telegramBot_${chat_id}_${update_id}.msg
      echo $mensaje  | base64 --decode | jq -r '.' > ${ARCHIVO}
      ${BASEDIR}/procesa_mensaje.sh ${ARCHIVO}
      #rm -- ${ARCHIVO}
      echo ${update_id} > ${OFFSETF}
    done
  fi
  sleep 5

done