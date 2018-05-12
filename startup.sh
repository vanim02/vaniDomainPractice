
#!bin/bash
sudo yum update -y
sudo yum install httpd -y
systemctl start httpd
sudo yum install git -y
