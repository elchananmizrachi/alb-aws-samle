#! /bin/bash
yum update -y
sudo amazon-linux-extras install nginx1 -y
sleep 10
echo "<h1>Hello from web-server Number 2</h1>" | sudo tee /var/www/html/index.html