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
options=("Block epoptes" "Block epoptes and SSH" "Activate epoptes" "Activate epoptes y SSH" "Quit")
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
            if sudo apt install ufw> /dev/null 2>&1 ; then
              echo "The firewall is already installed, skipping"
            else
              "Installing firewall"
              sudo apt install -y ufw 1> /dev/null
            fi
            echo "Activating firewall"
            ufw enable
            echo "Blocking epoptes port by firewall"
            ufw deny 789
            echo "Killing remaining running processes"
            kill $(ps -ax | grep epoptes | cut -d" " -f2) 2> /dev/null
            kill $(ps -ax | grep epoptes-client | cut -d" " -f2) 2> /dev/null
            echo "Done!"
            break
            ;;
        "Block epoptes and SSH")
            echo "Stopping vmware service"
            service vmware stop
            echo "Stopping VMware Add-on Service"
            service vmware-USBArbitrator stop
            echo "Stopping epoptes service"
            service epoptes-client stop
            echo "Stopping SSH service"
            service ssh stop
            if sudo apt install ufw> /dev/null 2>&1 ; then
              echo "The firewall is already installed, skipping"
            else
              "Installing firewall"
              sudo apt install -y ufw 1> /dev/null
            fi
            echo "Activating firewall"
            ufw enable
            echo "Blocking epoptes port by firewall"
            ufw deny 789
            echo "Blocking SSH port by firewall"
            ufw deny 22/tcp
            echo "Killing remaining running processes"
            kill $(ps -ax | grep epoptes | cut -d" " -f2) 2> /dev/null
            kill $(ps -ax | grep epoptes-client | cut -d" " -f2) 2> /dev/null
            echo "Done!"
            break
            ;;
        "Activate epoptes")
            echo "Unblocking epoptes port by firewall"
            ufw allow 789
            echo "Activating epoptes service"
            service epoptes-client start
            echo "Activating vmware service"
            service vmware start
            echo "Activating VMware Add-on Service"
            service vmware-USBArbitrator stop
            echo "Activating epoptes"
            sudo epoptes-client -c
            echo "Done!"
            break
            ;;
        "Activate epoptes and SSH")
        echo "Unblocking epoptes port by firewall"
        ufw allow 789
        echo "Unblocking SSH port by firewall"
        ufw allow 22/tcp
        echo "Activating epoptes service"
        service epoptes-client start
        echo "Activating SSH service"
        service ssh start
        echo "Activating vmware service"
        service vmware start
        echo "Activating VMware Add-on Service"
        service vmware-USBArbitrator stop
        echo "Activating epoptes"
        sudo epoptes-client -c
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
