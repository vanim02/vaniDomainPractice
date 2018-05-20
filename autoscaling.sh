#!/bin/bash
## retrieve instance id
instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
## compare with pilot instance
if [ $instanceId != i-0d371ecf0e1b145dd ] 
then
	exit 0
else
##git pull for every 30 mins 
cd /home/ec2-user/vaniDomainPractice && sudo git pull origin master
sleep 30s

cd /home/ec2-user/

echo "create image for the pilot instance"
aws ec2 create-image --instance-id i-0d371ecf0e1b145dd --name vani-img-$(date -u +\%Y\%m\%dT\%H\%M\%S) --region us-east-1 --no-reboot

sleep 2m

##retrieve the latest image and assign it to create a launch-configuration
latestami=$(aws ec2 describe-images --region us-east-1 --owners self --query 'Images[].[CreationDate,ImageId]' --output table | sort -k1r | grep ami |head -n1|awk '{print $4}') 

aws autoscaling create-launch-configuration --launch-configuration-name vanilc$(date -u +\%Y\%m\%dT\%H\%M\%S)  --image-id $latestami --instance-type t2.micro --region us-east-1

sleep 2m

echo "launch config in process"

###retrieve the latest launch-configurations and assign it to create autoscaling group
latestLc=$(aws autoscaling  describe-launch-configurations --region us-east-1 --output table  --query 'LaunchConfigurations[].[CreatedTime,LaunchConfigurationName,InstanceType]' | grep t2 | sort -k1r | head -n1 | awk '{print $4}')
echo "Latest LC is $latestLc"

##retrieve the list of auto-scaling-group into the array
asg=$(aws autoscaling describe-auto-scaling-groups  --query 'AutoScalingGroups[].[AutoScalingGroupName]' --output text| grep ^vaniasg$)
	
echo "ASG is $asg"

if [ $asg == vaniasg ] 
then
echo "vani asg exists"
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name vaniasg --launch-configuration-name $latestLc --min-size 2 --max-size 4 --vpc-zone-identifier subnet-a5827ec2 --termination-policies "OldestLaunchConfiguration"

sleep 90
echo "scale up in process" 
	aws autoscaling put-scheduled-update-group-action --scheduled-action-name ScaleUp --auto-scaling-group-name vaniasg --start-time "$(date -d "+30 secs")" --desired-capacity 4

sleep 90
echo "scale down in process"
		
	 aws autoscaling put-scheduled-update-group-action --scheduled-action-name ScaleDown --auto-scaling-group-name vaniasg --start-time "$(date -d "+30 secs")"  --desired-capacity 2 
else
echo "vani asg does not exists"
	aws autoscaling create-auto-scaling-group --auto-scaling-group-name vaniasg --launch-configuration-name $latestLc --min-size 2 --max-size 4 --load-balancer-names vanilb --vpc-zone-identifier subnet-a5827ec2 --region us-east-1 
fi
fi
