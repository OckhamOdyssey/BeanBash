#!/bin/bash
if [ "$UID" -ne 0 ]; then
	exec sudo "$0" "$@"
fi
## FUNCIONES ##
dpkg_test() {
	TEST="macchanger net-tools dnsutils iproute2 nmap network-manager"
	CONT=0
	for PACKAGE in $TEST; do
		if ! dpkg-query -s "$PACKAGE" >/dev/null 2>&1; then
			TOINSTALL="$TOINSTALL $PACKAGE"
			CONT=1
		fi
	done
	if [[ $CONT -eq 1 ]]; then
		echo "Las dependencias $TOINSTALL deben instalarse para que bean funcione correctamente."
		while true; do
			read -p "¿Desea instalarlas automáticamente? (Y/n) " yn
			case $yn in
			""|[Yy]*) apt update && apt install $TOINSTALL -y; break 1;;
			[Nn]*) echo "No puede usarse bean correctamente sin las dependencias"; exit 1;;
			*) echo "Por favor, indica sí (y) o no(n)." ;;
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
	if ping -c 1 $IP > /dev/null 2>&1; then
		echo -e "El bloqueo está \e[1m\e[31mdesactivado\e[0m. El sistema puede ser monitorizado"
	else
		if route | grep -qE "^$IP.+!"; then
			echo -e "El bloqueo está \e[1m\e[32mactivado\e[0m"
		elif [ 'route | grep -qE "^$DOMAIN.+!"' ]; then
			echo -e "El bloqueo está \e[1m\e[32mactivado\e[0m"
		else
			echo "El servicio no aparece como bloqueado pero no se recibe respuesta del servidor"
			echo -e "\e[1m\e[33mNo se puede determinar si el servidor está bloqueado o hay un error de red\e[0m"
		fi
	fi
	if crontab -lu root | grep -qE "#autobean$"; then
		echo -e "El bloqueo automático está \e[1m\e[32mactivado\e[0m"
	else
		echo -e "El bloqueo automático está \e[1m\e[31mdesactivado\e[0m"
	fi
}
epoptes_unblock() {
	route del $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
}
auto_unblock() {
	if crontab -l 2>&1 | grep -qi "#autobean"; then
		crontab -l | grep -v "#autobean" | crontab -
	else
		echo -e "\e[1m\e[31mError: \e[0mNo se ha encontrado la regla en el cron" >&2
	fi
}
epoptes_block() {
	route add -host $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
}
auto_bock() {
	IP=$(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2)
	if crontab -l 2>&1 | grep -qi "#autobean"; then
		(crontab -l;echo "@reboot /sbin/route add -host $IP reject #autobean") | grep -v "no crontab" | sort | uniq | crontab -
	else
		echo -e "\e[1m\e[31mError: \e[0mLa regla ya se encuentra en el cron" >&2
	fi
}
installer() {
	dpkg_test
	cp -r $0 $(echo $PATH | cut -d: -f1)/bean
}
system_info() {
	echo "Información del equipo"
	echo "-El nombre de tu equipo es: $HOSTNAME"
		echo -n " -Tu IP es: "; hostname -I
	if ping 8.8.8.8 -c2 >/dev/null 2>&1; then
		echo -e "\e[1m\e[32mTienes conexion a internet\e[0m"
	else
		echo -e "\e[1m\e[31mNo tienes conexión a internet \e[0m"
		echo -n " -Tu IP Publica es: "; dig +short myip.opendns.com @resolver1.opendns.com
		echo -n " -Tu servidor DNS es: "; nmcli dev show | grep DNS | cut -d":" -f2 | tr -d '[[:space:]]'
		echo "----"
		echo -n " -Tu gateway es: "; ip r | grep default | cut -d" " -f 3
		echo -n " -Tu dirección MAC es: "; ip a s dev eno1 | grep ether | tr " \t" "\n" | tr -s "\n" | tail -n 3 | head -n 1
	fi
}
epoptes_menu() {
	while true; do
		PS3='Elige una opción: '
		options=("Bloquear epoptes" "Automatizar bloqueo al iniciar sesión" "Activar epoptes" "Eliminar automatización de bloqueo" "Comprobación de estado" "Instalar BeanBash en el sistema" "Salir")
		select opt in "${options[@]}"; do
			case $opt in
			"Bloquear epoptes") epoptes_block; break;;
			"Automatizar bloqueo al iniciar sesión") auto_bock;	break;;
			"Activar epoptes") epoptes_unblock; break;;
			"Eliminar automatización de bloqueo") auto_unblock; break;;
			"Comprobación de estado")	prov;	break;;
			"Instalar BeanBash en el sistema") installer;	break;;
			"Salir") echo "¡Adiós!"
				break 2;;
			*) echo "invalid option $REPLY"
				break;;
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
			"Actualizar tabla ARP")	nmap -PR -sP $(ip -p r | grep -E "^.+\..+\..+\..+/.+ " | cut -d" " -f1 | grep -vE "^169.254.") >/dev/null 2>&1
				arp -e
				break;;
			"Cambiar MAC por la de un equipo de la red") nmap -PR -sP $(ip -p r | grep -E "^.+\..+\..+\..+/.+ " | cut -d" " -f1 | grep -vE "^169.254.") >/dev/null 2>&1
				i=1
				for line in $(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | tr '\n' ' '); do
					echo "$i) $line"
					((i++))
				done
				read -rp "Selecciona una tarjeta de red: " NUM
				CARD=$(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | sed $NUM'!d')
				i=1
				local IFS=$'\n'
				for line in $(arp -a | cut -d" " -f2,4); do
					echo "$i) $line"
					((i++))
				done
				read -rp "Selecciona una MAC para clonar: " NUM
				macchanger -r $CARD --mac="$(arp -a | cut -d" " -f2,4 | sed $NUM'!d' | cut -d" " -f2)"
				break;;
			"Cambiar MAC por una distinta") i=1
				for line in $(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | tr '\n' ' '); do
					echo "$i) $line"
					((i++))
				done
				read -rp "Selecciona una tarjeta de red: " NUM
				CARD=$(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | sed $NUM'!d')
				macchanger -rA $CARD
				dhclient -v $CARD
				break;;
			"Recuperar MAC original") i=1
				for line in $(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | tr '\n' ' '); do
					echo "$i) $line"
					((i++))
				done
				read -rp "Selecciona una tarjeta de red: " NUM
				CARD=$(ip -br link show | cut -d" " -f1 | grep -vE "^lo$" | sed $NUM'!d')
				macchanger -p $CARD
				dhclient -v $CARD
				break;;
			"Salir") break 2 ;;
			esac
		done
	done
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
		q) break ;;
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
