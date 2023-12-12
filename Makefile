.DEFAULT_GOAL ?= help
.PHONY: help

help:
	@echo "${Project}"
	@echo "${Description}"
	@echo ""
	@echo "	vpc - deploy VPC"
	@echo "	del-vpc - delete VPC"
	@echo "	asg - deploy ALB and ASG - requires deploying VPC first"
	@echo "	lb-url - show the URL of ALB"
	@echo "	del-asg - delete ALB and ASG" 
	@echo "	test-lb - Verify connectivity" 
	@echo "	stress-lb - attempt to trigger autoscaling" 


###################### Parameters ######################
Description ?= VPC and ASG with LB
# CFN Stack Parameters
AppName ?= app3
Project ?= pluto
Environment ?= dev
# VPC Parameters
CreateNatGateways ?= false
CreateBastion ?= false
VpcCIDR ?= "10.200.0.0/16"

## Stack Names - we get stack name from Project
IamStackName ?= ${Project}-${Environment}-iam
VpcStackName ?= ${Project}-${Environment}-vpc
VpcEndpointStackName ?= ${Project}-${Environment}-vpce
AsgLbStackName ?= ${Project}-${Environment}-asg
TestStackName ?= ${Project}-${Environment}-test-ec2



TargetAutoScaling ?= "true"
## S3FullPath ?= "s3://rp-demo1/aws/autoscaling/fulldemo"
S3FullPath ?= "s3://demos-2023-rp/cfn/autoscaling"
LocalAWSRegion ?= eu-south-2 ## eu-west-1
Profile ?= madmin

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
			VpcStackName=${VpcStackName}\
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

asg:
	aws cloudformation deploy \
		--template-file ./asg-lb.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${AsgLbStackName} \
		--parameter-overrides \
			AppName=${AppName} \
			Project=${Project} \
			Environment=${Environment} \
			VpcStackName=${VpcStackName} \
			TargetAutoScaling=${TargetAutoScaling} \
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
			VpcStackName=${VpcStackName}\
			IamStackName=${IamStackName}\
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile} \
		--region ${LocalAWSRegion}

lb-url:
	@aws cloudformation describe-stacks --stack-name ${AsgLbStackName} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' --output text  --profile ${Profile} --region ${LocalAWSRegion}

test-lb:
	@echo "Run command:  bash ./test.alb.sh <project-name> <environment>"

stress-lb:
	@echo "Run command:  bash ./stress.alb.sh <project-name> <environment>"

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

del-asg:
	@read -p "Are you sure that you want to destroy stack '${AsgLbStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${AsgLbStackName}" --profile ${Profile}

s3:
	@aws s3 cp iam.yaml ${S3FullPath}/iam.yaml --profile ${Profile}
	@aws s3 cp vpc.yaml ${S3FullPath}/vpc.yaml --profile ${Profile}
	@aws s3 cp vpc.yaml ${S3FullPath}/test-instance.yaml --profile ${Profile}
	@aws s3 cp asg-lb.yaml ${S3FullPath}/asg-lb.yaml --profile ${Profile}
	@aws s3 cp asg-lb.yaml ${S3FullPath}/vpc-endpoints.yaml --profile ${Profile}
	@aws s3 cp Makefile ${S3FullPath}/Makefile --profile ${Profile}

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
