#!/bin/bash

echo "Creating Lambda Function"

aws lambda create-function --function-name image-resizer --region us-east-1 --runtime python3.7 --role arn:aws:iam::arn:aws:lambda:us-east-1:488599217855 --timeout 300 --memory-size 512 --handler lambda_function.lambda_handler --code S3Bucket="bckt-image",S3Key="code.zip",S3ObjectVersion="Latest Version"


echo "Getting ARN for the lambda function"

arn=$(aws lambda get-function-configuration --function-name image-resizer --region us-east-1 --query '{FunctionArn:FunctionArn}' --output text)
echo $arn
#arn:aws:lambda:us-east-1:488599217855:function:image-resizer
echo "Adding events json file for S3 trigger"


echo "Lambda function created..\nAdding Permissions"
aws lambda add-permission \
--function-name image-resizer \
--region "us-east-1" \
--statement-id "1" \
--action "lambda:InvokeFunction" \
--principal s3.amazonaws.com \
--source-arn arn:aws:s3:::bckt-image 
#{
#    "Statement": "{\"Sid\":\"1\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"s3.amazonaws.com\"},\"Action\":\"lambda:InvokeFunction\",
#\"Resource\":\"arn:aws:lambda:us-east-1:488599217855:function:image-resizer\",\"Condition\":{\"ArnLike\":{\"AWS:SourceArn\":
#\"arn:aws:s3:::bckt-image\"}}}"
#}


echo "{
  \"LambdaFunctionConfigurations\": [
    {
      \"LambdaFunctionArn\":"\""$arn"\"",
      \"Events\": [\"s3:ObjectCreated:*\"]
    }]}" > events.json


echo "Permission added\nAdding S3 trigger..."
aws s3api put-bucket-notification-configuration \
--bucket bckt-image \
--notification-configuration file://events.json



