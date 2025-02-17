#!/bin/bash 

. `dirname $0`/bot.config
source ${BASEDIR}/funciones.sh
MESSAGE="message"
MENSAJE=$1
#cat ${MENSAJE} | jq .

edited=$(campo edited_message.message_id)
if [ "${edited}" != "null" ] ; then
  MESSAGE="edited_message"
fi
echo $(date -d @$(campo ${MESSAGE}.date)) $(campo update_id) $(campo ${MESSAGE}.from.first_name) $(campo ${MESSAGE}.text)

file_id=$(campo ${MESSAGE}.voice.file_id)

if [ ${file_id} == "null" ]; then 
  # No es un audio
  rm -- "${MENSAJE}"
  exit 1
fi

#echo Es un audio

chat_id=$(campo ${MESSAGE}.chat.id) 
from_id=$(campo ${MESSAGE}.from.id)
from_user=$(campo ${MESSAGE}.from.username)

DATOS=$(grep ^"${chat_id}~${from_id}~${from_user}" -- "${BASEDIR}/podcasts.conf")

if [ -z "${DATOS}" ] ; then 
    # No es el autor que buscamos
    rm -- "${MENSAJE}"
    exit 1
fi

titulo=$(echo "'${DATOS}'" | cut -d '~' -f 4 )
rss=$(echo "'${DATOS}'" | cut -d '~' -f 5 )
imagen=$(echo "'${DATOS}'" | cut -d '~' -f 6 )
urlbase=$(echo "'${DATOS}'" | cut -d '~' -f 7 )
update_id=$(campo update_id)

file_duration=$(campo ${MESSAGE}.voice.duration)
file_type=$(campo ${MESSAGE}.voice.mime_type)
file_unique_id=$(campo ${MESSAGE}.voice.file_unique_id)
file_size=$(campo ${MESSAGE}.voice.file_size)

message_id=$(campo ${MESSAGE}.message_id)

caption=$(campo ${MESSAGE}.caption)
date=$(campo ${MESSAGE}.date)

update_id=$(campo update_id)

#echo " Titulo ${titulo} ${rss}
# chat_id ${chat_id} 
# from ID: ${from_id} User: ${from_user} 
# FileID:${file_id} 
# Duracion:${file_duration} Tipo:${file_type} Unique:${file_unique_id} Tamaño:${file_size}
# Titulo:${caption}
# Fecha:${date}
# Imagen: ${imagen}
#"

#echo Descargo audio

# Guardo en una variable el chat_id sin el menos de los grupos
#chat_id2=$(echo "${chat_id}" | tr -d '-')
baseLink=${chat_id:4}
chat_id2=${chat_id:1}

mp3="$(dirname ${rss})/${file_unique_id}.mp3"
#json="$(dirname ${rss})/${file_unique_id}.json"

if [ ! -f "${mp3}" ] ; then
    echo no existe el mp3 ${mp3}, lo descargo y lo convierto
    file_path=$(curl -s "${TGURLFILE}?file_id=${file_id}" | jq -rc .result.file_path)
    if [ -z "${file_path}" ] ; then
        echo No puedo obtener el filepath
        exit 1
    fi
    oggOut="${TMPDIR}/${file_unique_id}-${RANDOM}.oga"
    
    curl -s "https://api.telegram.org/file/bot${TOKEN}/${file_path}" -o "${oggOut}"
    if [ ! -f "${oggOut}" ]; then
        echo Error descargando el archivo de telegram
        exit 1
    fi
    #Convierto el ogg a mp3
    ffmpeg -i "${oggOut}" "${mp3}"
    rm -- "${oggOut}"
    if [ ! -f "${mp3}" ] ; then
        echo Error generando el archivo ${mp3}
        exit 1
    fi
fi

unset LANG

#echo Genero la cabecera del podcast
cat <<EOF > "$(dirname ${rss})/header"
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
  <channel>
    <title>${titulo}</title>
    <link>https://t.me/c/${baseLink}</link>
    <description></description>
    <language>es</language>
    <pubDate>$(date --rfc-email)</pubDate>
    <itunes:owner>
      <itunes:email>sciguppd@grr.la</itunes:email>
      <itunes:name>${titulo}</itunes:name>
    </itunes:owner>
    <itunes:category text="Voice" />
    <itunes:image href="${imagen}" />
    <itunes:explicit>no</itunes:explicit>
    <itunes:keywords />
    <itunes:summary></itunes:summary>
    <image>
      <title>${titulo}</title>
      <url>${imagen}</url>
      <link>https://t.me/c/${baseLink}</link>
    </image>
EOF

#echo Genero el item
cat <<EOF > "$(dirname ${rss})/${chat_id2}_${message_id}.item"
    <item>
      <title>${caption} $(date -d @${date} +%Y/%m/%d)</title>
      <link>https://t.me/c/${baseLink}/${message_id}</link>
      <description>${caption}</description>
      <enclosure url="${urlbase}/$(basename ${mp3})" length="${file_duration}" type="audio/mpeg" />
      <pubDate>$(date --rfc-email -d @${date})</pubDate>
      <itunes:duration>${file_duration}</itunes:duration>
      <itunes:explicit>no</itunes:explicit>
      <guid>https://t.me/c/${baseLink}/${message_id}</guid>
    </item>
EOF

#echo Genero el pie
cat <<EOF > "$(dirname ${rss})/footer"
  </channel>
</rss>
EOF

echo Genero el rss concatenando archivos
cat  "$(dirname ${rss})/header" $(ls -r "$(dirname ${rss})"/*.item ) "$(dirname ${rss})/footer" > "${rss}"
