#!/bin/bash

# Run in AWS CLI

# Database credentials
DB_NAME="ab3db"
DB_USERNAME="admin"
DB_PASSWORD="EksAurora1!"

# Create JSON payload
SECRET_JSON=$(jq -n \
  --arg username "$DB_USERNAME" \
  --arg password "$DB_PASSWORD" \
  --arg dbname "$DB_NAME" \
  '{username: $username, password: $password, dbname: $dbname}')

# Try to create the secret
CREATE_RESULT=$(aws secretsmanager create-secret \
  --name "ab3/aurora/credentials" \
  --description "Aurora MySQL database credentials" \
  --secret-string "$SECRET_JSON" 2>&1)

# Check if the secret already exists
if echo "$CREATE_RESULT" | grep -q "ResourceExistsException"; then
  aws secretsmanager update-secret \
    --secret-id "ab3/aurora/credentials" \
    --secret-string "$SECRET_JSON"
  echo "Database credentials updated in AWS Secrets Manager"
else
  echo "Database credentials uploaded to AWS Secrets Manager"
fi
