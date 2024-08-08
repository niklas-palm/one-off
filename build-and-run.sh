#!/bin/bash

set -e  # Exit on error


# Variables
AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STACK_NAME="one-off"

# Function to handle errors
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Fetch required parameters from CloudFormation stack outputs
echo "Fetching stack outputs from CloudFormation..."

# Fetch required parameters from CloudFormation stack outputs
SUBNET_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MySubnet'].OutputValue" --output text)
SECURITY_GROUP_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MySecurityGroup'].OutputValue" --output text)
CLUSTER_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MyECSCluster'].OutputValue" --output text)
TASK_DEFINITION_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MyTaskDefinition'].OutputValue" --output text)
ECR_REPOSITORY_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MyECRRepository'].OutputValue" --output text)

# Log fetched values
echo "Fetched values from CloudFormation stack:"
echo "SUBNET_ID: $SUBNET_ID"
echo "SECURITY_GROUP_ID: $SECURITY_GROUP_ID"
echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "TASK_DEFINITION_NAME: $TASK_DEFINITION_NAME"
echo "ECR_REPOSITORY_NAME: $ECR_REPOSITORY_NAME"

# Step 1: Authenticate Docker to AWS ECR
echo "Authenticating Docker to AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com || error_exit "Docker authentication to ECR failed."

# Step 2: Build the Docker image
cd container || error_exit "Directory 'container' not found."
echo "Building Docker image..."
docker build --platform linux/amd64 -t $ECR_REPOSITORY_NAME . || error_exit "Docker build failed."

# Step 3: Tag the Docker image
echo "Tagging Docker image..."
docker tag $ECR_REPOSITORY_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest || error_exit "Docker tag failed."

# Step 4: Push the Docker image to ECR
echo "Pushing Docker image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest || error_exit "Docker push to ECR failed."

# Step 5: Run the ECS task
echo "Running ECS task..."
aws ecs run-task \
  --cluster $CLUSTER_NAME \
  --task-definition $TASK_DEFINITION_NAME \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" || error_exit "ECS task run failed."

echo "Build and run completed!"
