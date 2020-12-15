#!/bin/bash

# Check if the user is root
if [ "$UID" -eq 0 ]
# If the user is root, a message is displayed
then echo "El script se está ejecutando como administrador."
# If the user is not root, request sudo permissions
else echo "Se requieren permisos de administrador para ejecutar el script."
  exec sudo "$0" "$@"
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
echo "Wellcome to BeanBash. With this script you can block or activate epoptes and/or SSH."
echo "This script is distributed without any warranty under MIT license. Copyright (c) 2020 TheRussianHetzer"
echo "You can check the repository of this script on GitHub. https://github.com/TheRussianHetzer/BeanBash"
echo "Choose the option you want.";
echo "Unless the use of SSH is essential, we recommend blocking it as well. This is how you can prevent epoptes from re-activating remotely."
echo ""
echo ""
PS3='Choose an option: '
options=("Block epoptes" "Activate epoptes" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Block epoptes")
            echo "Stopping vmware service"
            service vmware stop
            echo "Stopping VMware Add-on Service"
            service vmware-USBArbitrator stop
            echo "Stopping epoptes service"
            service epoptes-client stop
            echo "Blocking server IP from kernel"
            route add -host $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
            echo "Killing remaining running processes"
            kill $(ps -ax | grep epoptes | cut -d" " -f2) 2> /dev/null
            kill $(ps -ax | grep epoptes-client | cut -d" " -f2) 2> /dev/null
            echo "Done!"
            break
            ;;
        "Activate epoptes")
            echo "Unblocking server IP from kernel"
            route del $(cat /etc/default/epoptes-client | grep SERVER | cut -d= -f2) reject
            echo "Activating epoptes service"
            service epoptes-client start
            echo "Activating vmware service"
            service vmware start
            echo "Activating VMware Add-on Service"
            service vmware-USBArbitrator stop
            echo "Activating epoptes"
            epoptes-client -c > /dev/null
            timeout 2 epoptes-client> /dev/null 2>&1
            echo "Done!"
            break
            ;;
        "Salir")
        echo "Bye!"
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
