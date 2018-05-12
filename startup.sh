#!/bin/bash
yum update -y
yum install httpd -y
systemctl start httpd
yum install git -y
cd /home/ec2-user/vaniDomainPractice
watch -n 120 git pull origin master
