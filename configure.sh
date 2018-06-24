#!/bin/bash

# This script is used to configure the Linux machine to be used as
# E-mail server. It will install requiered packages according to the
# parameters supplied by the user.

# Global variables
logFile="configure.log"

# Clean the old log file
if [ -e $logFile ]; then
    rm -rf $logFile
fi

# Check if the script has been run as root user
if [ $USER != "root" ]; then
    echo "Error: Script must be run as root user." >> $logFile
    exit 1
fi

# Source the function.sh to have access to commonly used functions
if [ ! -e functions.sh ]; then
    echo "Error: Unable to find functions.sh. Please make sure you have downloaded all the necessary files." >> $logFile
    exit 2
else
    source functions.sh
    if [ $? -ne 0 ]; then
        echo "Error: Unable to source functions.sh file." >> $logFile
        exit 3
    fi
fi

# In case configure is called with the help parameter show the help file
if [ "$1" == "--help" ] ||  [ "$1" == "help" ]; then
    cat help | grep "# Configure" -A 16 -B 1
    exit 0
fi

# Prepare constant parameters
GetHostInfo
if [ $? -ne 0 ]; then
    LogMessage "Error: Unable to get host information." $logFile
    exit 8
fi

if [ $freeDisk -lt 10 ]; then
    LogMessage "Warning: There is less than 10GB of free storage." $logFile
fi

if [ $totalMemMB -lt 1024 ]; then
    LogMessage "Warning: There is less than 1GB of total memory." $logFile
fi

# Read parameters
while getopts D:G:O:r:w:A: option; do
    case "${option}" in
        D) domainName=${OPTARG};;       #specifie the domain name which will be used to create the FQDN for the mail server.
        G) instalGUI=${OPTARG};;        #if set to [yes] a Graphical User Interface will be installed on the Linux Machine. Reboot required.
        O) openSSH=${OPTARG};;          #if set to [yes] it installs openssh-server on the Linux machine
        A) autoConfig=${OPTARG};;
    esac
done

#Append the domain name to the constants.sh file
domain=`echo $domainName | cut -d '.' -f 1`
tld=`echo $domainName | cut -d '.' -f 2`
echo "domainName=$domainName" >> constants.sh
echo "fqdn=$hostName.$domainName" >> constants.sh
echo "domain=$domain" >> constants.sh
echo "tld=$tld" >> constants.sh

# Check the distro we are running on
GetDistro

if [[ "$DISTRO" == "ubuntu"* ]]; then
    LogMessage "Info: $DISTRO distribution detected." $logFile
    LogMessage "Info: Proceeding to package installation." $logFile

    # Update repositories before proceeding to package installation
    apt-get update 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
        LogMessage "Error: Unable to update apt repositories." $logFile
        exit 3
    fi

    if [ "$autoConfig" == "yes" ] || [ "$autoConfig" == "Yes" ]; then
        instalGUI="yes"
        openSSH="yes"

    fi

    if [ "$instalGUI" == "yes" ] || [ "$instalGUI" == "Yes" ]; then
        dpkg --list | grep xserver
        if [ $? -ne 0 ]; then
            apt-get install -y ubuntu-desktop
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable install ubuntu-desktop" $logFile
                exit 4
            fi
        else
            LogMessage "Info: A GUI seems to be already installed. Skipping installation." $logFile
        fi
    fi

    if [ "$openSSH" == "yes" ] || [ "$openSSH" == "Yes" ]; then
        dpkg --list | grep openssh-server
        if [ $? -ne 0 ]; then
            apt-get install -y openssh-server
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable to install openssh-server." $logFile
                exit 4
            fi
        else
            LogMessage "Info: OpenSSH-Server is already installed. Skipping installation." $logFile
        fi

        cat /etc/ssh/sshd_config | grep "#PermitRootLogin"
        if [ $? -eq 0 ]; then
            sed -i -e 's/prohibit-password/yes/g' /etc/ssh/sshd_config
            sed -i -e 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable to uncomment PermitRootLogin" $logFile
                exit 5
            fi
        fi

        cat /etc/ssh/sshd_config | grep "#PasswordAuthentication"
        if [ $? -eq 0 ]; then
            sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable to uncomment PasswordAuthentication" $logFile
                exit 5
            fi
        fi
        # Restart the service to apply the new settings
        systemctl restart sshd
    fi
fi

######################################CentOS
if [[ "$DISTRO" == "centos"* ]]; then
    LogMessage "Info: $DISTRO distribution detected." $logFile
    LogMessage "Info: Proceeding to package installation." $logFile

    if [ "$instalGUI" == "yes" ] || [ "$instalGUI" == "Yes" ]; then
        rpm -qa | grep xserver
        if [ $? -ne 0 ]; then
            yum groupinstall -y "GNOME Desktop" "Graphical Administration Tools"
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable to install GNOME Desktop." $logFile
                exit 4
            fi
        else
            LogMessage "Info: A GUI seems to be already installed. Skipping installation." $logFile
        fi

        ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target
        if [ $? -ne 0 ]; then
            LogMessage "Error: Unable to create symlink for graphical target." $logFile
            exit 5
        fi
    fi

    if [ "$openSSH" == "yes" ] || [ "$openSSH" == "Yes" ]; then
        rpm -qa | grep openssh-server
        if [ $? -ne 0 ]; then
            yum install -y openssh-server
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable to install openssh-server." $logFile
                exit 4
            fi
        else
            LogMessage "Info: OpenSSH-Server is already installed. Skipping installation." $logFile
        fi

        cat /etc/ssh/sshd_config | grep "#PermitRootLogin"
        if [ $? -eq 0 ]; then
            sed -i -e 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable to uncomment PermitRootLogin" $logFile
                exit 5
            fi
        fi

        cat /etc/ssh/sshd_config | grep "#PasswordAuthentication"
        if [ $? -eq 0 ]; then
            sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
            if [ $? -ne 0 ]; then
                LogMessage "Error: Unable to uncomment PasswordAuthentication" $logFile
                exit 5
            fi
        fi
        # Restart the service to apply the new settings
        systemctl restart sshd
    fi
fi
