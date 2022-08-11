#!/bin/bash
UNIQUE=$(cat /tmp/environment.txt | cut -c -8 | tr _ - | tr '[:upper:]' '[:lower:]')
cd /home/ec2-user
/home/ec2-user/scripts/deploy.sh up --unique_id="$UNIQUE" --trusted="$(curl -s http://ipinfo.io/ip)/32"