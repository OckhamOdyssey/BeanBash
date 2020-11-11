#!/bin/bash

# Revisa si el usuario es root
if [ "$UID" -eq 0 ]
# Si el usuario es root, se muestra el mensaje
then echo "El script se está ejecutando como administrador."
# Si el usuario no es root, se solicitan permisos de administrador
else echo "Se requieren permisos de administrador para ejecutar el script."
  exec sudo "$0" "$@"
  # Fin de la condición
fi

echo "______                 ______           _     ";
echo "| ___ \                | ___ \         | |    ";
echo "| |_/ / ___  __ _ _ __ | |_/ / __ _ ___| |__  ";
echo "| ___ \/ _ \/ _\` | '_ \| ___ \/ _\` / __| '_ \ ";
echo "| |_/ /  __/ (_| | | | | |_/ / (_| \__ \ | | |";
echo "\____/ \___|\__,_|_| |_\____/ \__,_|___/_| |_|";
echo "                                              ";
echo "                                              ";
echo ""
echo "Bienvenido a BeanBash. Desde este script podrás bloquear o activar epoptes y/o SSH."
echo "Este script se distribuye sin ninguna garantía bajo licencia MIT. Copyright (c) 2020 TheRussianHetzer"
echo "Puedes consultar el repositorio de este script en GitHub. https://github.com/TheRussianHetzer/BeanBash"
echo "Elige la opción que desees realizar.";
echo "A no ser que sea imprescindible el uso del SSH, recomendamos bloquearlo también. Así puedes evitar que vuelvan a activar epoptes de forma remota."
echo ""
echo ""
PS3='Elige una opción: '
options=("Bloquear epoptes" "Bloquear epoptes y SSH" "Activar epoptes" "Activar epoptes y SSH" "Salir")
select opt in "${options[@]}"
do
    case $opt in
        "Bloquear epoptes")
            echo "Deteniendo servicio vmware"
            service vmware stop
            echo "Deteniendo servicio complementario vmware"
            service vmware-USBArbitrator stop
            echo "Deteniendo servicio epoptes"
            service epoptes-client stop
            if sudo apt install ufw> /dev/null 2>&1 ; then
              echo "El firewall ya se encuentra instalado, saltando instalación"
            else
              "Instalando firewall"
              sudo apt install -y ufw 1> /dev/null
            fi
            echo "Activando firewall"
            ufw enable
            echo "Bloqueando puerto epoptes por firewall"
            ufw deny 789
            echo "Matando procesos en ejecución restantes"
            kill $(ps -ax | grep epoptes | cut -d" " -f2) 2> /dev/null
            kill $(ps -ax | grep epoptes-client | cut -d" " -f2) 2> /dev/null
            echo "Proceso finalizado"
            break
            ;;
        "Bloquear epoptes y SSH")
            echo "Deteniendo servicio vmware"
            service vmware stop
            echo "Deteniendo servicio complementario vmware"
            service vmware-USBArbitrator stop
            echo "Deteniendo servicio epoptes"
            service epoptes-client stop
            echo "Deteniendo servicio SSH"
            service ssh stop
            if sudo apt install ufw> /dev/null 2>&1 ; then
              echo "El firewall ya se encuentra instalado, saltando instalación"
            else
              "Instalando firewall"
              sudo apt install -y ufw 1> /dev/null
            fi
            echo "Activando firewall"
            ufw enable
            echo "Bloqueando puerto epoptes por firewall"
            ufw deny 789
            echo "Bloqueando puerto SSH por firewall"
            ufw deny 22/tcp
            echo "Matando procesos en ejecución restantes"
            kill $(ps -ax | grep epoptes | cut -d" " -f2) 2> /dev/null
            kill $(ps -ax | grep epoptes-client | cut -d" " -f2) 2> /dev/null
            echo "Proceso finalizado"
            break
            ;;
        "Activar epoptes")
            echo "Desbloqueando puerto epoptes por firewall"
            ufw allow 789
            echo "Activando servicio epoptes"
            service epoptes-client start
            echo "Activado servicio vmware"
            service vmware start
            echo "Activando servicio complementario vmware"
            service vmware-USBArbitrator stop
            echo "Activando epoptes"
            sudo epoptes-client -c
            echo "Proceso finalizado"
            break
            ;;
        "Activar epoptes y SSH")
        echo "Desbloqueando puerto epoptes por firewall"
        ufw allow 789
        echo "Desbloqueando puerto SSH por firewall"
        ufw allow 22/tcp
        echo "Activando servicio epoptes"
        service epoptes-client start
        echo "Activando servicio SSH"
        service ssh start
        echo "Activado servicio vmware"
        service vmware start
        echo "Activando servicio complementario vmware"
        service vmware-USBArbitrator stop
        echo "Activando epoptes"
        sudo epoptes-client -c
        echo "Proceso finalizado"
        break
            ;;
        "Salir")
        echo "¡Adiós!"
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
