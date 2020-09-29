#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo chkconfig httpd on
#sudo bash -c 'echo webserver deployment on aws via terraform > /var/www/html/index.html'
echo "<h1>hello from $(hostname -f)<h1>" | sudo tee /var/www/html/index.html