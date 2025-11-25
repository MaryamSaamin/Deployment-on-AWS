# flask-cdk

Simple Flask web app deployed to AWS using AWS CDK (Python) and ECS Fargate.

## Table of contents
- [Overview](#overview)
- [Repository structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Setup (local dev)](#setup-local-dev)
- [Stack File)](#Rewrite--stack-file)
- [Deploy to AWS (CDK)](#deploy-to-aws-cdk)
- [Destroy / Cleanup](#destroy--cleanup)


## Overview
This repository contains a minimal Flask application and an AWS CDK stack that:
- Builds an ECS Fargate service (container from ECR)
- Creates a load balancer URL to reach the Flask app

The goal is to be simple and reproducible.

## Repository structure
flask-cdk/
├── app.py
├── requirements.txt
└── flask_cdk/
└── flask_cdk_stack.py

## Prerequisites
- AWS account with permissions to create VPC, ECS, ECR, IAM, ALB, CloudFormation
- AWS CLI installed and configured (`aws configure`) OR use environment variables / profiles
- Python 3.8+ and `python3-venv`
- AWS CDK CLI (`npm install -g aws-cdk`)


## Setup (local dev)

#1. Create a new folder and CDK project  or run deploy.sh

```bash
mkdir flask-cdk
cd flask-cdk
cdk init app --language python

#2. Set up Python environment  
python3 -m venv .env
source .env/bin/activate

#3. Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install "aws-cdk-lib>=2.0.0" "constructs>=10.0.0,<11.0.0"

#4. Replace the stack file contents
from aws_cdk import ( 
    Stack,
    aws_ec2 as ec2,
    aws_ecs as ecs,
    aws_ecs_patterns as ecs_patterns,
    aws_iam as iam,
    CfnOutput,
)
from constructs import Construct


class FlaskCdkStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Create a new VPC
        vpc = ec2.Vpc(self, "FlaskVpc", max_azs=2)

        # Create ECS Cluster
        cluster = ecs.Cluster(self, "FlaskCluster", vpc=vpc)

        # Create ECS Task Execution Role with proper permissions
        execution_role = iam.Role(
            self, "FlaskTaskExecutionRole",
            assumed_by=iam.ServicePrincipal("ecs-tasks.amazonaws.com")
        )
        execution_role.add_managed_policy(
            iam.ManagedPolicy.from_aws_managed_policy_name(
                "service-role/AmazonECSTaskExecutionRolePolicy"
            )
        )

        # Create Fargate service behind a Load Balancer
        flask_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self,
            "FlaskService",
            cluster=cluster,
            cpu=256,
            memory_limit_mib=512,
            desired_count=1,
            public_load_balancer=True,
            task_image_options=ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
                image=ecs.ContainerImage.from_registry(
                    "593970662859.dkr.ecr.eu-north-1.amazonaws.com/mathapp-repo:latest"
                ),
                container_port=5000,
                execution_role=execution_role  # <-- assign role here
            ),
        )

        # Output Load Balancer DNS
        CfnOutput(self, "LoadBalancerURL",
            value=f"http://{flask_service.load_balancer.load_balancer_dns_name}"
        )

#Deploy to AWS
#1.Bootstrap CDK environment
cdk bootstrap
#2.Deploy
cdk deploy
#3.After successful deploy, CDK will output the load balancer URL.
http://flaskc-flask-z8eexsen5plw-1078562451.eu-north-1.elb.amazonaws.com/

#Destroy / Cleanup  or run destroy.sh
cdk destroy
# or non-interactive:
cdk destroy --force
# Delete Docker image
aws ecr batch-delete-image --repository-name mathapp-repo --image-ids imageTag=latest




