#!/bin/bash
# Easy Backup Script Wrapper

echo "========================================"
echo "DR E-commerce Backup Script"
echo "========================================"

# Get EC2 IP
cd ~/dr-system-v2/terraform/primary
WEB_IP=$(terraform output -raw web_public_ip 2>/dev/null)

if [ -z "$WEB_IP" ]; then
    echo "❌ Error: Cannot find web server IP"
    exit 1
fi

echo "Web Server: $WEB_IP"
echo "Running backup..."
echo ""

# Run backup on EC2
ssh -i ~/.ssh/id_rsa ec2-user@$WEB_IP "python3 /tmp/backup_database.py"

# Verify backup
cd ~/dr-system-v2/terraform/backup
BACKUP_BUCKET=$(terraform output -raw db_backup_bucket 2>/dev/null)

echo ""
echo "========================================"
echo "Backup Verification"
echo "========================================"
echo "Latest backups in S3:"
aws s3 ls s3://$BACKUP_BUCKET/database/ --recursive --region us-west-2 | tail -5

echo ""
echo "✅ Backup Complete!"
