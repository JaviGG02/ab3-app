#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Patching metrics-server deployment...${NC}"

# Wait for metrics-server deployment to be available
echo -e "${GREEN}Waiting for metrics-server deployment to be available...${NC}"
ATTEMPTS=0
MAX_ATTEMPTS=30

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  if kubectl get deployment metrics-server -n kube-system &>/dev/null; then
    echo -e "${GREEN}metrics-server deployment found. Proceeding with patch...${NC}"
    break
  else
    echo -e "${YELLOW}metrics-server deployment not found yet. Waiting...${NC}"
    ATTEMPTS=$((ATTEMPTS+1))
    sleep 10
  fi
  
  if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}Timed out waiting for metrics-server deployment.${NC}"
    exit 1
  fi
done

# Apply the patch to metrics-server
echo -e "${GREEN}Applying patch to metrics-server...${NC}"
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
{
  "op": "add",
  "path": "/spec/template/spec/hostNetwork",
  "value": true
},
{
  "op": "replace",
  "path": "/spec/template/spec/containers/0/args",
  "value": [
    "--cert-dir=/tmp",
    "--secure-port=4443",
    "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
    "--kubelet-use-node-status-port",
    "--metric-resolution=15s",
    "--kubelet-insecure-tls"
  ]
},
{
  "op": "replace",
  "path": "/spec/template/spec/containers/0/ports/0/containerPort",
  "value": 4443
}
]'

echo -e "${GREEN}Patch applied successfully!${NC}"
echo -e "${YELLOW}Waiting for metrics-server to restart...${NC}"
sleep 10

# Check the status of the metrics-server
echo -e "${GREEN}Checking metrics-server status:${NC}"
kubectl get deployment metrics-server -n kube-system

echo -e "${GREEN}Patch completed. The metrics-server should now be functioning correctly.${NC}"
