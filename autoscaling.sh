#!/bin/bash
## retrieve instance id
instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
## compare with pilot instance
if [ $instanceId != i-0b46d5e092817eb1b ]
then
			exit 0
	else
	#git pull from origin
	cd /home/ec2-user/vaniDomainPractice 
	sudo git pull origin master
	sleep 30s

	
	sudo cp /home/ec2-user/vaniDomainPractice/index.html /var/www/html/

	echo "create image for the pilot instance"
	latestami=$(aws ec2 create-image --instance-id $instanceId --name vani-img-$(date -u +\%Y\%m\%dT\%H\%M\%S) --region us-east-1 --output text --no-reboot)

	echo "ami created is $latestami"

	imageState=$(aws ec2 describe-images --image-id $latestami --query 'Images[].[State]' --owners self  --region us-east-1 --output text)
	while [ $imageState != "available" ]
	do
	echo "image status now is $imageState"
	   sleep 30
	imageState="$(aws ec2 describe-images --image-id $latestami --query 'Images[].[State]' --owners self --region us-east-1 --output text)"
	done
		
		lcName=$(echo vanilc$(date -u +\%Y\%m\%dT\%H\%M\%S))
		echo "launch config in process"
		aws autoscaling create-launch-configuration --launch-configuration-name $lcName  --image-id $latestami --instance-type t2.micro --region us-east-1 --associate-public-ip-address 
	
	
	lcState=$(aws autoscaling describe-launch-configurations --launch-configuration-name $lcName  --region us-east-1| grep ImageId)
	while [ -z "$lcState" ]
	do
	echo "launch configuration status now is $lcState"
		sleep 30
	done
	
		
	if [ -z "$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name vaniasg --region us-east-1 --output text)" ]
	then
		 echo "vani asg does not exists"
			aws autoscaling create-auto-scaling-group --auto-scaling-group-name vaniasg --launch-configuration-name $lcName --min-size 2 --max-size 4 --load-balancer-names vanilb --vpc-zone-identifier subnet-a5827ec2  --vpc-zone-identifier subnet-95b857bb --region us-east-1

	else
		  
	echo "vani asg exists"
			aws autoscaling update-auto-scaling-group --auto-scaling-group-name vaniasg --launch-configuration-name $lcName --min-size 0 --max-size 4 --vpc-zone-identifier subnet-a5827ec2 --vpc-zone-identifier subnet-95b857bb --termination-policies "OldestLaunchConfiguration"  --region us-east-1
	echo "updating launch configuration"
			
			while [ "$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name vaniasg  --region us-east-1 --query 'AutoScalingGroups[].[LaunchConfigurationName]' --output text)" != "$lcName" ]
			do
				echo "LC not updated yet"
				sleep 30
			done
	sleep 30					 
echo "scale up in process..."	 
aws autoscaling set-desired-capacity --auto-scaling-group-name vaniasg  --region us-east-1 --desired-capacity 4
	sleep 30
echo "scale down in process..."
	  aws autoscaling set-desired-capacity --auto-scaling-group-name vaniasg  --region us-east-1 --desired-capacity 2	
fi
		
fi

