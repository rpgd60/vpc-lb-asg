.DEFAULT_GOAL ?= help
.PHONY: help

help:
	@echo "${Project}"
	@echo "${Description}"
	@echo ""
	@echo "	deploy - deploy VPC LB and ASG Group"
	@echo "	---"
	@echo "	tear-down - destroy CloudFormation stacks"
	@echo "	clean - clean temp folders"

###################### Parameters ######################
Description ?= VPC and ASG with LB
# CFN Stack Parameters
AppName ?= acctg
Project ?= acme
Environment ?= dev
CreateNatGateways ?= true
CreateBastion ?= false
NetworkStackName ?= base-network
AsgLbStackName ?= asg-lb-demo
VpcCIDR ?= "10.200.0.0/16"

LocalAWSRegion ?= eu-west-1
Profile ?= course

#######################################################

vpc:
	aws cloudformation deploy \
		--template-file ./vpc.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${NetworkStackName} \
		--parameter-overrides \
			Project=${Project} \
			Environment=${Environment} \
			CreateNatGateways=${CreateNatGateways} \
			CreateBastion=${CreateBastion} \
			VpcCIDR=${VpcCIDR} \
		--no-fail-on-empty-changeset \
		--profile ${Profile}

asg:
	aws cloudformation deploy \
		--template-file ./asg-lb.yaml \
		--region ${LocalAWSRegion} \
		--stack-name ${AsgLbStackName} \
		--parameter-overrides \
			AppName=${AppName} \
			Project=${Project} \
			Environment=${Environment} \
			NetworkStackName=${NetworkStackName} \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile ${Profile}

del-vpc:
	@read -p "Are you sure that you want to destroy stack '${NetworkStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${NetworkStackName}" --profile ${Profile}
del-asg:
	@read -p "Are you sure that you want to destroy stack '${AsgLbStackName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${AsgLbStackName}" --profile ${Profile}

# tear-down:
# 	@read -p "Are you sure that you want to destroy stack '${Project}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
# 	aws cloudformation delete-stack --region ${LocalAWSRegion} --stack-name "${Project}-vpc" --profile ${Profile}

clean:
	@rm -fr temp/
	@rm -fr dist/
	@rm -fr htmlcov/
	@rm -fr site/
	@rm -fr .eggs/
	@rm -fr .tox/
	@find . -name '*.egg-info' -exec rm -fr {} +
	@find . -name '.DS_Store' -exec rm -fr {} +
	@find . -name '*.egg' -exec rm -f {} +
	@find . -name '*.pyc' -exec rm -f {} +
	@find . -name '*.pyo' -exec rm -f {} +
	@find . -name '*~' -exec rm -f {} +
	@find . -name '__pycache__' -exec rm -fr {} +
