#!/bin/bash

show_sid=0
show_dir=0
show_user=0
show_advertencia=0
show_terminal=0
show_tabla=0

user=()
dir=""
file=""

# Funcion de ayuda por si pasa algo malo
show_help() {
  echo "Uso: $0 [-h] [-z] [-u user1 user2 ... ] [-d dir] [-w] [-t] [-f file]"
  echo "Opciones:"
  echo "  -h              Muestra esta ayuda."
  echo "  -z              Incluye procesos con SID igual a 0."
  echo "  -u user1 ...    Especifica un usuario cuyos procesos se listarán."
  echo "  -d dir          Muestra los procesos de forma ordenada dentro de ese directorio."
  echo "  -w              Muestra advertencia si hay más de 5 procesos."
  echo "  -t              Muestra los procesos con una terminal controlada asociada"
}

# Procesar los argumentos de línea de comandos
while [ -n "$1" ]; do
  case $1 in
    -h)
      show_help
      exit 0
      ;;
    -z)
      show_sid=1
      shift 
      ;;
    -u)
      shift
      if [[ -z "$1" || "$1" == -* ]]; then
        echo "Entregable 2 (con modificación) de Dylan Gonzalo Campo Bedoya: "
        echo "Error: Se requiere un nombre de usuario después de -u."
        show_help
        exit 1
      fi

      while [[ -n "$1" && "$1" != -* ]]; do  # Acepta múltiples usuarios después de -u
        user+=("$1")
        shift
      done
      show_user=1                               
      ;;
    -t)
      show_terminal=1
      shift 
      ;;
    -d)
      shift
      if [[ -z "$1" || "$1" == -* ]]; then
        echo "Entregable 2 (con modificación) de Dylan Gonzalo Campo Bedoya: "
        echo "Error: Se requiere una ruta de directorio después de -d."
        show_help
        exit 1
      fi
      dir=$1
      show_dir=1
      shift 
      ;;
    -e)
      show_tabla=1
      ;;
    -f)
      shift
      if [[ -z "$1" || "$1" == -* ]]; then
        echo "Entregable 2 (con modificación) de Dylan Gonzalo Campo Bedoya: "
        echo "Error: Se requiere un file después de -f."
        show_help
        exit 1
      fi
      file=$1
      show_file=1
      shift
      ;;
    *)
      echo "Entregable 2 (con modificación) de Dylan Gonzalo Campo Bedoya: "
      echo "Error: Opción no reconocida"
      show_help
      exit 1
      ;;
  esac                                
done

# Funcion baase que nos muestra los procesos por pantalla
get_processes() {
  ps -e -o sid:8,pgid:8,pid:8,euser:10,tty:8,%mem:8,cmd --sort=sid | \
  awk '{ printf "%-8s %-8s %-8s %-10s %-8s %-8s %-s\n", $1, $2, $3, $4, $5, $6, $7 }'       # Para mostrar todos los procesos
}

# Funcion que muestra por pantalla los sid = 0 cuando el usuario ponga [-z]
filter_sid() {
  if [ $show_sid -eq 0 ]; then
    awk '$1 != 0'
  else
    cat
  fi
}

# Funcion que filtra los procesos por usuarios pedidos con la opcion [-u user1 user2 ...]
filter_user() {
  if [ -n "$user" ]; then
    printf "%-8s %-8s %-8s %-10s %-8s %-8s %-s\n" "SID" "PGID" "PID" "USER" "TTY" "%MEM" "COMMAND"
    awk -v users="${user[*]}" 'BEGIN {
        split(users, user_arr)
        for (i in user_arr) user_map[user_arr[i]] = 1
      }
      $4 in user_map  # Filtra por usuario en user_map'
  else
    cat
  fi
}

# Funcion que filtra los procesos por directorio con la opcion [-d dir]
filter_dir() {
  if [ $show_dir -eq 1 ]; then
    lsof +d "$dir" | awk '{print $2}'
  else
    cat
  fi
}

# Funcion que muestra los procesos con una terminal asociada con la opcion [-t]
filter_terminal() {
  if [ $show_terminal -eq 1 ]; then
    printf "%-8s %-8s %-8s %-10s %-8s %-8s %-s\n" "SID" "PGID" "PID" "USER" "TTY" "%MEM" "COMMAND"
    awk '$5 == "?"'
  else
    cat
  fi
}

filter_file() {
  if [ $show_file -eq 1 ]; then
    processes_count_file=$(echo "$processes" | wc -l)
    if [ "$processes_count_file" -gt 5 ]; then
      cat "$file"
    fi
  else
    cat
  fi
}

# Funcion que muestra lo anterior de forma normalita [-e]
# funcion_e() {
#   if [ $show_tabla -eq 1 ]; then
#     
#   else
#     processes=$(get_processes | filter_sid | filter_terminal | filter_user | filter_dir )
#     echo "$proceses"
#   fi
# }       EN DESARROLLO


# ------------------------------------------------- (MODI1) -------------------------------------------------
# Bucle para contar los procesos y soltar una advertencia si son mayores que cinco con la opcion [-w]
# if [ $show_advertencia -eq 1 ]; then
#   process_count=$(echo "$processes" | wc -l)
#   if [ "$process_count" -gt 5 ]; then
#     echo "Entregable 2 (con modificación) de Dylan Gonzalo Campo Bedoya: "
#     echo "Advertencia: Hay más de 5 procesos."
#     exit 0
#   fi
# fi

# -w)
#       show_advertencia=1
#       shift 
#       ;;
# ------------------------------------------------- ------- -------------------------------------------------

# Obtiene los procesos y aplica los filtros existentes
processes=$(get_processes | filter_sid | filter_terminal | filter_user | filter_dir | filter_file)
# Mostrar encabezado y resultados finales
echo "Entregable 2 (con modificación) de Dylan Gonzalo Campo Bedoya: "
echo "$processes"
# funcion_e





# ------------------------------------------------- (HACER) -------------------------------------------------

# Hacer el -e:
#       Solo si se pone el -e se pondrá toda la wea anterior
#       Sin el -e se verá:
# Para cada sesion, sumar los valores de memoria
# El proceso lider lo encontrare gracias al PID, que debe tener el mismo SID
# Mostrar los SID que hay, pero no repetidos, creo
# Poner el user, tty y cmd del proceso LIDER
# Acá hay otro, mirar bien la plantilla que la explica mejor

#   -sm    Ordena por el porcentaje de memoria
#           Se puede hacer desde ps, o tmb con el sort -g (Para ordenar numeros)
#   -sg    Ordenamiento de la tabla resumen (incompatible con -e)
#           Otro sort -g, pero solo con la tabla
#   -r    Invierte cualquier ordenamiento
#           sort -

# No poner espacios en el nombre del archivo al entregarlo
# La opcion -d deberia devolver la lista de PIDS de lsof +d 
#            y luego usar los PIDS para coger los procesos como un criterio más con -u
