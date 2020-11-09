    ______                 ______           _     
    | ___ \                | ___ \         | |    
    | |_/ / ___  __ _ _ __ | |_/ / __ _ ___| |__  
    | ___ \/ _ \/ _` | '_ \| ___ \/ _` / __| '_ \
    | |_/ /  __/ (_| | | | | |_/ / (_| \__ \ | | |
    \____/ \___|\__,_|_| |_\____/ \__,_|___/_| |_|

# Performance

BeanBash is a script written in Bash dedicated to blocking the epoptes service and being able to prevent remote connection from this service. In addition, you have the possibility to also block the SSH service to prevent them from re-enabling epoptes remotely. Epoptes uses VMWare, so this service must be stopped as well.

Every time you log in again, epoptes starts again with all services, so the script must be run every time.

This script uses the "service" and "apt" commands so it only works with Debian and its derivatives like Ubuntu.

The blocking options stop the VMWare and epoptes services, then detect if ufw is on the system and install it if not. After this, create the rules to block the applications' ports and kill the active processes of epoptes.

The activation options remove the applications' port blocking rules, start epoptes and vmware services, and rerun epoptes-client for activation.

If the option includes SSH, perform the same processes by including this service in the commands.

# Download

You can download the script directly from GitHub, there are two ways to download: by cloning the repository and downloading the compressed file.

## Cloning repository
To download from the repository you must have git installed, it can be installed with the following command:
```
sudo apt install git
```
With git installed, you have to stay in the directory where you want to have the script and execute the following command:
```
git clone https://github.com/TheRussianHetzer/BeanBash.git
```
This command will create a directory that will contain the script ready to be executed.

## Download compressed file

From [this link](https://github.com/TheRussianHetzer/BeanBash/archive/main.zip) you can get the English version. Through [this link](https://github.com/TheRussianHetzer/BeanBash/archive/es.zip) you will have the Spanish version. The Spanish version is always released in advance and may have more bugs but more features.
Once downloaded it can be unzipped using the following command:
```
tar -xvzf example.zip
```
Change ```ejemplo.zip``` to the file name.

# Possible issues
## Not an executable file

It may be necessary to add execute permissions to the script in order to work. To do this, you must first go to the directory where the script is stored and execute the following command:
```
chmod u+x ./BeanBash.sh
```
