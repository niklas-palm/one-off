#!/bin/bash

set -e  # Exit on error

# Variables
AWS_REGION="eu-west-1"
STACK_NAME="one-off"

# Function to handle errors
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Fetch CloudWatch Log Group name from CloudFormation stack outputs
echo "Fetching log group name from CloudFormation stack..."

LOG_GROUP_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MyLogGroup'].OutputValue" --output text) || error_exit "Failed to get Log Group name from CloudFormation stack."

# Log fetched value
echo "Fetched Log Group Name: $LOG_GROUP_NAME"

# Check if the Log Group name is empty
if [ -z "$LOG_GROUP_NAME" ]; then
    error_exit "Log Group Name is empty. Ensure the CloudFormation stack is correct and the Log Group exists."
fi

# Run `sam logs` to fetch and tail logs from the CloudWatch Log Group
echo "Fetching and tailing logs from CloudWatch Log Group..."
sam logs --tail --cw-log-group "$LOG_GROUP_NAME" || error_exit "Failed to fetch logs from CloudWatch Log Group."

echo "Logs fetching and tailing completed successfully!"
