cd /var/www/foxden

sudo apt update
sudo apt -y upgrade

sudo useradd --system foxden

sudo apt -y install gnupg

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

sudo apt update

sudo apt -y install mongodb-org

sudo systemctl start mongod
sudo systemctl enable mongod

sudo apt -y install build-essential ruby-full git nginx

sudo gem install bundler

sudo chown foxden:foxden /var/www/foxden
sudo chmod 444 /var/www/foxden
sudo mkdir -p /var/www/foxden/public/static/img/profile
sudo chmod 644 /var/www/foxden/public/static/img/profile

bundler install

sudo cp misc/nginx.conf /etc/nginx/nginx.conf

sudo cp misc/foxden.service /etc/systemd/system/foxden.service
sudo systemctl daemon-reload
sudo systemctl start foxden
sudo systemctl enable foxden

sudo systemctl start nginx
sudo systemctl enable nginx
