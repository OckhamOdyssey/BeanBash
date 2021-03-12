#!/bin/bash -x

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
echo "Este script se distribuye sin ninguna garantía bajo licencia MIT y el creador no se hace responsable de la finalidad de su uso. Copyright (c) 2020-2021 TheRussianHetzer"
echo "Puedes consultar el repositorio de este script en GitHub. https://github.com/TheRussianHetzer/BeanBash"
echo "Elige la opción que desees realizar.";
echo ""
echo ""
PS3='Elige una opción: '
options=("Bloquear epoptes" "Automatizar bloqueo al iniciar sesión" "Activar epoptes" "Eliminar automatización de bloqueo" "Comprobación de estado" "Salir")
select opt in "${options[@]}"
do
    case $opt in
        "Bloquear epoptes")
            echo "Bloqueando IP del servidor"
            route add -host $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
            break
            ;;
        "Automatizar bloqueo al iniciar sesión")
            IP=$(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2)
            crontab -l 2>&1 | grep -qi "#autobean"
            if [ $? != 0 ]; then
              echo "Añadiendo regla cron al usuario root"
              (crontab -l ; echo "@reboot /sbin/route add -host $IP reject #autobean") | grep -v "no crontab" | sort | uniq | crontab -
            else
              echo "La regla ya se encuentra en el cron"
            fi
            break
            ;;
        "Activar epoptes")
            echo "Desbloqueando IP del servidor"
            route del $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
            break
            ;;
        "Eliminar automatización de bloqueo")
        crontab -l 2>&1 | grep -qi "#autobean"
        if [ $? = 0 ]; then
            crontab -l | grep -v "#autobean" | crontab -
          else
            echo "No se ha encontrado la regla en el cron"
          fi
          break
          ;;
        "Comprobación de estado")
        IP=$(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2)
        DOMAIN=$(nslookup $IP | grep name | cut -d"=" -f2)  
          echo "Solicitando respuesta de $IP"
          ping -c 1 $IP > /dev/null 2>&1
          if [[ $? = 0 ]]; then
            echo "Se recibe respuesta del servidor."
            echo -e "El bloqueo está \e[1m\e[31mdesactivado\e[0m. El sistema puede ser monitorizado"
          else
            echo "No se recibe respuesta del servidor"
            echo "Revisando tabla de redireccionamiento"
            route | grep -qE "^$IP.+!"
            if [[ $? = 0 ]]; then
              echo "El servicio aparece como bloqueado"
              echo -e "El bloqueo está \e[1m\e[32mactivado\e[0m"
            elif [ 'route | grep -qE "^$DOMAIN.+!"' ]; then
              echo "El servicio aparece como bloqueado"
              echo -e "El bloqueo está \e[1m\e[32mactivado\e[0m"
            else
              echo "OWO"
            fi
          fi
          echo "Revisando archivo cron"
          crontab -lu root | grep -qE "#autobean$"
          if [[ $? = 0 ]]; then
            echo -e "El bloqueo automático está \e[1m\e[32mactivado\e[0m"
          else
            echo -e "El bloqueo automático está \e[1m\e[31mdesactivado\e[0m"
          fi
          ;;
        "Salir")
          echo "¡Adiós!"
          break
          ;;
        *) echo "invalid option $REPLY";;
    esac
done
