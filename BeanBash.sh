#!/bin/bash
if [ "$UID" -ne 0 ]; then
  echo "Se requieren permisos de administrador para ejecutar el script."
  exec sudo "$0" "$@"
fi

red=$(ifconfig | head -n 1 | cut -d":" -f 1)

### FUNCIONES ###
prov() {
  IP=$(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2)
  DOMAIN=$(nslookup $IP | grep name | cut -d"=" -f2)
  ping -c 1 $IP >/dev/null 2>&1
  if [[ $? = 0 ]]; then
    echo -e "El bloqueo está \e[1m\e[31mdesactivado\e[0m. El sistema puede ser monitorizado"
  else
    route | grep -qE "^$IP.+!"
    if [[ $? = 0 ]]; then
      echo -e "El bloqueo está \e[1m\e[32mactivado\e[0m"
    elif [ 'route | grep -qE "^$DOMAIN.+!"' ]; then
      echo -e "El bloqueo está \e[1m\e[32mactivado\e[0m"
    else
      echo "El servicio no aparece como bloqueado pero no se recibe respuesta del servidor"
      echo -e "\e[1m\e[33mNo se puede determinar si el servidor está bloqueado o hay un error de red\e[0m"
    fi
  fi
  crontab -lu root | grep -qE "#autobean$"
  if [[ $? = 0 ]]; then
    echo -e "El bloqueo automático está \e[1m\e[32mactivado\e[0m"
  else
    echo -e "El bloqueo automático está \e[1m\e[31mdesactivado\e[0m"
  fi
}
menu1() {
    echo "Introduce una opción: "
    echo "1) Información/Configurar Epoptes"
    echo "2) Información del sistema"
    echo "3) Instalar BeanBash en el sistema"
    echo "4) Salir"
read opc
}
### FIN FUNCIONES ###
a=0
while [ $a = 0 ]; do
menu1
    case $opc in
        1) 
        clear
        if [ ! -d /etc/default/epoptes-client ]; then 
            prov
            echo
            while true; do
                PS3='Elige una opción: '
                options=("Bloquear epoptes" "Automatizar bloqueo al iniciar sesión" "Activar epoptes" "Eliminar automatización de bloqueo" "Comprobación de estado" "Salir")
                select opt in "${options[@]}"; do
                    case $opt in
                    "Bloquear epoptes")
                    echo "Bloqueando IP del servidor"
                    route add -host $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
                    clear
                    break
                    ;;
                    "Automatizar bloqueo al iniciar sesión")
                    clear
                    IP=$(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2)
                    crontab -l 2>&1 | grep -qi "#autobean"
                    if [ $? != 0 ]; then
                        echo "Añadiendo regla cron al usuario root"
                        (
                        crontab -l
                        echo "@reboot /sbin/route add -host $IP reject #autobean"
                        ) | grep -v "no crontab" | sort | uniq | crontab -
                    else
                        echo "La regla ya se encuentra en el cron"
                    fi
                    break
                    ;;
                    "Activar epoptes")
                    echo "Desbloqueando IP del servidor"
                    route del $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
                    clear
                    break
                    ;;
                    "Eliminar automatización de bloqueo")
                    clear
                    crontab -l 2>&1 | grep -qi "#autobean"
                    if [ $? = 0 ]; then
                        crontab -l | grep -v "#autobean" | crontab -
                    else
                        echo "No se ha encontrado la regla en el cron"
                    fi
                    break
                    ;;
                    "Comprobación de estado")
                    clear
                    prov
                    echo
                    break
                    ;;
                    "Salir")
                    echo "¡Adiós!"
                    break 2
                    ;;
                    *)
                    clear
                    echo "Opción invalida $REPLY"
                    break
                    ;;
                    esac
                done
            done
            a=0
        else 
            echo "Epoptes No esta instalado"
        fi
        ;;

        2) clear
          echo "Información del equipo"
          echo "-El nombre de tu equipo es: $HOSTNAME"
          
          ping 8.8.8.8 -c2 > /dev/null 2>&1
          if [ $? -eq 0 ]; then 
            echo -e "\e[1m\e[32mTienes conexion a internet\e[0m" 
            echo -n " -Tu IP es: "; hostname -I
            echo -n " -Tu IP Publica es: "; dig +short myip.opendns.com @resolver1.opendns.com
            echo -n " -Tu dirección DNS es: "; nmcli dev show | grep DNS | cut -d":" -f2 |tr -d '[[:space:]]'; echo 
            echo -n " -Tu gateway es: "; ip r | grep default | cut -d" " -f 3
            echo -n " -Tu dirección MAC es: "; ip a s dev eno1 | grep ether |  tr " \t" "\n" | tr -s "\n" | tail -n 3 | head -n 1
          else 
            echo -e "\e[1m\e[31mNo tienes conexión a internet \e[0m"
          fi
          echo
          a=0
        ;;
        3)
            clear
            INSTALL=$(echo $PATH | cut -d: -f1)
            cp $0 $INSTALL/bean
            echo "Ahora puedes ejecutar el comando \"bean\" en el sistema"
            break
            ;;
        4)
        echo "Adiós!" 
            a=1
        ;;
        *) clear
        echo -e "\e[1m\e[31mOpción invalida \e[0m"
            a=0
        ;;
    esac
done
