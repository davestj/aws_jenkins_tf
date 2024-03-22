# lambda_function.py

import boto3

def lambda_handler(event, context):
    # Extract the new certificate ARN from the event
    new_certificate_arn = event['detail']['requestParameters']['certificateArn']
    
    # Get the listener ARN from environment variables
    listener_arn = os.environ['LISTENER_ARN']
    
    # Update the listener with the new certificate
    elbv2_client = boto3.client('elbv2')
    response = elbv2_client.modify_listener(
        ListenerArn=listener_arn,
        Certificates=[
            {
                'CertificateArn': new_certificate_arn,
            },
        ],
    )
    
    return {
        'statusCode': 200,
        'body': 'SSL certificate updated successfully.'
    }

