#!/usr/bin/env python3
"""
Database Backup Script
Backs up RDS MySQL database to S3 in backup region
"""

import boto3
import subprocess
import datetime
import os
import json
from botocore.exceptions import ClientError

# Configuration
PRIMARY_REGION = 'us-east-1'
BACKUP_REGION = 'us-west-2'
DB_NAME = 'ecommerce'
DB_USER = 'admin'
DB_PASS = 'SecurePass123!'

def get_db_endpoint():
    """Get RDS endpoint from primary region"""
    rds = boto3.client('rds', region_name=PRIMARY_REGION)
    
    try:
        response = rds.describe_db_instances(
            Filters=[
                {'Name': 'db-instance-id', 'Values': ['dr-ecom-v2-db-primary']}
            ]
        )
        endpoint = response['DBInstances'][0]['Endpoint']['Address']
        print(f"✓ Found DB endpoint: {endpoint}")
        return endpoint
    except Exception as e:
        print(f"✗ Error getting DB endpoint: {e}")
        return None

def get_backup_bucket():
    """Get backup bucket name from us-west-2"""
    s3 = boto3.client('s3', region_name=BACKUP_REGION)
    
    try:
        response = s3.list_buckets()
        for bucket in response['Buckets']:
            if 'db-backups-backup' in bucket['Name']:
                print(f"✓ Found backup bucket: {bucket['Name']}")
                return bucket['Name']
    except Exception as e:
        print(f"✗ Error finding backup bucket: {e}")
        return None

def backup_database(db_endpoint, backup_bucket):
    """Backup database to S3"""
    timestamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup_file = f"/tmp/db_backup_{timestamp}.sql"
    
    print(f"\n=== Starting Database Backup ===")
    print(f"Time: {datetime.datetime.now()}")
    print(f"Database: {db_endpoint}")
    print(f"Backup file: {backup_file}")
    
    # Dump database
    print("\n1. Dumping database...")
    dump_cmd = f"mysqldump -h {db_endpoint} -u {DB_USER} -p{DB_PASS} {DB_NAME} > {backup_file}"
    
    try:
        subprocess.run(dump_cmd, shell=True, check=True)
        file_size = os.path.getsize(backup_file)
        print(f"✓ Database dumped successfully ({file_size} bytes)")
    except subprocess.CalledProcessError as e:
        print(f"✗ Database dump failed: {e}")
        return False
    
    # Compress backup
    print("\n2. Compressing backup...")
    compressed_file = f"{backup_file}.gz"
    
    try:
        subprocess.run(f"gzip {backup_file}", shell=True, check=True)
        compressed_size = os.path.getsize(compressed_file)
        print(f"✓ Backup compressed ({compressed_size} bytes)")
    except subprocess.CalledProcessError as e:
        print(f"✗ Compression failed: {e}")
        return False
    
    # Upload to S3
    print(f"\n3. Uploading to S3 ({BACKUP_REGION})...")
    s3_key = f"database/{timestamp}/backup.sql.gz"
    
    try:
        s3 = boto3.client('s3', region_name=BACKUP_REGION)
        s3.upload_file(compressed_file, backup_bucket, s3_key)
        print(f"✓ Uploaded to s3://{backup_bucket}/{s3_key}")
    except ClientError as e:
        print(f"✗ Upload failed: {e}")
        return False
    
    # Save metadata
    print("\n4. Saving backup metadata...")
    metadata = {
        'timestamp': timestamp,
        'database': DB_NAME,
        'endpoint': db_endpoint,
        'file_size': compressed_size,
        's3_bucket': backup_bucket,
        's3_key': s3_key,
        'region': BACKUP_REGION
    }
    
    metadata_key = f"database/{timestamp}/metadata.json"
    s3.put_object(
        Bucket=backup_bucket,
        Key=metadata_key,
        Body=json.dumps(metadata, indent=2)
    )
    print(f"✓ Metadata saved")
    
    # Cleanup
    os.remove(compressed_file)
    print(f"\n✓ Backup completed successfully!")
    print(f"Backup location: s3://{backup_bucket}/{s3_key}")
    
    return True

if __name__ == "__main__":
    print("=" * 60)
    print("DR E-commerce Database Backup")
    print("=" * 60)
    
    db_endpoint = get_db_endpoint()
    if not db_endpoint:
        exit(1)
    
    backup_bucket = get_backup_bucket()
    if not backup_bucket:
        exit(1)
    
    success = backup_database(db_endpoint, backup_bucket)
    
    if success:
        print("\n✓ BACKUP COMPLETED SUCCESSFULLY")
        exit(0)
    else:
        print("\n✗ BACKUP FAILED")
        exit(1)
