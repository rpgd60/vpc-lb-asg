Collection of linked stacks to create an AWS VPC and an ALB with an ASG with a simple Web Server Launch Template

Uses Makefile to launch AWS CLI cloudformation commands


## Disclaimers
- DEFINITELY NOT for production - use at your own risk
- The templates in this repo will create resourses OUTSIDE of the free tier.  You can incur siginificant AWS charges

At the moment only the vpc.yaml template has been tested more or less thoroughly
The asg-lb.yaml template is work in progress
VPC Endpoints are created but do not seem to work at the moment (at leaset for SSM Session Manager)


## Stack Names
Stack Names are based on "Project" and "Environment" names.  
Setting Project to "acme"  and Environment to "dev" will create stacks
- acme-iam-dev
- acme-vpc-dev
- acme-vpce-dev  (vpc endpoints)
- acme-asg-dev



## Example Usage
Normally we include the Project as a parameter when calling make.

- Create VPC with default values for parameters  (stack:  acme-vpc)
`make Project=acme Environment=dev vpc` 

- Create VPC overriding some parameters

`make  Project=acme  Environment=test CreateNatGateways=false  CreateBastion=false vpc`
`make Project=acme44 Environment=dev VpcCIDR="10.44.0.0/16" CreateNatGateways=false vpc`

- Create ASG and ALB  (Stack linked to VPC stack - must be run after creating VPC)

`make Project=acme Environment=dev asg`

- ASG with Target Autoscaling   (use 'false' to disable)

`make Project=acme Environment=dev TargetAutoscaling=true asg`


- Create VPC Endpoints - must be run after creating VPC

`make Project=acme Environment=dev vpc-endpoints`


## Testing and 'stressing' the ALB / ASG

Running `make lb-url` gets the DNS Name associated with the Application Load Balancer
```
$ make Project=acme lb-url
http://dev-alb-3453634523.eu-west-1.elb.amazonaws.com/
```
This is called by two simple bash scripts to test the LB connectivity using curl.

test.alb.sh  -  sends HTTP requests to  the ALB at one second intervals
```
## Simple script to test the LB / ASG 
LB_URL=$(make lb-url)
echo $LB_URL
curl $LB_URL
while sleep 1;  do curl -s -o /dev/null -w "%{url_effective}, %{response_code}, %{time_total}\n" $LB_URL ; done

```

stress.alb.sh - blasts the ALB with a quick succession of HTTP requests.  
Does not really stress the CPU, but it can be used to test a Target Tracking autoscaling policy based on LB requests per target (ALBRequestCountPerTarget)

```
## Simple script to stress the LB / ASG 
LB_URL=$(make lb-url)
echo $LB_URL
curl $LB_URL
while sleep 1;  do curl -s -o /dev/null -w "%{url_effective}, %{response_code}, %{time_total}\n" $LB_URL ; done
```

