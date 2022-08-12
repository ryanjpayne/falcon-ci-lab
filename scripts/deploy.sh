#!/bin/bash
DG="\033[1;30m"
RD="\033[0;31m"
NC="\033[0;0m"
LB="\033[1;34m"

echo -e "$LB\n"
read -p "Your external IP Address (for remote SSH connection, CIDR format eg. 1.1.1.1/32): " trustedIp
echo -e "Initializing environment templates$NC"
bucketName="$(cat /tmp/environment.txt | cut -c -8 | tr _ - | tr '[:upper:]' '[:lower:]')-templatebucket"
az=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
region="`echo \"$az\" | sed 's/[a-z]$//'`"
cd /home/ec2-user
if [[ $region = "us-east-1" ]]
then
aws s3api create-bucket --bucket $bucketName --region $region
echo -e "$LB\n"
echo -e "Standing up environment$NC"
aws cloudformation create-stack --stack-name falcon-ci-lab-stack --template-url https://$bucketName.s3.amazonaws.com/entry.yaml --parameters ParameterKey=S3Bucket,ParameterValue=$bucketName ParameterKey=RemoteIp,ParameterValue=$trustedIp --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --region $region
else
aws s3api create-bucket --bucket $bucketName --region $region --create-bucket-configuration LocationConstraint=$region
echo -e "$LB\n"
echo -e "Standing up environment$NC"
aws cloudformation create-stack --stack-name falcon-ci-lab-stack --template-url https://$bucketName.s3-$region.amazonaws.com/entry.yaml --parameters ParameterKey=S3Bucket,ParameterValue=$bucketName ParameterKey=RemoteIp,ParameterValue=$trustedIp --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --region $region
fi
aws s3 cp templates/ s3://$bucketName --recursive
echo -e "$LB\n"
echo -e "Standing up environment$NC"
aws cloudformation create-stack --stack-name falcon-ci-lab-stack --template-url https://$bucketName.s3-$region.amazonaws.com/entry.yaml --parameters ParameterKey=S3Bucket,ParameterValue=$bucketName ParameterKey=RemoteIp,ParameterValue=$trustedIp --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --region $region
echo -e "The Cloudformation stack will take 5-10 minutes to complete$NC"
echo -e "\n\nCheck the status at any time with the command \n\naws cloudformation describe-stacks --stack-name falcon-ci-lab-stack --region $region$NC\n\n"