#!/usr/bin/env bash

set -o errexit # Exit on error. Append "|| true" if you expect an error.
set -o errtrace # Exit on error inside any functions or subshells.
set -o nounset # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o xtrace

cd "$(dirname "$0")"

TG_STACK_NAME="transit-gateway-stack"
EC2_STACK_NAME="transitgateway-test-ec2"

# Delete test EC2 stack
aws cloudformation delete-stack \
  --no-cli-auto-prompt \
  --no-cli-pager \
  --stack-name "${EC2_STACK_NAME}"

# Wait for EC2 stack to be deleted
time aws cloudformation wait stack-delete-complete \
  --stack-name "${EC2_STACK_NAME}"

# Delete transit gateway stack
aws cloudformation delete-stack \
  --no-cli-auto-prompt \
  --no-cli-pager \
  --stack-name "${TG_STACK_NAME}"

# Wait for transit gateway stack to be deleted
time aws cloudformation wait stack-delete-complete \
  --stack-name "${TG_STACK_NAME}"
