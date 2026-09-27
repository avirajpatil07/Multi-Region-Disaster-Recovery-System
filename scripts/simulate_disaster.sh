#!/bin/bash
# Disaster Simulation Script

echo "========================================"
echo "⚠️  DISASTER SIMULATION ⚠️"
echo "========================================"
echo ""
echo "This will STOP your e-commerce servers!"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🔥 Starting disaster simulation..."

cd ~/dr-system-v2/terraform/primary

# Get instance ID
WEB_INSTANCE=$(terraform output -raw web_instance_id)
DB_IDENTIFIER="dr-ecom-v2-db-primary"
WEB_IP=$(terraform output -raw web_public_ip)

echo "Stopping E-commerce web server..."
aws ec2 stop-instances --instance-ids $WEB_INSTANCE
echo "✓ Web server stopped"

echo ""
read -p "Also stop database? (yes/no): " stop_db

if [ "$stop_db" = "yes" ]; then
    echo "Stopping RDS database..."
    aws rds stop-db-instance --db-instance-identifier $DB_IDENTIFIER
    echo "✓ Database stopped"
fi

echo ""
echo "========================================"
echo "🔥 DISASTER SIMULATED!"
echo "========================================"
echo ""
echo "Site is DOWN: http://$WEB_IP/index.php"
echo ""
echo "Next: Run restore script"
echo "  ./restore_from_backup.sh"
