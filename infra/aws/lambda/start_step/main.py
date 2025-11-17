import boto3
import json
import os

sfn_client = boto3.client('stepfunctions')

ignore_events = [
    "output/",
    "music/"
]

def lambda_handler(event, context):
    bucket = event['detail']['bucket']['name']
    key = event['detail']['object']['key']

    # Ignore output and music folders
    if any(key.startswith(dir) for dir in ignore_events):
        print(f"Ignoring excluded path: {key}")
        return {'statusCode': 200, 'message': 'Ignored'}
    
    # Extract job ID from key structure: user@email.com/job-id/timestamp-filename
    parts = key.split('/')
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