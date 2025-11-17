import boto3
import subprocess
import glob
import os

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['bucket']
    video_key = event['videoKey']
    email = event['email']
    model_arn = event['modelArn']
    
    print(f"Processing video: {video_key}")
    
    # Download video from S3
    video_file = '/tmp/video.mp4'
    s3.download_file(bucket, video_key, video_file)
        
    # Extract 1 frame per second using ffmpeg
    frames_dir = '/tmp/frames'
    os.makedirs(frames_dir, exist_ok=True)
    
    subprocess.run([
        'ffmpeg', '-i', video_file,
        '-vf', 'fps=1',  # 1 frame per second
        '-q:v', '2',     # High quality JPEG
        f'{frames_dir}/frame_%04d.jpg'
    ], check=True, capture_output=True)
    
    # Get all extracted frames
    frame_files = sorted(glob.glob(f'{frames_dir}/frame_*.jpg'))
    print(f"Extracted {len(frame_files)} frames")
    
    # Process each frame with Rekognition
    kill_timestamps = []
    
    for i, frame_file in enumerate(frame_files):
        print(f"Processing frame {i+1}/{len(frame_files)}")
        
        with open(frame_file, 'rb') as f:
            image_bytes = f.read()
        
        try:
            response = rekognition.detect_custom_labels(
                Image={'Bytes': image_bytes},
                ProjectVersionArn=model_arn,
                MinConfidence=50
            )
            
            # Each frame represents 1 second of video (since we extract at 1fps)
            timestamp_seconds = float(i)
            
            for label in response.get('CustomLabels', []):
                if label['Name'].lower() == 'kill':
                    kill_timestamps.append({
                        'time': timestamp_seconds,
                        'confidence': label['Confidence']
                    })
        
        except rekognition.exceptions.ResourceNotReadyException as e:
            raise RuntimeError("Model is not ready. Failing Lambda so Step Functions can retry or stop.") from e

        except Exception as e:
            print(f"  Error processing frame {i}: {e}")
    
    # Cleanup
    os.unlink(video_file)
    for frame_file in frame_files:
        os.unlink(frame_file)
    os.rmdir(frames_dir)
    
    print(f"Found {len(kill_timestamps)} kill detections")
    
    return {
        'videoKey': video_key,
        'email': email,
        'bucket': bucket,
        'killTimestamps': kill_timestamps,
        'totalDetections': len(kill_timestamps)
    }