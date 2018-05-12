#!/bin/bash
yum update -y
yum install httpd -y
systemctl start httpd
yum install git -y