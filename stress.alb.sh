## Simple script to "stress" the LB / ASG f
## Use at your own risk
LB_URL=$(make lb-url)
echo $LB_URL
curl $LB_URL
while true;  do curl -s -o /dev/null -w "%{url_effective}, %{response_code}, %{time_total}\n" $LB_URL ; done
