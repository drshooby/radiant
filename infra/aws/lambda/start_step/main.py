import boto3
import json
import os

sfn_client = boto3.client('stepfunctions')

ignore_dirs = [
    "output",
    "music"
]

def lambda_handler(event, context):
    bucket = event['detail']['bucket']['name']
    key = event['detail']['object']['key']

    print("Bucket:", bucket)
    print("Key:", key)

    # Split the key to check path parts
    parts = key.split('/')
    
    # Ignore if any path part matches ignored directories
    if any(part in ignore_dirs for part in parts):
        print(f"Ignoring event for key containing ignored directory: {key}")
        return {
            'statusCode': 200,
            'body': json.dumps('Ignored')
        }
    
    # Now safe to extract job ID
    if len(parts) < 2:
        raise ValueError(f"Invalid S3 key format: {key}")
    
    job_id = parts[1]
    
    state_machine_arn = os.environ['STATE_MACHINE_ARN']
    model_arn = os.environ['REKOGNITION_MODEL_ARN']
    
    # Start Step Function with job ID as execution name
    response = sfn_client.start_execution(
        stateMachineArn=state_machine_arn,
        name=f'job-{job_id}',
        input=json.dumps({
            'bucket': bucket,
            'videoKey': key,
            'jobId': job_id,
            'modelArn': model_arn
        })
    )
    
    return {
        'statusCode': 200,
        'executionArn': response['executionArn']
    }