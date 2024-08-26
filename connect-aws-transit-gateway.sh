#!/usr/bin/env bash

set -o errexit # Exit on error. Append "|| true" if you expect an error.
set -o errtrace # Exit on error inside any functions or subshells.
set -o nounset # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
#set -o xtrace

cd "$(dirname "$0")"

# Set right permission to private key (for key par)
chmod 0400 transit-gateway-key-pair.pem

# Looking for the public IP of the Bastion Host in the AWS console
BASTION_HOST=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Bastion" --query "Reservations[].Instances[].PublicIpAddress[]" --output text)

# Looking for the private IP of the App instances in the AWS console
APP1_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name, Values=App1VM" --query "Reservations[].Instances[].PrivateIpAddress[]" --output text)
APP2_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name, Values=App2VM" --query "Reservations[].Instances[].PrivateIpAddress[]" --output text)

# Copy private key to Bastion Host
scp -i "transit-gateway-key-pair.pem" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "transit-gateway-key-pair.pem" \
  "ec2-user@${BASTION_HOST}:/home/ec2-user/transit-gateway-key-pair.pem" || true # Ignore error if file already exists

# Connect to Bastion Host and execute commands (connect to private instance, test nat routing)
ssh -i "transit-gateway-key-pair.pem" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "ec2-user@${BASTION_HOST}" << EOF
    echo "Connecting to App1... (${APP1_PRIVATE_IP})" && \
    ssh -i /home/ec2-user/transit-gateway-key-pair.pem \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      "ec2-user@${APP1_PRIVATE_IP}" \
      "echo \"Hello from App1!\"; id; uname -a; curl -sL checkip.amazonaws.com" && \
    sleep 5 && \
    echo "Connecting to App2... (${APP2_PRIVATE_IP})" && \
    ssh -i /home/ec2-user/transit-gateway-key-pair.pem \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      "ec2-user@${APP2_PRIVATE_IP}" \
      "echo \"Hello from App2!\"; id; uname -a; curl -sL checkip.amazonaws.com"
EOF

echo "Connection to Bastion Host closed"
