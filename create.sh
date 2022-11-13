aws cloudformation create-stack --stack-name vpc$1  --template-body file://rp-vpc.yaml \
 --parameters ParameterKey=EnvironmentName,ParameterValue=vpc$1 \
 ParameterKey=VpcCIDR,ParameterValue=10.$1.0.0/16 \
 ParameterKey=CreateNatGateways,ParameterValue=true \
 ParameterKey=SingleNatGateway,ParameterValue=true \
 ParameterKey=CreateSSMVPCEndpoints,ParameterValue=false \
 ParameterKey=CreateALBandASG,ParameterValue=true \
 ParameterKey=CreateBastion,ParameterValue=true 