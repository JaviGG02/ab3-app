#!/bin/bash
# This script updates the CloudFront distribution with the actual ALB domain name and WAF ACL

# Wait for the ingress to be created and get its hostname
echo "Waiting for ALB to be provisioned (this may take several minutes)..."
ATTEMPTS=0
MAX_ATTEMPTS=30

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  ALB_HOSTNAME=$(kubectl get ingress ui-ingress -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  
  if [ -n "$ALB_HOSTNAME" ]; then
    echo "ALB hostname found: $ALB_HOSTNAME"
    break
  fi
  
  echo "Attempt $((ATTEMPTS+1))/$MAX_ATTEMPTS: ALB not ready yet, waiting 30 seconds..."
  sleep 30
  ATTEMPTS=$((ATTEMPTS+1))
done

if [ -z "$ALB_HOSTNAME" ]; then
  echo "Failed to get ALB hostname after $MAX_ATTEMPTS attempts"
  exit 1
fi

# Get the CloudFront distribution ID
DISTRIBUTION_ID=$(terraform output -raw cloudfront_domain_name | cut -d. -f1)

if [ -z "$DISTRIBUTION_ID" ]; then
  echo "Failed to get CloudFront distribution ID"
  exit 1
fi

# Get the WAF ACL ID
WAF_ACL_ID=$(terraform output -raw waf_acl_arn)

if [ -z "$WAF_ACL_ID" ]; then
  echo "Failed to get WAF ACL ID"
  exit 1
fi

echo "Updating CloudFront distribution $DISTRIBUTION_ID with ALB hostname $ALB_HOSTNAME and WAF ACL $WAF_ACL_ID"

# Get the current CloudFront configuration
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --output json > cf_config.json

# Extract the ETag
ETAG=$(jq -r '.ETag' cf_config.json)

# Update the origin domain name and WAF ACL
jq --arg alb "$ALB_HOSTNAME" --arg waf "$WAF_ACL_ID" '.DistributionConfig.Origins.Items[0].DomainName = $alb | .DistributionConfig.WebACLId = $waf' cf_config.json > cf_config_updated.json

# Remove the ETag from the updated config
jq '.DistributionConfig' cf_config_updated.json > cf_update.json

# Update the CloudFront distribution
aws cloudfront update-distribution --id $DISTRIBUTION_ID --distribution-config file://cf_update.json --if-match "$ETAG"

echo "CloudFront distribution updated successfully. It may take a few minutes to propagate."