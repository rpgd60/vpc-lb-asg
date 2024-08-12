.DEFAULT_GOAL ?= help
.PHONY: help

help:
	@echo "${Project}"
	@echo "${Description}"
	@echo ""
	@echo "	iam - deploy iam role for EC2 instances"
	@echo "	vpc - deploy VPC"
	@echo "	del-vpc - delete VPC"
	@echo "	asg - deploy ALB and ASG - requires deploying VPC first"
	@echo "	del-asg - delete ALB and ASG" 
	@echo "	lb-url - show the URL of ALB"	
	@echo "	lb-test - Verify connectivity" 
	@echo "	lb-stress - attempt to trigger autoscaling" 


###################### Parameters ######################
Description ?= VPC and ASG with ALB
# CFN Stack Parameters
AppName ?= app3
Project ?= p33
Environment ?= dev
LocalAWSRegion ?= eu-south-2 ## eu-west-1

## Web server AMI
## Ubuntu 22.04 arm with nginx in eu-south-2 (Spain)
## Generated by ImageBuilder 
WebAmiId ?= ami-0ba8e6418b9af878a
ServerAmiId ?= ${WebAmiId}
WebInstanceType ?= t4g.micro
ServerInstanceType ?= $(WebInstanceType)
# VPC Parameters
CreateNatGateways ?= false
CreateBastion ?= false
VpcCIDR ?= "10.200.0.0/16"

## Stack Names - we get stack name from Project
IamStackName ?= ${Project}-${Environment}-iam
VpcStackName ?= ${Project}-${Environment}-vpc
VpcEndpointStackName ?= ${Project}-${Environment}-vpce
AsgAlbStackName ?= ${Project}-${Environment}-asg-alb
AsgNlbStackName ?= ${Project}-${Environment}-asg-nlb
TestStackName ?= ${Project}-${Environment}-test-ec2
BastionKeyName ?= demo-${LocalAWSRegion}
TargetAutoScaling ?= "false"
## S3FullPath ?= "s3://rp-demo1/aws/autoscaling/fulldemo"
S3FullPath ?= "s3://demos-2023-rp/cfn/autoscaling"
Profile ?= rafaadmin

#######################################################
all:  iam vpc vpc-endpoints asg

iam:
	aws cloudformation deploy \
		--template-file ./iam.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${IamStackName} \
		--parameter-overrides \
			Project=${Project} \
			Environment=${Environment} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

vpc:
	aws cloudformation deploy \
		--template-file ./vpc.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${VpcStackName} \
		--parameter-overrides \
			Project=${Project} \
			Environment=${Environment} \
			CreateNatGateways=${CreateNatGateways} \
			CreateBastion=${CreateBastion} \
			VpcCIDR=${VpcCIDR} \
			BastionKeyName=${BastionKeyName} \
		--no-fail-on-empty-changeset \
		--profile ${Profile} \
		--region ${LocalAWSRegion}


vpc-endpoints: 
	aws cloudformation deploy \
		--template-file ./vpc-endpoints.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${VpcEndpointStackName} \
		--parameter-overrides \
			AppName=${AppName} \
			Project=${Project} \
			Environment=${Environment} \
			VpcStackName=${VpcStackName} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

asg-alb:
	aws cloudformation deploy \
		--template-file ./asg-alb.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${AsgAlbStackName} \
		--parameter-overrides \
			AppName=${AppName} \
			Project=${Project} \
			Environment=${Environment} \
			VpcStackName=${VpcStackName} \
			TargetAutoScaling=${TargetAutoScaling} \
			WebAmiId=${WebAmiId} \
			WebInstanceType=${WebInstanceType} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

asg-nlb:
	aws cloudformation deploy \
		--template-file ./asg-nlb.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${AsgNlbStackName} \
		--parameter-overrides \
			AppName=${AppName} \
			Project=${Project} \
			Environment=${Environment} \
			VpcStackName=${VpcStackName} \
			TargetAutoScaling=${TargetAutoScaling} \
			WebAmiId=${WebAmiId} \
			WebInstanceType=${WebInstanceType} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}
test-ec2:
	aws cloudformation deploy \
		--template-file ./instance.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${TestStackName} \
		--parameter-overrides \
			AppName=${AppName} \
			Project=${Project}\
			Environment=${Environment} \
			VpcStackName=${VpcStackName} \
			IamStackName=${IamStackName} \
			ServerAmiId=${ServerAmiId} \
			ServerInstanceType=${ServerInstanceType} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

lb-url:
	@aws cloudformation describe-stacks --stack-name ${AsgLbStackName} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' --output text  --profile ${Profile} --region ${LocalAWSRegion}

lb-test:
	@LB_URL=$$(aws cloudformation describe-stacks --stack-name ${AsgLbStackName} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' --output text --profile ${Profile} --region ${LocalAWSRegion}) && \
	echo "Load Balancer URL: $$LB_URL" && \
	while sleep 0.5; do \
		curl -s -o /dev/null -w "%{url_effective}, %{response_code}, %{time_total}\n" $$LB_URL; \
	done
lb-stress:
	@LB_URL=$$(aws cloudformation describe-stacks --stack-name ${AsgLbStackName} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' --output text --profile ${Profile} --region ${LocalAWSRegion}) && \
	echo "Load Balancer URL: $$LB_URL" && \
	ab -n 100 -c 1 $$LB_URL

del-iam:
	@read -p "Are you sure that you want to destroy stack '${IamStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${IamStackName}" --profile ${Profile}

del-vpc:
	@read -p "Are you sure that you want to destroy stack '${VpcStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${VpcStackName}" --profile ${Profile}


del-vpc-endpoints:
	@read -p "Are you sure that you want to destroy stack '${VpcEndpointStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${VpcEndpointStackName}" --profile ${Profile}

del-test:
	@read -p "Are you sure that you want to destroy stack '${TestStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${TestStackName}" --profile ${Profile}

del-asg-alb:
	@read -p "Are you sure that you want to destroy stack '${AsgLbStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${AsgLbStackName}" --profile ${Profile}

s3:
	aws s3 rm  ${S3FullPath}/ --recursive --profile ${Profile}
	@aws s3 cp iam.yaml ${S3FullPath}/iam.yaml --profile ${Profile}
	@aws s3 cp vpc.yaml ${S3FullPath}/vpc.yaml --profile ${Profile}
	@aws s3 cp vpc-endpoints.yaml ${S3FullPath}/vpc-endpoints.yaml --profile ${Profile}
	@aws s3 cp instance.yaml ${S3FullPath}/instance.yaml --profile ${Profile}
	@aws s3 cp asg-alb.yaml ${S3FullPath}/asg-alb.yaml --profile ${Profile}
	@aws s3 cp asg-nlb.yaml ${S3FullPath}/asg-nlb.yaml --profile ${Profile}	
	@aws s3 cp Makefile ${S3FullPath}/Makefile --profile ${Profile}
	@aws s3 ls ${S3FullPath}/ --profile ${Profile}

tear-down:
## Attempt to remove all in one shot -  NEEDS work - Always verify that stuff was deleted
## Useful to launch and go for a coffee
	@read -p "Are you sure that you want to destroy all stacks from project '${Project}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${VpcEndpointStackName}" --profile ${Profile}
	sleep 60
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${AsgLbStackName}" --profile ${Profile}
	sleep 300
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${VpcStackName}" --profile ${Profile}


clean:
	@echo Not much to do for the time being
	find . -name '.DS_Store' -exec rm -fr {} +
#	@rm -fr temp/
#	@rm -fr htmlcov/
#	@rm -fr dist/
#	@rm -fr site/
#	@rm -fr .eggs/
#	@rm -fr .tox/
#	@find . -name '*.egg-info' -exec rm -fr {} +
#	@find . -name '.DS_Store' -exec rm -fr {} +
#	@find . -name '*.egg' -exec rm -f {} +
#	@find . -name '*.pyc' -exec rm -f {} +
#	@find . -name '*.pyo' -exec rm -f {} +
#	@find . -name '*~' -exec rm -f {} +
#	@find . -name '__pycache__' -exec rm -fr {} +
