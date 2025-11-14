import boto3

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = event['detail']['bucket']['name']
    object_key = event['detail']['object']['key']
    
    # Get the metadata
    response = s3_client.head_object(
        Bucket=bucket_name,
        Key=object_key
    )
    
    user_email = response['Metadata']['user-email']
    
    print(f"Email: {user_email}")
    print(f"Bucket: {bucket_name}")
    print(f"Key: {object_key}")

    return {
        'statusCode': 200,
        'body': 'Seen successfully'
    }