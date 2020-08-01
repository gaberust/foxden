#!/bin/bash

# Update System, Install Git
apt update
apt -y upgrade
apt install -y git

# Download Source Code
while [ ! -d "./foxden" ]
do
    git clone https://github.com/gaberust/foxden.git
done

# Create Foxden System User
useradd --system foxden

# Install The Things
apt -y install gnupg build-essential ruby-full nginx

# Stop And Disable Nginx
systemctl disable nginx
systemctl stop nginx

# Configure And Enable UFW
ufw allow OpenSSH
ufw allow "Nginx Full"
ufw enable

# Install, Start, And Enable MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
apt update
apt -y install mongodb-org
systemctl start mongod
systemctl enable mongod

# Copy Source Code To Correct Destinations
mkdir -p /var/www
mv foxden /var/www/foxden
mv /var/www/foxden/misc/nginx.conf /etc/nginx/nginx.conf
mv /var/www/foxden/misc/foxden-start /usr/bin/foxden-start
chmod +x /usr/bin/foxden-start
mv /var/www/foxden/misc/foxden-stop /usr/bin/foxden-stop
chmod +x /usr/bin/foxden-stop
mv /var/www/foxden/misc/foxden-restart /usr/bin/foxden-restart
chmod +x /usr/bin/foxden-restart
rmdir /var/www/foxden/misc

# Create Necessary Directory Structures
mkdir -p /var/www/foxden/tmp/sockets
mkdir -p /var/www/foxden/tmp/pids
mkdir -p /var/www/foxden/log

# Give Foxden User Ownership Of App Directory
chown -R foxden:foxden /var/www/foxden

# Install Gem Dependencies
gem install --no-user-install --no-document unicorn sinatra mongoid bcrypt json jwt

# Finished
echo "Run foxden-start and foxden-stop to start and stop the application."
