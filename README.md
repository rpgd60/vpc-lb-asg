Collection of linked stacks to create an AWS VPC and an ALB with an ASG with a simple Web Server Launch Template

Uses Makefile to launch AWS CLI cloudformation commands


## Disclaimers
- DEFINITELY NOT for production - use at your own risk
- The templates in this repo will create resourses OUTSIDE of the free tier.  You can incur siginificant AWS charges

At the moment only the vpc.yaml template has been tested more or less thoroughly
The asg-lb.yaml template is work in progress
VPC Endpoints are created but do not seem to work at the moment (at leaset for SSM Session Manager)


## Stack Names
Stack Names are based on "Project" name.  Setting project to "acme" will create stacks
- acme-iam
- acme-vpc
- acme-vpce  (vpc endpoints)
- acme-asg 

(
    TODO:  explore including Environment parameter in stack name

    Example  -  Project "acme" and Environment "prod" will create stacks:
        acme-prod-vpc
        acme-prod-asg
        acme-prod-vpce
        ...
)

## Example Usage
Normally we include the Project as a parameter when calling make.

- Create VPC with default values for parameters  (stack:  acme-vpc)
`make Project=acme vpc` 

- Create VPC overriding some parameters
`make  Project=acme CreateNatGateways=false  CreateBastion=false vpc`
`make Project=acme44 VpcCIDR="10.44.0.0/16" CreateNatGateways=false vpc`

- Create ASG and ALB  (Stack linked to VPC stack - must be run after creating VPC)
`make Project=acme asg`
- ASG with Target Autoscaling   (use 'false' to disable)
`make Project=acme TargetAutoscaling=true asg`


- Create VPC Endpoints - must be run after creating VPC
`make Project=acme vpc-endpoints`


## Testing and 'stressing' the ALB / ASG

Running `make lb-url` gets the DNS Name associated with the Application Load Balancer

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

