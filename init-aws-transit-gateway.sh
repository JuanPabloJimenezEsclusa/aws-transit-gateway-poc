#!/usr/bin/env bash

set -o errexit # Exit on error. Append "|| true" if you expect an error.
set -o errtrace # Exit on error inside any functions or subshells.
set -o nounset # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o xtrace

cd "$(dirname "$0")"

TG_STACK_NAME="transit-gateway-stack"
EC2_STACK_NAME="transitgateway-test-ec2"

# Create transit gateway stack
aws cloudformation create-stack \
  --stack-name "${TG_STACK_NAME}" \
  --template-body "file://transitgateway-egress-solution.yml" \
  --capabilities CAPABILITY_NAMED_IAM || true # Ignore errors if stack already exists

# Wait for stack to be created
time aws cloudformation wait stack-create-complete \
  --stack-name "${TG_STACK_NAME}"

# Get required stack outputs
HOST_PUBLIC_IP="$(curl -sL checkip.amazonaws.com)/32"

EGRESS_VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name "${TG_STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='EgressVPCId'].OutputValue" \
  --output text)
APP1_VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name "${TG_STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='App1VPCId'].OutputValue" \
  --output text)
APP2_VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name "${TG_STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='App2VPCId'].OutputValue" \
  --output text)
EGRESS_SUBNET_ID=$(aws cloudformation describe-stacks \
  --stack-name "${TG_STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='PublicEgressSubnet1Id'].OutputValue" \
  --output text)
APP1_SUBNET_ID=$(aws cloudformation describe-stacks \
  --stack-name "${TG_STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='PrivateApp1Subnet1Id'].OutputValue" \
  --output text)
APP2_SUBNET_ID=$(aws cloudformation describe-stacks \
  --stack-name "${TG_STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='PrivateApp2Subnet1Id'].OutputValue" \
  --output text)

# Create ec2 test stack
aws cloudformation create-stack \
  --stack-name "${EC2_STACK_NAME}" \
  --template-body "file://transitgateway-test-ec2.yml" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    "ParameterKey=SSHAccessCIDR,ParameterValue=${HOST_PUBLIC_IP}" \
    "ParameterKey=BastionVPCId,ParameterValue=${EGRESS_VPC_ID}" \
    "ParameterKey=App1VPCId,ParameterValue=${APP1_VPC_ID}" \
    "ParameterKey=App2VPCId,ParameterValue=${APP2_VPC_ID}" \
    "ParameterKey=BastionPublicSubnetId,ParameterValue=${EGRESS_SUBNET_ID}" \
    "ParameterKey=App1PrivateSubnetId,ParameterValue=${APP1_SUBNET_ID}" \
    "ParameterKey=App2PrivateSubnetId,ParameterValue=${APP2_SUBNET_ID}" || true # Ignore errors if stack already exists

# Wait for stack to be created
time aws cloudformation wait stack-create-complete \
  --stack-name "${EC2_STACK_NAME}"
