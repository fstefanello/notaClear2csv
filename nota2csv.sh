#!/bin/bash
  CODES=(
  ' ED '
  ' EJ '
  ' EDJ '
  ' EB '
  ' ES '
  ' ER '
  ' EX '
  ' EC '
  ' EG '
  ' ER '
  ' S '
  ' ATZ '
  )

  FII_CODES=( ' CI ')

function companyEventSeparation {
  name="$1 "
  events=""

  for i in "${CODES[@]}"; do
    if [[ "$name" == *"$i"* ]]; then
      events="$events $i"
    fi
    name=${name//$i/ }
  done

  for i in "${FII_CODES[@]}"; do
    name=${name//$i/ }
  done

  name=$(echo "$name"|xargs)
  events=$(echo "$events"|xargs)

  echo "$name; $events"
}


function extractFromFile {
  FILE=$1
  NOTA=$(pdftotext  -layout $FILE -)

  noteNumber=$(echo "${NOTA}"|sed '3q;d'|awk '{print $1}')
  noteDate=$(echo "${NOTA}"|sed '3q;d'|awk '{print $3}')

  # echo "$NOTA"
  TRANSACTIONS=$(echo "${NOTA}"| egrep "1-BOVESPA")
  while IFS= read -r line ; do
    # echo "$line"

    rType=$(echo "$line"|grep -Eo ' [CV]{1} '| xargs)
    if [[ "$rType" == "V"* ]]; then signal="-"; else signal=""; fi

    rCompany=$(echo "${line:70:60}"|xargs)
    # companyEventSeparation "$rCompany"
    rCompany=$(companyEventSeparation "$rCompany")
    rObs=$(echo "${line:130:20}"|xargs)

    d="${line}"

    rQuant=$signal$(echo "$d"| awk '{print $(NF - 3)}')
    rPrice=$(echo "$d"| awk '{print $(NF - 2)}')
    rValue=$signal$(echo "$d"| awk '{print $(NF - 1)}')
    # rOpera=$(echo "$d"| awk '{print $(NF - 0)}')

    echo "${noteNumber}; ${noteDate}; ${rType}; ${rCompany}; ${rObs}; ${rQuant}; ${rPrice}; ${rValue}"
  done < <(printf '%s\n' "$TRANSACTIONS")

}

echo "Nota; Data; Tipo; Companhia; Eventos; Obs; Quantidade; ValUnitario; Total"
for f in $@ ; do
  extractFromFile $f
done