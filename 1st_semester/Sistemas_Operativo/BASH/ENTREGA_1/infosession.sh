#!/bin/bash
#Necesito procesar los elementos de la linea de comandos para que note el -h o lo que chigados quiera

show_sid=0
show_help=0

while [ -n "$1" ]; do
  case $1 in
    -h)
      show_help
      exit 0
      ;;
    -z)
      show_sid=1
      ;;
    -u)
      #user=$2
      #shift

      #ó

      shift
      if [[ $1 == -* ]]; then
        echo "Te falta poner algo depués del -u tontin"
        exit 1                          # Comprobar que user tiene algo
      fi                                # Hay que hacer un bucle para cuando tengamos más de 1 user, mirarlo ;)
      user=$1
      ;;
    *)
      echo "Error, intentalo hacerlo mejor la próxima vez..."
      show_help
      exit 1
      ;;
  esac
  shift                                 # $2 se dezplaza a $1, por lo que este se pierde y podemos revisar con "$2" :0
done

show_help() {
  echo "Uso: infosession.sh [-h] [-z] [-u user]"
  echo "Opciones:"
  echo "  -h        Muestra esta ayuda y termina."
  echo "  -z        Incluye procesos con SID igual a 0."
  echo "  -u user   Filtra los procesos para el usuario especificado."
  exit 0
}

get_processes() {
    ps -ax -o sid,pgid,pid,user,tty,%mem,cmd | tail -n +2
}

filter_sid() {
    if [ $show_sid -eq 0 ]; then
        awk '$1 != 0'
    else
        cat
    fi
}

filter_user() {
    if [ -n "$user" ]; then
        awk -v user="$user" '$4 == user'
    else
        cat
    fifunction get_processes {
  ps -eo sid,pgid,pid,euser,tty,%mem,cmd | awk -v show_sid="$show_sid" -v user="$user" '
    BEGIN { OFS="\t"; print "SID", "PGID", "PID", "USER", "TTY", "%MEM", "CMD" }
    $4 == user && (show_sid || $1 != 0) {
      print $1, $2, $3, $4, ($5 == "?" ? "?" : $5), $6, $7
    }
  ' | sort -k4,4
}

# Mostrar los procesos
get_processes
}

processes=$(get_processes | filter_sid | filter_user)

# Mostrar encabezado y resultados finales
echo "SID PGID PID USER TTY %MEM CMD"
echo "$processes"

#processes=$(get_processes)              # If sid = 0, no mostrar

#if [ $show_sid=0 ]; then
#  processes=$(filter_sid "$processes")
#fi

#if [ -n $user ]; then
#  processes=$(filer_user "$processes" "$user")
#fi
