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

sudo mkdir -p /var/www

cd /var/www

# TODO chmod/chown

git clone https://github.com/gaberust/foxden.git

cd foxden

bundler install

sudo cp misc/nginx.conf /etc/nginx/nginx.conf

# TODO create, start, and enable unicorn systemd service

sudo systemctl start nginx
sudo systemctl enable nginx
