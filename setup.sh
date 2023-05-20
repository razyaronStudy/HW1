#!/bin/bash

# Set variables
AMI="ami-024e6efaf93d85776"  # Updated AMI ID
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_NAME="my-security-group"
KEY_PAIR_NAME="my-key-pair"
VOLUME_SIZE=16
VOLUME_TYPE="gp3"

# Create security group
aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "My security group"
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP_NAME --protocol tcp --port 22 --cidr 0.0.0.0/0

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCE_TYPE --security-groups $SECURITY_GROUP_NAME --key-name $KEY_PAIR_NAME --block-device-mappings DeviceName=/dev/sda1,Ebs={VolumeSize=$VOLUME_SIZE,VolumeType=$VOLUME_TYPE} | grep "InstanceId" | awk -F'"' '{print $4}')

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP address of the instance
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

# Copy code to the instance
scp -i ~/.ssh/my-key-pair.pem parking_lot.py ubuntu@$PUBLIC_IP:/home/ubuntu/

# Connect to the instance and execute commands
ssh -i ~/.ssh/my-key-pair.pem ubuntu@$PUBLIC_IP << EOF
    # Install dependencies (assuming Ubuntu)
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip

    # Install Flask
    pip3 install flask

    # Run the Python code
    python3 /home/ubuntu/parking_lot.py
EOF

# Print instructions for executing the code
echo "The code has been deployed to the EC2 instance."
echo "To access the instance, use the following command:"
echo "ssh -i ~/.ssh/my-key-pair.pem ubuntu@$PUBLIC_IP"
echo "Once connected to the instance, you can run the code by executing the following command:"
echo "python3 /home/ubuntu/parking_lot.py"
