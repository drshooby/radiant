import boto3
import json
import os
from datetime import datetime, timezone

client = boto3.client('stepfunctions')

def build_api_rsp(output, status):
    return {
        "statusCode": status,
        "headers": {
            "Access-Control-Allow-Origin": "https://brutus.ettukube.com",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "POST"
        },
        "body": json.dumps(output)
    }

def lambda_handler(event, context):
    try:
        # Parse job ID from request
        if 'body' in event:
            body = json.loads(event['body'])
            job_id = body.get('jobId')
        else:
            job_id = event.get('jobId')
        
        print(f"Received job_id: {job_id}")
        
        if not job_id:
            return build_api_rsp({'error': 'jobId is required'}, 400)
        
        # Construct execution ARN
        state_machine_arn = os.environ.get('STATE_MACHINE_ARN')
        print(f"State machine ARN: {state_machine_arn}")
        
        if not state_machine_arn:
            raise ValueError("STATE_MACHINE_ARN environment variable not set")
        
        execution_arn = f'{state_machine_arn.replace(":stateMachine:", ":execution:")}:job-{job_id}'
        print(f"Looking for execution ARN: {execution_arn}")
        
        # Get execution status
        response = client.describe_execution(executionArn=execution_arn)
        
        status = response['status']
        is_complete = status in ['SUCCEEDED', 'FAILED', 'TIMED_OUT', 'ABORTED']
        
        result = {
            'jobId': job_id,
            'status': status,
            'isComplete': is_complete,
            'startDate': response['startDate'].isoformat()
        }
        
        # Add completion details
        if is_complete:
            result['stopDate'] = response.get('stopDate').isoformat()
            
            if status == 'SUCCEEDED':
                result['output'] = response.get('output')
            elif status == 'FAILED':
                result['error'] = response.get('error')
                result['cause'] = response.get('cause')
        
        return build_api_rsp(result, 200)
        
    except client.exceptions.ExecutionDoesNotExist:
        print(f"Execution not found for job_id: {job_id}")
        return build_api_rsp({
                'jobId': job_id,
                'status': 'PENDING_REDRIVE',
                'isComplete': False,
                'found': False,
                'startDate': datetime.now(timezone.utc).isoformat(),
                'message': 'Execution not started yet'
            }, 202)
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return build_api_rsp({
                'error': str(e),
                'type': type(e).__name__
            }, 500)