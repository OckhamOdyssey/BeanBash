#!/bin/bash
if [ "$UID" -ne 0 ]; then
  echo "Se requieren permisos de administrador para ejecutar el script."
  exec sudo "$0" "$@"
fi
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
### FIN FUNCIONES ###
prov
while true; do
  PS3='Elige una opción: '
  options=("Bloquear epoptes" "Automatizar bloqueo al iniciar sesión" "Activar epoptes" "Eliminar automatización de bloqueo" "Comprobación de estado" "Instalar BeanBash en el sistema" "Salir")
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
      break
      ;;
    "Instalar BeanBash en el sistema")
      clear
      INSTALL=$(echo $PATH | cut -d: -f1)
      cp $0 $INSTALL/bean
      echo "Ahora puedes ejecutar el comando \"bean\" en el sistema"
      break
      ;;
    "Salir")
      echo "¡Adiós!"
      break 2
      ;;
    *)
      echo "invalid option $REPLY"
      break
      ;;
    esac
  done
done
