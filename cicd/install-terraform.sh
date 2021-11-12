#!/bin/bash -e
# If you are using an image where you need to install terraform on the fly, this is an example script you can use.
apt-get install unzip wget -y
wget -O terraform.zip "https://releases.hashicorp.com/terraform/${1}/terraform_${1}_linux_amd64.zip"
unzip terraform.zip -d /usr/local/bin/
terraform version