#!/bin/bash
DG="\033[1;30m"
RD="\033[0;31m"
NC="\033[0;0m"
LB="\033[1;34m"

echo -e "$LB\n"
read -p "Your external IP Address (for remote SSH connection, CIDR format eg. 1.1.1.1/32): " TRUSTED_IP
echo -e "Initializing environment templates$NC"
BUCKET_NAME="$(cat /tmp/environment.txt | cut -c -8 | tr _ - | tr '[:upper:]' '[:lower:]')-templatebucket"
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
REGION_CODE="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
cd /home/ec2-user
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION_CODE --create-bucket-configuration LocationConstraint=$REGION_CODE
aws s3 cp templates/ s3://$BUCKET_NAME --recursive
echo -e "$LB\n"
echo -e "Standing up environment$NC"
aws cloudformation create-stack --stack-name falcon-ci-lab-stack --template-url https://$BUCKET_NAME.s3-$REGION_CODE.amazonaws.com/entry.yaml --parameters ParameterKey=S3Bucket,ParameterValue=$BUCKET_NAME ParameterKey=RemoteIp,ParameterValue=$TRUSTED_IP --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --region $REGION_CODE
echo -e "The Cloudformation stack will take 5-10 minutes to complete$NC"
echo -e "\n\nCheck the status at any time with the command \n\naws cloudformation describe-stacks --stack-name falcon-ci-lab-stack --region $REGION_CODE$NC\n\n"