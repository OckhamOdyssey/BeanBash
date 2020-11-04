#!/bin/bash

# Check if the user is root
if [ "$UID" -eq 0 ]
# If the user is root, a message is displayed
then echo "The script is running as sudo."
# If the user is not root, request sudo permissions
else echo "Sudo permissions are required to run the script."
  exec sudo "$0" "$@"
fi
# Stopping services and notifying the process
echo "Stopping vmware service"
service vmware stop
echo "Stopping VMware Add-on Service"
service vmware-USBArbitrator stop
echo "Stopping epoptes service"
service epoptes-client stop
echo "Stopping SSH service"
service ssh stop
# Port blocking by ufw firewall
echo "Activating firewall"
ufw enable
echo "Blocking epoptes port by firewall"
ufw deny 789
echo "Blocking SSH port by firewall"
ufw deny 22/tcp
echo "Killing remaining running processes"
kill $(ps -ax | grep epoptes | cut -d" " -f2)
kill $(ps -ax | grep epoptes-client | cut -d" " -f2)
