#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y

sudo su

locale-gen en_US en_US.UTF-8
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
cd ~

echo 'EDXAPP_LMS_BASE: "enialrash.org"' >> config.yml
echo 'EDXAPP_CMS_BASE: "studio.enialrash.org"' >> config.yml

export OPENEDX_RELEASE=open-release/ironwood.master

apt-get install rabbitmq-server -y
apt autoremove -y
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management

apt-get install python3-pip -y

wget https://raw.githubusercontent.com/edx/configuration/$OPENEDX_RELEASE/util/install/ansible-bootstrap.sh -O - | sudo -H bash

mkdir /home/rabbitmq/
touch /home/rabbitmq/.erlan.cookie
chown -Rv rabbitmq:root /home/rabbitmq/.

wget https://raw.githubusercontent.com/edx/configuration/$OPENEDX_RELEASE/util/install/generate-passwords.sh -O - | bash

wget https://raw.githubusercontent.com/edx/configuration/$OPENEDX_RELEASE/util/install/native.sh -O - | bash > install.out &