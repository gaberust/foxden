#!/usr/bin/bash

# Update System
sudo apt update
sudo apt -y upgrade

# Create Foxden System User
sudo useradd --system foxden
sudo mkdir -p /home/foxden
sudo chown -R foxden:foxden /home/foxden

# Install The Things
sudo apt -y install gnupg build-essential ruby-full nginx git

# Configure And Enable UFW
sudo ufw allow OpenSSH
sudo ufw allow "Nginx HTTP"
sudo ufw enable

# Install, Start, And Enable MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
sudo apt update
sudo apt -y install mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# Download Source Code
git clone https://github.com/gaberust/foxden.git
sudo mkdir -p /var/www
sudo mv foxden /var/www/foxden
sudo mv /var/www/foxden/misc/nginx.conf /etc/nginx/nginx.conf
sudo mv /var/www/foxden/misc/foxden-start /usr/bin/foxden-start
sudo mv /var/www/foxden/misc/foxden-stop /usr/bin/foxden-stop
sudo rmdir /var/www/misc

# Create Necessary Directory Structures
sudo mkdir -p /var/www/foxden/tmp/sockets
sudo mkdir -p /var/www/foxden/tmp/pids
sudo mkdir -p /var/www/foxden/log

# Give Foxden User Ownership Of App Directory
sudo chown -R foxden:foxden /var/www/foxden

# Install Gem Dependencies
sudo -u foxden bundle install --gemfile=/var/www/foxden/Gemfile

# Finished
echo "Run foxden-start and foxden-stop to start and stop the application."
