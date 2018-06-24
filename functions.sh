#!/bin/bash

# This function takes the message given as first argument and appends it to the log file given as second argument
# $1 == Message
# $2 == Log file
LogMessage()
{
        echo $(date "+%a %b %d %T %Y") : "${1}" >> "${2}"
}

# Return a variable $DISTRO with the name and version of the distribution we are on
# No parameters requiered
GetDistro()
{
# Make sure we don't inherit anything
declare __DISTRO
__DISTRO=$(grep -ihs "Ubuntu\|SUSE\|Fedora\|Debian\|CentOS\|Red Hat Enterprise Linux" /etc/{issue,*release,*version})
case $__DISTRO in
    *Ubuntu*12*)
            DISTRO=ubuntu_12
            ;;
    *Ubuntu*14*)
            DISTRO=ubuntu_14
            ;;
    *Ubuntu*16*)
            DISTRO=ubuntu_16
        ;;
    *Ubuntu*18*)
            DISTRO=ubuntu_18
            ;;
    *Ubuntu*)
            DISTRO=ubuntu_x
            ;;
    *Debian*7*)
            DISTRO=debian_7
            ;;
    *Debian*)
            DISTRO=debian_x
            ;;
    *SLE*15*)
            DISTRO=suse_15
            ;;
    *SUSE*15*)
            DISTRO=suse_15
            ;;
    *SUSE*12*)
            DISTRO=suse_12
            ;;
    *SUSE*11*)
            DISTRO=suse_11
            ;;
    *SUSE*)
            DISTRO=suse_x
            ;;
    *CentOS*5.*)
            DISTRO=centos_5
            ;;
    *CentOS*6.*)
            DISTRO=centos_6
            ;;
    *CentOS*7.*)
            DISTRO=centos_7
            ;;
    *CentOS*)
            DISTRO=centos_x
            ;;
    *Fedora*18*)
            DISTRO=fedora_18
            ;;
    *Fedora*19*)
            DISTRO=fedora_19
            ;;
    *Fedora*20*)
            DISTRO=fedora_20
            ;;
    *Fedora*)
            DISTRO=fedora_x
            ;;
    *Red*5.*)
            DISTRO=redhat_5
            ;;
    *Red*6.*)
            DISTRO=redhat_6
            ;;
    *Red*7.*)
            DISTRO=redhat_7
            ;;
    *Red*8.*)
            DISTRO=redhat_8
            ;;
    *Red*)
            DISTRO=redhat_x
            ;;
    *)
            DISTRO=unknown
            return 1
            ;;
esac
return 0
}

# Check for basic OS info
GetHostInfo() {
    # Clean old constants.sh
    if [ -e constants.sh ]; then
        rm -rf constants.sh
    fi

    # Check if we are on a virtual environment
    cat /proc/cpuinfo | grep -i "hypervisor" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        virtEnv="yes"
    else
        virtEnv="no"
    fi

    # Get processor count, total RAM and free disk space
    cpuNumber=`nproc`
    totalMemKB=`cat /proc/meminfo | grep "MemTotal" | awk '{print $2}'`
    totalMemMB=$((totalMemKB/1024))
    freeDiskG=`df -h | awk '/\/dev\/sd/ {print $4}'`
    freeDisk=`echo $freeDiskG | rev | cut -c 2- | rev`

    # Get IP address of the network adapter with access to internet and the WAN IP address
    declare -a activeInterface
    interfaces=`ip -o link show | awk -F':' '{print $2}'`
    for adapter in $interfaces; do
        ping -I $adapter -c 4 8.8.4.4 > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            activeInterface+="$adapter "
        fi
    done

    hostName=`hostname`
    hostIpCidr=`ip a | grep $activeInterface | grep -w inet| cut -f 6 -d ' '`
    hostIPv4=`echo $hostIpCidr | cut -f 1 -d '/'`
    wanIPv4=`dig +short myip.opendns.com @resolver1.opendns.com`
    
    # Export variables to constants.sh
    echo "virtEnv=$virtEnv" >> constants.sh
    echo "cpuNumber=$cpuNumber" >> constants.sh
    echo "totalMemKB=$totalMemKB" >> constants.sh
    echo "totalMemMB=$totalMemMB" >> constants.sh
    echo "freeDisk=$freeDisk" >> constants.sh
    echo "hostName=$hostName" >> constants.sh
    echo "hostIpCidr=$hostIpCidr" >> constants.sh
    echo "hostIPv4=$hostIPv4" >> constants.sh
    echo "wanIPv4=$wanIPv4" >> constants.sh
}
