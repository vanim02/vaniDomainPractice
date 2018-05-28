#!/bin/bash
## retrieve instance id
instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
## compare with pilot instance
if [ $instanceId != i-0baa2bdc4d34bc008 ]
then
			exit 0
	else
	##git pull from origin
	cd /home/ec2-user/vaniDomainPractice 
	 sudo git pull origin master
	sleep 30s

	
	 sudo cp /home/ec2-user/vaniDomainPractice/index.html /var/www/html/

	echo "create image for the pilot instance"
	latestami=$(aws ec2 create-image --instance-id $instanceId --name vani-mutable-img-$(date -u +\%Y\%m\%dT\%H\%M\%S) --region us-east-1 --output text --no-reboot)

	echo "ami created is $latestami"

	imageState=$(aws ec2 describe-images --image-id $latestami --query 'Images[].[State]' --owners self  --region us-east-1 --output text)
	while [ $imageState != "available" ]
	do
	echo "image status now is $imageState"
	   sleep 30
	imageState="$(aws ec2 describe-images --image-id $latestami --query 'Images[].[State]' --owners self --region us-east-1 --output text)"
	done
		
		lcName=$(echo vaniMutableLc$(date -u +\%Y\%m\%dT\%H\%M\%S))
		echo "launch config in process"
		aws autoscaling create-launch-configuration --launch-configuration-name $lcName  --image-id $latestami --instance-type t2.micro --region us-east-1
	
	
	lcState=$(aws autoscaling describe-launch-configurations --launch-configuration-name $lcName  --region us-east-1| grep ImageId)
	while [ -z "$lcState" ]
	do
	echo "launch configuration status now is $lcState"
		sleep 30
	done
	
		
	if [ -z "$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name vaniMutableAsg --region us-east-1 --output text)" ]
	then
<<<<<<< HEAD
		 echo "vani asg does not exists"
			aws autoscaling create-auto-scaling-group --auto-scaling-group-name vaniMutableAsg --launch-configuration-name $lcName --min-size 2 --max-size 4 --load-balancer-names mutable-lb --vpc-zone-identifier subnet-85ff13ab --vpc-zone-identifier subnet-90c771da --region us-east-1
	else
	
	echo "vani asg exists"
=======
		 echo "mutable asg does not exists"
			aws autoscaling create-auto-scaling-group --auto-scaling-group-name vaniMutableAsg --launch-configuration-name $lcName --min-size 2 --max-size 4 --load-balancer-names mutable-lb --vpc-zone-identifier subnet-85ff13ab --vpc-zone-identifier subnet-90c771da --region us-east-1
	else
	
	echo "mutable asg exists"
>>>>>>> d4de0e5054fff242ea199f6d56b72f4625c38fbb
			aws autoscaling update-auto-scaling-group --auto-scaling-group-name vaniMutableAsg --launch-configuration-name $lcName --min-size 1 --max-size 4 --vpc-zone-identifier subnet-85ff13ab --vpc-zone-identifier subnet-90c771da --termination-policies "OldestLaunchConfiguration"  --region us-east-1
	echo "updating launch configuration"
			
			while [ "$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name vaniMutableAsg  --region us-east-1 --query 'AutoScalingGroups[].[LaunchConfigurationName]' --output text)" != "$lcName" ]
			do
				echo "LC not updated yet"
				sleep 30
			done
	sleep 10					 
echo "scale up in process..."	 
aws autoscaling set-desired-capacity --auto-scaling-group-name vaniMutableAsg  --region us-east-1 --desired-capacity 4
	sleep 10
echo "scale down in process..."
	  aws autoscaling set-desired-capacity --auto-scaling-group-name vaniMutableAsg  --region us-east-1 --desired-capacity 2	
fi
		
fi

