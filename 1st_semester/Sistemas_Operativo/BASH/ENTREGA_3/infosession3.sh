#!/bin/bash

show_sid=0
show_dir=0
show_user=0
show_advertencia=0
show_terminal=0
show_tabla=0
show_sm=0
show_sg=0
show_reverse=0

user=()
dir=""

# Funcion de ayuda por si pasa algo malo
show_help() {
  echo "Uso: $0 [-h] [-z] [-u user1 user2 ...] [-d dir] [-w] [-t] [-f file] [-e] [-sm] [-sg] [-r]" 
  echo ""
  echo "Opciones:"
  echo "  -h              Muestra esta ayuda."
  echo "  -z              Incluye procesos con SID igual a 0."
  echo "  -u user1 ...    Especifica un usuario cuyos procesos se listarán."
  echo "  -d dir          Muestra los procesos de forma ordenada dentro de ese directorio."
  echo "  -w              Muestra advertencia si hay más de 5 procesos."
  echo "  -t              Muestra los procesos con una terminal controlada asociada."
  echo "  -e              Cambia la tabla resumen por todos los procesos ejecuntados en ese momento."
  echo "  -sm             Órdena por porcentaje de memoria."
  echo "  -sg             Órdena la tabla resumen."
  echo "  -r              Invierte el órden."
  echo ""
  echo "No intentar colocar la opción -r y -sg a la vez porque produce error"
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
        echo "Entregable 3 (con modificación) de Dylan Gonzalo Campo Bedoya: "
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
        echo "Entregable 3 (con modificación) de Dylan Gonzalo Campo Bedoya: "
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
      shift
      ;;
    -sm)
      show_sm=1
      shift
      ;;
    -sg)
      show_sg=1
      shift
      ;;
    -r)
      show_reverse=1
      shift
      ;;
    *)
      echo "Entregable 3 (con modificación) de Dylan Gonzalo Campo Bedoya: "
      echo "Error: Opción no reconocida"
      show_help
      exit 1
      ;;
  esac                                
done

#Comprobación de que no junte opciones incompatibles
if [ $show_tabla -eq 1 ] && [ $show_sg -eq 1 ]; then
  echo "La opcion -sg es incompatible con la opcion -e"
  show_help
  exit 0
fi

if [ $show_sm -eq 1 ] && [ $show_sg -eq 1 ]; then
  echo "La opcion -sg es incompatible con la opcion -e"
  show_help
  exit 0
fi


# Funcion baase que nos muestra los procesos por pantalla
get_processes() {
  ps -e -o sid,pgid,pid,euser,tty,%mem,cmd | sort -k4 | \
  awk '{ printf "%-8s %-8s %-8s %-10s %-8s %-8s %-s\n", $1, $2, $3, $4, $5, $6, $7 }' 
}

filter_user() {
  if [ -n "$user" ]; then
    printf "%-8s %-8s %-8s %-10s %-8s %-8s %-s\n" "SID" "PGID" "PID" "USER" "TTY" "%MEM" "COMANDO"
    awk -v users="${user[*]}" '
      BEGIN {
        split(users, user_arr)
        for (i in user_arr) user_map[user_arr[i]] = 1
      }
      $4 in user_map { print }'
  else
    cat
  fi
}

# Funcion que muestra por pantalla los sid = 0 cuando el usuario ponga [-z]
filter_sid() {
  if [ $show_sid -eq 0 ]; then
    awk '$1 != 0'
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
    printf "%-8s %-8s %-8s %-10s %-8s %-8s %-s\n" "SID" "PGID" "PID" "USER" "TTY" "%MEM" "COMANOD"
    awk '$5 != "?"'
  else
    cat
  fi
}

filter_sm() {
  if [ $show_sm -eq 1 ]; then
    sort -k6 -n # Columna del %mem de ambas tablas
  else
    cat
  fi
}

filter_sg() {
  if [ $show_sg -eq 1 ]; then
    sort -k2 -n # Columna del contedor_PID
  else
    cat
  fi
}

filter_reverse() {
  if [ $show_reverse -eq 1 ]; then
    sort -r
  else
    cat
  fi
  
}

#processes=$(get_processes | filter_sid | filter_terminal | filter_user | filter_dir | filter_sm | filter_sg | filter_reverse)
processes=$(get_processes | filter_sid | filter_terminal | filter_dir | filter_sm | filter_terminal | filter_user | filter_reverse)
processes_resumen=$(get_processes | filter_sm | filter_sg | filter_reverse | filter_user | filter_terminal | filter_dir | filter_sid)

# Funcion que muestra lo anterior de forma normalita [-e]
funcion_e() {
  if [ $show_tabla -eq 1 ]; then
    echo "$processes"
  else
    printf "%-8s %-8s %-8s %-8s %-8s %-12s %-10s\n" "SID" "C_PID" "l_PID" "User lider" "Ltty" "%memT" "Comando lider" 

    # Hacer la tabla resumen
    echo "$processes_resumen" | awk '
    BEGIN {
      OFS="\t"
    }
    {
      SID = $1     
      pgid = $2     
      pid = $3     
      user = $4     
      tty = $5      
      mem = $6       
      cmd = $7       

      sessions[SID]["mem"] += mem
      sessions[SID]["c_PID"] += 1
      # Suma el SID en el que esté la memoria y el numero de PIDs

      if (!(SID in sessions) || pid == SID) {
        sessions[SID]["l_PID"] = pid
        sessions[SID]["user"] = user
        sessions[SID]["tty"] = tty
        sessions[SID]["cmd"] = cmd
      } # Cuenta procesos y muestra los lideres

    }
    END {
      for (SID in sessions) {
        l_PID = sessions[SID]["l_PID"]
        total_mem = sessions[SID]["mem"]
        Luser = sessions[SID]["user"]
        Ltty = sessions[SID]["tty"]
        Lcmd = sessions[SID]["cmd"]
        c_PID = sessions[SID]["c_PID"]
        
        
        # Imprimir por pantalla las soluciones del for de antes
        printf "%-8s %-8s %-8s %-10s %-8s %-12s %-s\n", \
          SID, c_PID, l_PID, Luser, Ltty, total_mem, Lcmd
      } 
      # For para mostrar el resultado de cada SID lider con sus correspondientes columnas
    }'
  fi
}

# Mostrar encabezado y resultados finales
echo "Entregable 3 (con modificación) de Dylan Gonzalo Campo Bedoya: "
funcion_e



# ------------------------------------------------- (HACER) -------------------------------------------------

# ERRORES:
# El -r no hace lo que debe
# EL -sm no funciona con la tabla resumen pero si con la otra (ENCABEZADO)
# el -sg no va con la tabla resumen
# Falta arreglar el -d

 
# No poner espacios en el nombre del archivo al entregarlo
# La opcion -d deberia devolver la lista de PIDS de lsof +d 
#            y luego usar los PIDS para coger los procesos como un criterio más con -u
