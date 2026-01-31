#!/bin/bash

SG_ID="sg-0b7199557ac4e0337"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z0996154EJGGPGBA9M2V"
DOMAIN_NAME="daws88s.store"

for instance in $@
do
    instance_id=$( aws ec2 run-instances \ 
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-groups-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )
    
    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        RECORD_NAME="$DOMAIN_NAME"
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME="$instance.$DOMAIN_NAME"
    fi 

    echo "IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                { 
                    "Value": "$IP" 
                }
                ]
            }
            }
        ]
    }  

    '
    
    echo "Record updated for $instance"

done


