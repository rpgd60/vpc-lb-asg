Collection of linked stacks to create an AWS VPC and an ALB with an ASG with a basic Web Server Launch Template

Disclaimer:  Not for production - use at your own risk

Uses Makefile to launch AWS CLI cloudformation commands

At the moment only the vpc.yaml template has been tested more or less thoroughly
The asg-lb.yaml template is work in progress
The other templates are just very initial tests.


Sample Runs

- Create VPC with default values for parameters
`make vpc` 

- Create VPC overriding some parameters
`make  CreateNatGateways=false  CreateBastion=false vpc`

