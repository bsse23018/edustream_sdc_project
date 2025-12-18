import boto3
import json
import os
import subprocess
import time

# CONFIGURATION
REGION = 'us-east-1'
QUEUE_URL = 'https://sqs.us-east-1.amazonaws.com/590184044110/EduStream-Transcode-Jobs' # REPLACE THIS LATER
SECRET_NAME = "EduStream/EC2/Credentials"

def get_keys():
    """Securely fetch credentials from Secrets Manager - No Hardcoding!"""
    client = boto3.client('secretsmanager', region_name=REGION)
    resp = client.get_secret_value(SecretId=SECRET_NAME)
    return json.loads(resp['SecretString'])

def process_video(s3_client, bucket, key):
    print(f"🎬 Processing: {key}")
    filename = key.split('/')[-1]
    local_path = f"/tmp/{filename}"
    thumb_path = f"/tmp/{filename}.jpg"

    # 1. Download
    s3_client.download_file(bucket, key, local_path)

    # 2. Extract Thumbnail using FFmpeg (The Heavy Task)
    # This runs a linux command line tool
    subprocess.run([
        'ffmpeg', '-i', local_path,
        '-ss', '00:00:01.000', '-vframes', '1',
        thumb_path, '-y'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 3. Upload Thumbnail
    thumb_key = key.replace('.mp4', '_thumb.jpg')
    s3_client.upload_file(thumb_path, bucket, thumb_key, ExtraArgs={'ACL': 'public-read'})
    print(f"✅ Thumbnail Generated: {thumb_key}")

    # (Future: HLS Transcoding command would go here)

    # Cleanup
    os.remove(local_path)
    os.remove(thumb_path)

def main():
    print("🚀 Worker Daemon Started...")

    # 1. Setup Clients
    creds = get_keys() # FETCHING SECRETS
    sqs = boto3.client('sqs', region_name=REGION,
                       aws_access_key_id=creds['access_key'],
                       aws_secret_access_key=creds['secret_key'],
                       aws_session_token=creds['token'])

    s3 = boto3.client('s3', region_name=REGION,
                      aws_access_key_id=creds['access_key'],
                      aws_secret_access_key=creds['secret_key'],
                      aws_session_token=creds['token'])

    # 2. Infinite Loop (Daemon)
    while True:
        try:
            # Poll SQS
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL, MaxNumberOfMessages=1, WaitTimeSeconds=20
            )

            if 'Messages' in response:
                msg = response['Messages'][0]
                body = json.loads(msg['Body'])

                # S3 Event Structure extraction
                records = body.get('Records', [])
                for rec in records:
                    bucket = rec['s3']['bucket']['name']
                    key = rec['s3']['object']['key']
                    process_video(s3, bucket, key)

                # Delete from Queue (Acknowledge)
                sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg['ReceiptHandle'])

        except Exception as e:
            print(f"❌ Error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()