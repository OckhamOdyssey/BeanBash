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
echo "Bienvenido a BeanBash. Desde este script podrás bloquear o desbloquear epoptes."
echo "Este script se distribuye sin ninguna garantía bajo licencia MIT y el creador no se hace responsable de la finalidad de su uso. Copyright (c) 2020 TheRussianHetzer"
echo "Puedes consultar el repositorio de este script en GitHub. https://github.com/TheRussianHetzer/BeanBash"
echo "Elige la opción que desees realizar.";
echo ""
echo ""
PS3='Elige una opción: '
options=("Bloquear epoptes" "Activar epoptes" "Salir")
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
            echo "Bloqueando IP del servidor"
            route add -host $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
            echo "Matando procesos en ejecución restantes"
            kill $(ps -ax | grep epoptes | cut -d" " -f1,2) 2> /dev/null
            echo "Proceso finalizado"
            break
            ;;
        "Activar epoptes")
            echo "Desbloqueando IP del servidor"
            route del $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
            echo "Activando servicio epoptes"
            service epoptes-client start
            echo "Activado servicio vmware"
            service vmware start
            echo "Activando servicio complementario vmware"
            service vmware-USBArbitrator stop
            echo "Activando epoptes"
            epoptes-client -c > /dev/null
            timeout 2 epoptes-client> /dev/null 2>&1
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
