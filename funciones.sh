function filtra {
  texto=$1
  resultado=`echo "${texto}" \
    | sed 's/u00e1/a/g' \
    | sed 's/u00c1/A/g' \
    | sed 's/u00e9/e/g' \
    | sed 's/u00c9/E/g' \
    | sed 's/u00ed/i/g' \
    | sed 's/u00cd/I/g' \
    | sed 's/u00f3/o/g' \
    | sed 's/u00d3/O/g' \
    | sed 's/u00fa/u/g' \
    | sed 's/u00da/U/g' \
    | sed 's/u00f1/n/g' \
    | sed 's/u00d1/N/g' \
    | sed 's/ñ/n/g' \
    | sed 's/Ñ/N/g' \
    | sed 's/á/a/g' \
    | sed 's/é/e/g' \
    | sed 's/í/i/g' \
    | sed 's/ó/o/g' \
    | sed 's/ú/u/g' \
    | sed 's/ü/u/g' \
    | sed 's/Á/A/g' \
    | sed 's/É/E/g' \
    | sed 's/Í/I/g' \
    | sed 's/Ó/O/g' \
    | sed 's/Ú/U/g' \
    | sed 's/Ü/U/g' \
    | tr -d '"*?'
  `
  echo ${resultado}
}

function campo {
  echo $(cat -- ${MENSAJE} | jq -rc .${1})
}