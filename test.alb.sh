## Simple script to test the LB / ASG 
## Must use the project name as parameter to this script
## TODO: enforce parameter

LB_URL=$(make Project=$1 Environment=$2 lb-url)
echo $LB_URL
curl $LB_URL
while sleep 1;  do curl -s -o /dev/null -w "%{url_effective}, %{response_code}, %{time_total}\n" $LB_URL ; done
