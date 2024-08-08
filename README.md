# OneOff

Quickly run a long-running python program in a fargate task untill it completes.

Makes it easy to run long-running python programs that does something that you can't have running on your local computer.

## Prerequisites

- Active AWS credentials in your environment.
- AWS SAM installed.

## Instructions

- Update CPU and memory in the parameter section of `template.yaml` to suit your needs

- Deploy infra

  `sam build && sam deploy`

  Deploys the necessary infrastructure, like network, ECS cluster etc.

- Add execute permissions for build script

  `sudo chmod +x build-and-run.sh`

- Edit the python scipt in `container/main.py` to suit your needs

- Build container and register with ECR, and run the task

  `./build-and-run.sh`

- Add execute permissions for the get-logs script

  `sudo chmod +x get-logs.sh`

- Tail the logs of the container

  `./get-logs.sh`

> [!WARNING]  
> The IAM role created for the task contains admin permissions. You probably want to update the role in the cloudformation template to scope permissions.
