aws s3 mb s3://w-source-bucket --region us-east-1
make_bucket: w-source-bucket

aws s3 mb s3://w-destination-bucket --region us-west-1
make_bucket: w-destination-bucket

aws s3api put-bucket-versioning --bucket w-source-bucket --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning --bucket w-destination-bucket --versioning-configuration Status=Enabled

echo "Versioning enabled "

echo "Adding Copy Lambda Code...."

echo "import boto3
import json
import time
s3 = boto3.client('s3')
REGION = 'us-east-1' # region to launch instance.
INSTANCE_TYPE = 't2.micro' # type of instance to launch.
EC2 = boto3.client('ec2', region_name=REGION)
def lambda_handler(event, context):
  \"\"\" Lambda handler taking [message] and creating a http instance with an echo. \"\"\"
  #message = event['message']
  source_bucket = event['Records'][0]['s3']['bucket']['name']
  key = event['Records'][0]['s3']['object']['key']
  #size = event['Records'][0]['s3']['object']['size']
  eventName = event['Records'][0]['eventName']
  print(source_bucket)
  print(key)
  #print(size)
  print(eventName)
  copy_source = {'Bucket':source_bucket, 'Key':key}
  target_bucket = 'w-destination-bucket'
  if eventName == 'ObjectCreated:Put':
    print ("Copying object from Source S3 bucket to Target S3 bucket ")
    s3.copy_object(Bucket=target_bucket, Key=key, CopySource=copy_source)
  if eventName == 'ObjectRemoved:DeleteMarkerCreated':
    s3.delete_object(Bucket=target_bucket, Key=key)
  return \"Hello\"" > copylambda.py

zip myfile.zip copylambda.py


echo "Created zip file and copylambda code"

echo "Creating Lambda Function"

aws lambda create-function --function-name pe-rmm-copylambda \
--runtime python3.6 \
--role arn:aws:iam::488599217855:role/FullAccess \
--handler copylambda.lambda_handler \
--zip-file fileb://myfile.zip \
--timeout 300 \
--region us-east-1
aws lambda create-function --function-name replicate --runtime python3.6 --role arn:aws:iam::488599217855:role/FullAccess --handler replicate.lambda_handler --zip-file fileb://s3-replicate.zip --timeout 300 --region us-east-1

echo "Lambda function created..\nAdding Permissions"

aws lambda add-permission --function-name replicate --region "us-east-1" --statement-id "1" --action "lambda:InvokeFUnction" --principal s3.amazonaws.com --source-arn arn:aws:s3:::w-source-bucket
{
    "Statement": "{\"Sid\":\"1\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"s3.amazonaws.com\"},\"Action\":\"lambda:InvokeFUnction\",\"Resource\":\"arn:aws:lambda:us-east-1:488599217855:function:replicate\",\"Condition\":{\"ArnLike\":{\"AWS:SourceArn\":\"arn:aws:s3:::w-source-bucket\"}}}"
}

echo "Getting ARN for the lambda function"
arn=$(aws lambda get-function-configuration --function-name replicate --region us-east-1 --query '{FunctionArn:FunctionArn}' --output text)
#arn=arn:aws:lambda:us-east-1:488599217855:function:replicate

echo $arn
echo "Adding events json file for S3 trigger"

echo "{
  \"LambdaFunctionConfigurations\": [
    {
      \"LambdaFunctionArn\":"\""$arn"\"",
      \"Events\": [\"s3:ObjectCreated:*\"]
    },
    {
      \"LambdaFunctionArn\":"\""$arn"\"",
      \"Events\": [\"s3:ObjectRemoved:*\"]
    }
  ]
}" > event.json

echo "Permission added\nAdding S3 trigger..."
aws s3api put-bucket-notification-configuration --bucket w-destination-bucket --notification-configuration file://event.json
