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

OPERATION=''

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "$0" [operation] [...files]

  echo -e "
    operation:
      --taxes || -t
      --extrato || -e  #lista do formato de extrato
      (default) #lista de transações
  "

  exit
fi


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

function printTaxes {
  FILE=$1
  NOTA=$(pdftotext  -layout $FILE -)

  noteNumber=$(echo "${NOTA}"|sed '3q;d'|awk '{print $1}')
  noteDate=$(echo "${NOTA}"|sed '3q;d'|awk '{print $NF}')

  noteMonth=$(echo "${noteDate}"|cut -d '/' -f 2 )
  noteYear=$(echo "${noteDate}"|cut -d '/' -f 3 )

  txLiq=$(echo "${NOTA}"|grep -o -P '(?<=Taxa de liquidação).*'| awk '{print $1}')
  txEmol=$(echo "${NOTA}"|grep -o -P '(?<=Emolumentos).*'| awk '{print $1}')
  txIR=$(echo "${NOTA}" | grep -o -P '(?<=I.R.R.F. s/ operações, base).*'|xargs| awk '{print $2}')

  if [[ "$txLiq" != "0,00" ]] ; then echo "${noteNumber}; ${noteDate}; ${noteMonth}; ${noteYear}; Liquidação ; ${txLiq}"; fi
  if [[ "$txEmol" != "0,00" ]] ; then echo "${noteNumber}; ${noteDate}; ${noteMonth}; ${noteYear}; Emolumentos ; ${txEmol}"; fi
  if [[ "$txIR" != "0,00" ]] ; then echo "${noteNumber}; ${noteDate}; ${noteMonth}; ${noteYear}; IRRF ; ${txIR}"; fi
}

function extratoList {
  FILE=$1
  NOTA=$(pdftotext  -layout $FILE -)

  noteNumber=$(echo "${NOTA}"|sed '3q;d'|awk '{print $1}')
  noteDate=$(echo "${NOTA}"|sed '3q;d'|awk '{print $NF}')

  noteMonth=$(echo "${noteDate}"|cut -d '/' -f 2 )
  noteYear=$(echo "${noteDate}"|cut -d '/' -f 3 )

  TRANSACTIONS=$(echo "${NOTA}"| egrep "1-BOVESPA")
  while IFS= read -r line ; do

    rType=$(echo "$line"|grep -Eo ' [CV]{1} '| xargs)
    if [[ "$rType" == "V"* ]]; then signal="-"; else signal=""; fi

    rCompany=$(echo "${line:70:60}"|xargs)
    rCompany=$(companyEventSeparation "$rCompany")
    rObs=$(echo "${line:130:20}"|xargs)

    d="${line}"

    rQuant=$signal$(echo "$d"| awk '{print $(NF - 3)}')
    rPrice=$(echo "$d"| awk '{print $(NF - 2)}')
    rValue=$signal$(echo "$d"| awk '{print $(NF - 1)}')
    # rOpera=$(echo "$d"| awk '{print $(NF - 0)}')

    echo "${noteDate}; 18:00:00; ${noteMonth}; ${noteYear}; ${rType}; ;${rCompany}; ${rQuant}; ${rPrice}; ${rValue}; Swing Trade; Nota; Executada"
  done < <(printf '%s\n' "$TRANSACTIONS")

}

function noteList {
  FILE=$1
  NOTA=$(pdftotext  -layout $FILE -)

  noteNumber=$(echo "${NOTA}"|sed '3q;d'|awk '{print $1}')
  noteDate=$(echo "${NOTA}"|sed '3q;d'|awk '{print $NF}')

  noteMonth=$(echo "${noteDate}"|cut -d '/' -f 2 )
  noteYear=$(echo "${noteDate}"|cut -d '/' -f 3 )

  TRANSACTIONS=$(echo "${NOTA}"| egrep "1-BOVESPA")
  while IFS= read -r line ; do

    rType=$(echo "$line"|grep -Eo ' [CV]{1} '| xargs)
    if [[ "$rType" == "V"* ]]; then signal="-"; else signal=""; fi

    rCompany=$(echo "${line:70:60}"|xargs)
    rCompany=$(companyEventSeparation "$rCompany")
    rObs=$(echo "${line:130:20}"|xargs)

    d="${line}"

    rQuant=$signal$(echo "$d"| awk '{print $(NF - 3)}')
    rPrice=$(echo "$d"| awk '{print $(NF - 2)}')
    rValue=$signal$(echo "$d"| awk '{print $(NF - 1)}')
    # rOpera=$(echo "$d"| awk '{print $(NF - 0)}')

    echo "${noteNumber}; ${noteDate}; ${noteMonth}; ${noteYear}; ${rType}; ${rCompany}; ${rObs}; ${rQuant}; ${rPrice}; ${rValue}"
  done < <(printf '%s\n' "$TRANSACTIONS")

}

# --------------------------------------------------

if [[ "$1" == "--taxes" || "$1" == "-t" ]]; then
  shift
  echo "Nota; Data; Mês; Ano; Taxa; Valor"
  for f in $@ ; do
    printTaxes $f
  done
  exit
fi

# --------------------------------------------------
if [[ "$1" == "--extrato" || "$1" == "-e" ]] ; then
  shift
  echo "Data; Hora; Mês; Ano; Tipo; Ticket; Companhia; Eventos; Qty; Valor; Total; Modulo; Orig; Status"
  for f in $@ ; do
    extratoList $f
  done
fi

# --------------------------------------------------
echo "Nota; Data; Mês; Ano; Tipo; Companhia; Eventos; Obs; Quantidade; ValUnitario; Total"
for f in $@ ; do
  noteList $f
done
