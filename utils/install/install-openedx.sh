#!/bin/bash

EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME=""
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME=""
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH=""
EDXAPP_LMS_BASE=""
EDXAPP_CMS_BASE=""

help()
{
    echo "This script sets up SSH, installs MDSD and runs the DB bootstrap"
    echo "Options:"
    echo "        --edxconfiguration-public-github-accountname Name of the account that owns the edx configuration repository"
    echo "        --edxconfiguration-public-github-projectname Name of the edx configuration GitHub repository"
    echo "        --edxconfiguration-public-github-projectbranch Branch of edx configuration GitHub repository"
    echo "        --edxplatform-lms-base Platform base URL for LMS"
    echo "        --edxplatform-cms-base Platform base URL for CMS"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
    do

        arg_value="${2}"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]]; 
        then
            arg_value=""
            shift_once=1
        fi

         # Log input parameters to facilitate troubleshooting
        echo "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
            --edxconfiguration-public-github-accountname)
                EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME="${arg_value}"
                ;;
            --edxconfiguration-public-github-projectname)
                EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME="${arg_value}"
                ;;
            --edxconfiguration-public-github-projectbranch)
                EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="${arg_value}"
                ;;
            --edxplatform-lms-base)
                EDXAPP_LMS_BASE="${arg_value}"
                ;;
            --edxplatform-cms-base)
                EDXAPP_CMS_BASE="${arg_value}"
                ;;
            -h|--help)  # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                echo "Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
                help
                exit 2
                ;;
        esac

        shift # past argument or value

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi
    done
}

# parse script arguments
parse_args $@

sudo apt-get update -y
sudo apt-get upgrade -y

sudo su

locale-gen en_US en_US.UTF-8
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
cd ~

echo "EDXAPP_LMS_BASE: \"$EDXAPP_LMS_BASE\"" >> config.yml
echo "EDXAPP_CMS_BASE: \"$EDXAPP_CMS_BASE\"" >> config.yml

apt-get install rabbitmq-server -y
apt autoremove -y
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management

apt-get install python3-pip -y

wget https://raw.githubusercontent.com/$EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME/$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME/$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH/util/install/ansible-bootstrap.sh -O - | sudo -H bash

mkdir /home/rabbitmq/
touch /home/rabbitmq/.erlan.cookie
chown -Rv rabbitmq:root /home/rabbitmq/.

wget https://raw.githubusercontent.com/$EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME/$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME/$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH/util/install/generate-passwords.sh -O - | bash

wget https://raw.githubusercontent.com/$EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME/$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME/$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH/util/install/native.sh -O - | bash > install.out &