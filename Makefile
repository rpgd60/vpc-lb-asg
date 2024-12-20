MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
.DEFAULT_GOAL ?= help
.PHONY: help
help:
	@echo "${Project}"
	@echo "${Description}"
	@echo ""
	@echo "	iam - deploy iam role for EC2 instances"
	@echo "	vpc - deploy VPC"
	@echo "	del-vpc - delete VPC"
	@echo "	asg-alb - deploy ALB and ASG - requires deploying VPC first"
	@echo "	asg-alb2 - deploy 2nd stack with ALB and ASG - requires deploying VPC first"
	@echo "	del-asg-alb - delete stack with ALB and ASG" 
	@echo "	del-asg-alb2 - delete 2nd stack with ALB and ASG" 	
	@echo "	test-ec2 - create instance in vpc (pub subnet)" 	
	@echo "	del-test-ec2 - delete instance in vpc (pub subnet)" 	
	@echo "	lb-url - show the URL of ALB"
	@echo "	lb-test - Verify connectivity" 
	@echo "	lb-stress - attempt to trigger autoscaling" 
	# @echo ${MAKEFILE_DIR}


###################### Parameters ######################
Description ?= VPC and ASG with ALB
# CFN Stack Parameters
AppName ?= app1
AppName2 ?= app2
Project ?= proj1
Project2 ?= proj2
Environment ?= dev
LocalAWSRegion ?= eu-south-1  ## Using eu-south-1 for SSM Application Manager (CloudFormation Library) not available in Spain

## Ubuntu 22.04 arm with nginx in eu-south-2 (Spain)
## Generated by ImageBuilder in eu-west-1, eu-south-1, eu-south-2
## TODO - use parameter store
WebAmiId_eu-west-1 := ami-03cc26ad1361623f2
WebAmiId_eu-south-1 := ami-09539b0b5e65c6b83
WebAmiId_eu-south-2 := ami-03224098792970ca9
# WebAmiId = $(WebAmiId_$(LocalAWSRegion))
WebAmiId = ${WebAmiId_eu-south-1}
ServerAmiId ?= ${WebAmiId}
WebInstanceType ?= t4g.nano
ServerInstanceType ?= $(WebInstanceType)
# VPC Parameters
CreateNatGateways ?= true
VpcCIDR ?= "10.200.0.0/16"

## Stack Names - we get stack name from Project
IamStackName ?= ${Project}-${Environment}-iam
VpcStackName ?= ${Project}-${Environment}-vpc
VpcEndpointStackName ?= ${Project}-${Environment}-vpce
AsgAlbStackName ?= ${Project}-${Environment}-asg-alb
AsgAlbStackName2 ?= ${AsgAlbStackName}-2
AsgNlbStackName ?= ${Project}-${Environment}-asg-nlb
TestStackName ?= ${Project}-${Environment}-test-ec2
TargetAutoScaling ?= "true"
## S3FullPath ?= "s3://rp-demo1/aws/autoscaling/fulldemo"
S3FullPath ?= "s3://demos-rp-eu-south-2/cfn/autoscaling"
Profile ?= sso-madmin

#######################################################
.PHONY: all
all:  iam vpc asg-alb

.PHONY: debug-vars
debug-vars:
	@echo "Region: ${LocalAWSRegion}"
	@echo "Web AMI: ${WebAmiId}"
	@echo "Server AMI: ${ServerAmiId}"
	@echo "Available AMIs:"
	@echo "  eu-west-1:  $(WebAmiId_eu-west-1)"
	@echo "  eu-south-1: $(WebAmiId_eu-south-1)"
	@echo "  eu-south-2: $(WebAmiId_eu-south-2)"
	@echo "VPC CIDR:  ${VpcCIDR}"
	@echo "Create NAT GWs: ${CreateNatGateways}"

.PHONY: iam
iam:
	aws cloudformation deploy \
		--template-file ./iam.yaml \
		--stack-name ${IamStackName} \
		--parameter-overrides \
			Project=${Project} \
			Environment=${Environment} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}
.PHONY: vpc
vpc:
	aws cloudformation deploy \
		--template-file ./vpc.yaml \
		--stack-name ${VpcStackName} \
		--parameter-overrides \
			Project=${Project} \
			Environment=${Environment} \
			CreateNatGateways=${CreateNatGateways} \
			VpcCIDR=${VpcCIDR} \
		--capabilities CAPABILITY_NAMED_IAM \
		--no-fail-on-empty-changeset \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

.PHONY: vpc-endpoints
vpc-endpoints: 
	aws cloudformation deploy \
		--template-file ./vpc-endpoints.yaml \
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

.PHONY: asg-alb
asg-alb:
	aws cloudformation deploy \
		--template-file ./asg-alb.yaml \
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

.PHONY: asg-alb2
asg-alb2:
	aws cloudformation deploy \
		--template-file ./asg-alb.yaml \
		--stack-name ${AsgAlbStackName2} \
		--parameter-overrides \
			AppName=${AppName2} \
			Project=${Project2} \
			Environment=${Environment} \
			VpcStackName=${VpcStackName} \
			TargetAutoScaling=${TargetAutoScaling} \
			WebAmiId=${WebAmiId} \
			WebInstanceType=${WebInstanceType} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

.PHONY: asg-nlb
asg-nlb:
	aws cloudformation deploy \
		--template-file ./asg-nlb.yaml \
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
.PHONY: test-ec2
test-ec2:
	aws cloudformation deploy \
		--template-file ./instance.yaml \
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
.PHONY: alb-url
alb-url:
	@aws cloudformation describe-stacks --stack-name ${AsgAlbStackName} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' --output text  --profile ${Profile} --region ${LocalAWSRegion}
.PHONY: alb-test
alb-test:
	@LB_URL=$$(aws cloudformation describe-stacks --stack-name ${AsgAlbStackName} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' --output text --profile ${Profile} --region ${LocalAWSRegion}) && \
	echo "ALB Balancer URL: $$LB_URL" && \
	while sleep 0.5; do \
		curl -s -o /dev/null -w "%{url_effective}, %{response_code}, %{time_total}\n" $$LB_URL; \
	
.PHONY: alb-stress
alb-stress:
	@LB_URL=$$(aws cloudformation describe-stacks --stack-name ${AsgAlbStackName} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' --output text --profile ${Profile} --region ${LocalAWSRegion}) && \
	echo "ALB Balancer URL: $$LB_URL" && \
	ab -n 100 -c 1 $$LB_URL
.PHONY: del-iam
del-iam:
	@read -p "Are you sure that you want to destroy stack '${IamStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${IamStackName}" --profile ${Profile}

.PHONY: del-vpc
del-vpc:
	@read -p "Are you sure that you want to destroy stack '${VpcStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${VpcStackName}" --profile ${Profile}

.PHONY: del-vpc-endpoints
del-vpc-endpoints:
	@read -p "Are you sure that you want to destroy stack '${VpcEndpointStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${VpcEndpointStackName}" --profile ${Profile}
.PHONY: del-test
del-test-ec2:
	@read -p "Are you sure that you want to destroy stack '${TestStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${TestStackName}" --profile ${Profile}

.PHONY: del-asg-alb
del-asg-alb:
	@read -p "Are you sure that you want to destroy stack '${AsgAlbStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${AsgAlbStackName}" --profile ${Profile}
.PHONY: del-asg-alb2
del-asg-alb2:
	@read -p "Are you sure that you want to destroy stack '${AsgAlbStackName2}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${AsgAlbStackName2}" --profile ${Profile}
.PHONY: del-asg-nlb
del-asg-nlb:
	@read -p "Are you sure that you want to destroy stack '${AsgNlbStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${AsgNlbStackName}" --profile ${Profile}
.PHONY: s3
s3:
	aws s3 rm  ${S3FullPath}/ --recursive --profile ${Profile} --region ${LocalAWSRegion}
	@aws s3 cp iam.yaml ${S3FullPath}/iam.yaml --profile ${Profile} --region ${LocalAWSRegion}
	@aws s3 cp vpc.yaml ${S3FullPath}/vpc.yaml --profile ${Profile} --region ${LocalAWSRegion}
	@aws s3 cp vpc-endpoints.yaml ${S3FullPath}/vpc-endpoints.yaml --profile ${Profile} --region ${LocalAWSRegion}
	@aws s3 cp instance.yaml ${S3FullPath}/instance.yaml --profile ${Profile} --region ${LocalAWSRegion}
	@aws s3 cp asg-alb.yaml ${S3FullPath}/asg-alb.yaml --profile ${Profile}  --region ${LocalAWSRegion}
	@aws s3 cp asg-nlb.yaml ${S3FullPath}/asg-nlb.yaml --profile ${Profile}	 --region ${LocalAWSRegion}
	@aws s3 cp Makefile ${S3FullPath}/Makefile --profile ${Profile} --region ${LocalAWSRegion}
	@aws s3 ls ${S3FullPath}/ --profile ${Profile}  --region ${LocalAWSRegion}
.PHONY: tear-down
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
