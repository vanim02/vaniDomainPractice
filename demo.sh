#!/bin/bash
instid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
if [  $instid != i-0e39588a46e0127d6 ]
then
      exit 0
else
##git pull
echo 'doing git pull' 
cd /home/ec2-user/vaniDomainPractice && sudo git pull origin master
sleep 30
cd /home/ec2-user
##create image for the pilot instance
echo 'creating an AMI'
aws ec2 create-image --instance-id i-0e39588a46e0127d6 --name demoimg-$(date -u +\%Y\%m\%dT\%H\%M\%S) --region us-east-1 --no-reboot
echo 'sleep mode for 90secs'
sleep 90
##retrieve the latest image and assign it to create a launch-configuration
echo 'creating a LC with new AMI'
varami=$(aws ec2 describe-images --region us-east-1 --owners self --query 'Images[].[CreationDate,ImageId]' --output table | sort -k1r | grep ami |head -n1|awk '{print $4}')
aws autoscaling create-launch-configuration --launch-configuration-name demolc$(date -u +\%Y\%m\%dT\%H\%M\%S) --image-id $varami --instance-type t2.micro --region us-east-1
echo 'sleep mode for 90 secs' 
sleep 90

###retrieve the latest launch-configurations and assign it to create autoscaling group
echo 'retrieveing the LC and assigning to the  ASG'
varLc=$(aws autoscaling  describe-launch-configurations --region us-east-1 --output table  --query 'LaunchConfigurations[].[CreatedTime,LaunchConfigurationName,InstanceType]' | grep t2 | sort -k1r | head -n1 | awk '{print $4}')
asgname=$(aws autoscaling describe-auto-scaling-groups  --query 'AutoScalingGroups[].[AutoScalingGroupName]' --region us-east-1 --output text|grep ^demoasg$)
 if [ $asgname == demoasg ]
 then
     	echo 'updating the ASG  demoasg please wait.......'
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name demoasg --launch-configuration-name $varLc --region us-east-1 --min-size 1 --max-size 5 --vpc-zone-identifier subnet-90c771da
    echo 'Scaling up now please wait....'
aws autoscaling put-scheduled-update-group-action --scheduled-action-name ScaleUp --auto-scaling-group-name demoasg --desired-capacity 4 --start-time "$(date -d "+30 secs")" --region us-east-1
    echo 'Scaling down '
aws autoscaling put-scheduled-update-group-action --scheduled-action-name ScaleDown --auto-scaling-group-name demoasg --desired-capacity 1 --start-time "$(date -d "+300 secs")" --region us-east-1

 else 
 echo 'creating a new asg please wait.....'
 aws autoscaling create-auto-scaling-group --auto-scaling-group-name demoasg --launch-configuration-name $varLc --min-size 2 --max-size 3 --load-balancer-names projectELB --vpc-zone-identifier subnet-90c771da  --region us-east-1 --termination-policies "OldestLaunchConfiguration"
fi
echo 'Script SUccessful '
fi
