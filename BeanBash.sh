#!/bin/bash
## TODO
## Hacer una opción help
## Ordenar el código
## Crear opciones fáciles para: activar bloqueo, desactivar bloqueo, info de red
## Revisar la función prov
## Terminar net menu
if [ "$UID" -ne 0 ]; then
  echo "Se requieren permisos de administrador para ejecutar el script."
  exec sudo "$0" "$@"
fi
## FUNCIONES ##
dpkg_test(){
  TEST="neofetch macchanger net-tools dnsutils iproute2 nmap"
CONT=0
for PACKAGE in $TEST
do
  dpkg-query -s $PACKAGE > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    TOINSTALL="$TOINSTALL $PACKAGE"
    CONT=1
    fi
done
if [[ $CONT -eq 1 ]]; then
  echo "Las dependencias $TOINSTALL deben instalarse para que bean funcione correctamente."
  while true; do
    read -p "¿Desea instalarlas automáticamente? (Y/n) " yn
    case $yn in
        [Yy]* ) apt update && apt install $TOINSTALL -y; break 1;;
        [Nn]* ) echo "No puede usarse bean correctamente sin las dependencias"; exit 1;;
        "" ) apt install $TOINSTALL -y; break 1;;
        * ) echo "Por favor, indica sí (y) o no(n).";;
    esac
done
fi
}
usage() {
  echo "Uso: $(basename $0) [-aAbBiqsh]" 2>&1
  echo '   -a   Activa epoptes'
  echo '   -A   Elimina la automatización de epoptes al inicio de la sesión'
  echo '   -b   Bloquea epoptes'
  echo '   -B   Automatiza el bloqueo de epoptes al inicio de la sesión'
  echo '   -i   Instala esta versión de bean en el sistema'
  echo '   -q   Quiet. No muestra el estado del bloqueo antes de mostrar el menú'
  echo '   -s   Muestra el estado del bloqueo'
  echo '   -h   Muestra este mensaje de ayuda'
}
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
epoptes_unblock() {
  route del $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
}
auto_unblock() {
  crontab -l 2>&1 | grep -qi "#autobean"
  if [ $? = 0 ]; then
    crontab -l | grep -v "#autobean" | crontab -
  else
    echo "No se ha encontrado la regla en el cron"
  fi
}
epoptes_block() {
  route add -host $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
}
auto_bock() {
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
}
system_info() {
  echo "Información del equipo"
  echo "-El nombre de tu equipo es: $HOSTNAME"

  ping 8.8.8.8 -c2 >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "\e[1m\e[32mTienes conexion a internet\e[0m"
    echo -n " -Tu IP es: "
    hostname -I
    echo -n " -Tu IP Publica es: "
    dig +short myip.opendns.com @resolver1.opendns.com
    echo -n " -Tu dirección DNS es: "
    nmcli dev show | grep DNS | cut -d":" -f2 | tr -d '[[:space:]]'
    echo
    echo -n " -Tu gateway es: "
    ip r | grep default | cut -d" " -f 3
    echo -n " -Tu dirección MAC es: "
    ip a s dev eno1 | grep ether | tr " \t" "\n" | tr -s "\n" | tail -n 3 | head -n 1
  else
    echo -e "\e[1m\e[31mNo tienes conexión a internet \e[0m"
  fi
}
epoptes_menu() {
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
}
net_menu() {
  while true; do
    PS3='Elige una opción: '
    options=("Actualizar tabla ARP" "Cambiar MAC por la de un equipo de la red"
      "Cambiar MAC por una distinta" "Recuperar MAC original" "Salir")
    select opt in "${options[@]}"; do
      case $opt in
      "Actualizar tabla ARP")
        ADDRESS=$(ip -p r | grep -E "^.+\..+\..+\..+/.+ " | cut -d" " -f1 | grep -vE "^169.254.")
        nmap -PR -sP $ADDRESS >/dev/null 2>&1
        arp -e
        break
        ;;
      "Cambiar MAC por la de un equipo de la red")
        ADDRESS=$(ip -p r | grep -E "^.+\..+\..+\..+/.+ " | cut -d" " -f1 | grep -vE "^169.254.")
        nmap -PR -sP $ADDRESS >/dev/null 2>&1
        i=1
        for line in $(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | tr '\n' ' '); do
          echo "$i) $line"
          ((i++))
        done
        read -rp "Selecciona una tarjeta de red: " NUM
        CARD=$(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | sed $NUM'!d')
        i=1
        IFS=$'\n'
        for line in $(arp -a | cut -d" " -f2,4); do
          echo "$i) $line"
          ((i++))
          done
          read -rp "Selecciona una MAC para clonar: " NUM
          MAC=$(arp -a | cut -d" " -f2,4 | sed $NUM'!d' | cut -d" " -f2)
          macchanger -r $CARD --mac="$MAC" 
        break
        ;;
      "Cambiar MAC por una distinta")
        i=1
        for line in $(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | tr '\n' ' '); do
          echo "$i) $line"
          ((i++))
        done
        read -rp "Selecciona una tarjeta de red: " NUM
        CARD=$(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | sed $NUM'!d')
        macchanger -rA $CARD
        dhclient -v $CARD
        break
        ;;
      "Recuperar MAC original")
        i=1
        for line in $(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | tr '\n' ' '); do
          echo "$i) $line"
          ((i++))
        done
        read -rp "Selecciona una tarjeta de red: " NUM
        CARD=$(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | sed $NUM'!d')
        macchanger -p $CARD
        dhclient -v $CARD
        break
        ;;
      "Salir") break 2 ;;
      esac
    done
  done
}
installer() {
  dpkg_test
  local INSTALL=$(echo $PATH | cut -d: -f1)
  cp -r $0 $INSTALL/bean
}
## FIN FUNCIONES ##
dpkg_test
if [[ $# -ne 0 ]]; then

  while getopts "aAbBisqh" arg; do
    case "$arg" in
    a)
      epoptes_unblock
      exit
      ;;
    A)
      auto_unblock
      exit
      ;;
    b)
      epoptes_block
      exit
      ;;
    B)
      auto_bock
      exit
      ;;
    i)
      installer
      exit
      ;;
    s)
      prov
      exit
      ;;
    h)
      usage
      exit
      ;;
    q) break;;
    ?)
      usage
      exit 1
      ;;
    esac
  done

fi
if [[ $(echo $@ | grep "q") -ne 0 ]]; then
  prov
fi
while true; do
  PS3='Selecciona una opción: '
  options=("Información del sistema" "Configurar epoptes" "Configurar red" "Instalar BeanBash en el sistema" "Salir")
  select opt in "${options[@]}"; do
    case $opt in
    "Información del sistema")
      system_info
      break
      ;;
    "Configurar epoptes")
      epoptes_menu
      break
      ;;
    "Configurar red")
      net_menu
      break
      ;;
    "Instalar BeanBash en el sistema")
      installer
      break
      ;;
    "Salir")
      echo "salir"
      break 2
      ;;
    *) ;;

    esac
  done
done
