## Simple script to test the LB / ASG 
LB_URL=$(make lb-url)
echo $LB_URL
curl $LB_URL
while sleep 1;  do curl -s -o /dev/null -w "%{url_effective}, %{response_code}, %{time_total}\n" $LB_URL ; done
