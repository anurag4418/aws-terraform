#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo chkconfig httpd on
echo "<h1>hello from $(hostname -f)<h1>" | sudo tee /var/www/html/index.html
