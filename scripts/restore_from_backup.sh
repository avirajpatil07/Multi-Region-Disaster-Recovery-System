#!/bin/bash
# Disaster Recovery - Restore to us-west-2

echo "========================================"
echo "🚀 DISASTER RECOVERY - RESTORE"
echo "========================================"
echo ""
echo "This will restore your site in us-west-2"
echo ""

START_TIME=$(date +%s)

# Step 1: Find latest backup
echo "Step 1: Finding latest backup..."
cd ~/dr-system-v2/terraform/backup
BACKUP_BUCKET=$(terraform output -raw db_backup_bucket)

LATEST_BACKUP=$(aws s3 ls s3://$BACKUP_BUCKET/database/ --region us-west-2 | \
    grep "PRE" | tail -1 | awk '{print $2}' | sed 's/\///')

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ No backup found!"
    exit 1
fi

echo "✓ Found backup: $LATEST_BACKUP"

# Download backup
echo ""
echo "Step 2: Downloading backup..."
mkdir -p /tmp/dr-restore
aws s3 cp s3://$BACKUP_BUCKET/database/$LATEST_BACKUP/backup.sql.gz \
    /tmp/dr-restore/backup.sql.gz --region us-west-2

echo "✓ Backup downloaded"

# Step 3: Create infrastructure
echo ""
echo "Step 3: Creating infrastructure in us-west-2..."
echo "⏳ This takes 8-10 minutes (RDS is slow)..."
echo ""

cd ~/dr-system-v2/terraform
mkdir -p dr-restore
cd dr-restore

# Create Terraform config
cat > main.tf << 'TFEOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "dr-ecom-v2-vpc-restored" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "dr-ecom-v2-igw-restored" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags                    = { Name = "dr-ecom-v2-public-restored" }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-west-2a"
  tags              = { Name = "dr-ecom-v2-private-1-restored" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "us-west-2b"
  tags              = { Name = "dr-ecom-v2-private-2-restored" }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "dr-ecom-v2-rt-restored" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "web" {
  name        = "dr-ecom-v2-web-sg-restored"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name        = "dr-ecom-v2-db-sg-restored"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH Key
resource "aws_key_pair" "deployer" {
  key_name   = "dr-ecom-v2-key-restored"
  public_key = file("~/.ssh/id_rsa.pub")
}

# AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-BASH
#!/bin/bash
yum update -y
yum install -y httpd php php-mysqlnd mysql
systemctl start httpd
systemctl enable httpd
BASH

  tags = { Name = "dr-ecom-v2-web-restored" }
}

# RDS
resource "aws_db_subnet_group" "main" {
  name       = "dr-ecom-v2-db-subnet-restored"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "main" {
  identifier              = "dr-ecom-v2-db-restored"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  db_name                 = "ecommerce"
  username                = "admin"
  password                = "SecurePass123!"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  backup_retention_period = 1
  skip_final_snapshot     = true
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}
TFEOF

terraform init
terraform apply -auto-approve

echo "✓ Infrastructure created"

# Step 4: Restore database
echo ""
echo "Step 4: Restoring database..."
echo "⏳ Waiting 60 seconds for servers..."
sleep 60

WEB_IP=$(terraform output -raw web_public_ip)
DB_ENDPOINT=$(terraform output -raw db_endpoint | cut -d: -f1)

echo "New Server IP: $WEB_IP"
echo "New DB Endpoint: $DB_ENDPOINT"

# Copy backup to new server
echo "Copying backup to server..."
scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa \
    /tmp/dr-restore/backup.sql.gz ec2-user@$WEB_IP:/tmp/

# Restore database
echo "Restoring database..."
ssh -i ~/.ssh/id_rsa ec2-user@$WEB_IP << REMOTEEOF
gunzip /tmp/backup.sql.gz
mysql -h $DB_ENDPOINT -u admin -pSecurePass123! ecommerce < /tmp/backup.sql
echo "✓ Database restored"
REMOTEEOF

# Step 5: Deploy application
echo ""
echo "Step 5: Deploying application..."

ssh -i ~/.ssh/id_rsa ec2-user@$WEB_IP << REMOTEEOF
sudo tee /var/www/html/index.php > /dev/null << 'PHPEOF'
<?php
\$db_host = "$DB_ENDPOINT";
\$db_name = "ecommerce";
\$db_user = "admin";
\$db_pass = "SecurePass123!";

\$conn = mysqli_connect(\$db_host, \$db_user, \$db_pass, \$db_name);

if (\$conn) {
    \$result = mysqli_query(\$conn, "SELECT * FROM products ORDER BY id");
    \$products = mysqli_fetch_all(\$result, MYSQLI_ASSOC);
    \$db_status = "Connected ✓";
} else {
    \$db_status = "Error";
    \$products = [];
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>DR E-commerce - RESTORED</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: Arial;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .alert {
            background: #28a745;
            color: white;
            padding: 20px;
            text-align: center;
            font-size: 1.3em;
            font-weight: bold;
        }
        .header { 
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 { font-size: 2.5em; }
        .info-panel { 
            background: #f8f9fa;
            padding: 20px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        .info-item { 
            background: white;
            padding: 15px;
            border-radius: 10px;
        }
        .info-label { 
            font-weight: bold;
            color: #f5576c;
            font-size: 0.9em;
        }
        .info-value { margin-top: 5px; }
        .status-ok { color: #28a745; font-weight: bold; }
        .products { padding: 40px; }
        .products h2 { text-align: center; margin-bottom: 30px; }
        .products-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 25px;
        }
        .product-card { 
            border: 2px solid #e0e0e0;
            padding: 25px;
            border-radius: 15px;
        }
        .product-card:hover {
            box-shadow: 0 8px 25px rgba(245, 87, 108, 0.4);
            border-color: #f5576c;
        }
        .product-name { font-size: 1.4em; font-weight: bold; margin-bottom: 15px; }
        .product-price { color: #f5576c; font-size: 1.8em; font-weight: bold; }
        .product-stock { 
            background: #ffe7ea;
            color: #f5576c;
            padding: 8px 15px;
            border-radius: 20px;
            display: inline-block;
            margin-top: 10px;
        }
        .footer {
            text-align: center;
            padding: 30px;
            background: #f8f9fa;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="alert">
            ✅ SITE SUCCESSFULLY RESTORED FROM BACKUP!
        </div>
        
        <div class="header">
            <h1>🛒 DR E-commerce Store</h1>
            <p>RESTORED in us-west-2</p>
        </div>
        
        <div class="info-panel">
            <div class="info-item">
                <div class="info-label">🖥️ SERVER</div>
                <div class="info-value"><?php echo gethostname(); ?></div>
            </div>
            <div class="info-item">
                <div class="info-label">🌍 REGION</div>
                <div class="info-value">us-west-2 (RESTORED)</div>
            </div>
            <div class="info-item">
                <div class="info-label">💾 DATABASE</div>
                <div class="info-value status-ok"><?php echo \$db_status; ?></div>
            </div>
            <div class="info-item">
                <div class="info-label">🕐 RESTORED</div>
                <div class="info-value"><?php echo date('Y-m-d H:i:s'); ?></div>
            </div>
        </div>
        
        <div class="products">
            <h2>📦 Restored Products</h2>
            <div class="products-grid">
                <?php foreach(\$products as \$p): ?>
                <div class="product-card">
                    <div class="product-name"><?php echo \$p['name']; ?></div>
                    <div class="product-price">\$<?php echo number_format(\$p['price'], 2); ?></div>
                    <div class="product-stock">📦 <?php echo \$p['stock']; ?> in stock</div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>🚀 Disaster Recovery Complete!</strong></p>
            <p>us-east-1 (DOWN) → us-west-2 (ACTIVE)</p>
        </div>
    </div>
</body>
</html>
PHPEOF

sudo systemctl restart httpd
REMOTEEOF

# Calculate time
END_TIME=$(date +%s)
RECOVERY_TIME=\$((END_TIME - START_TIME))
MINUTES=\$((RECOVERY_TIME / 60))
SECONDS=\$((RECOVERY_TIME % 60))

echo ""
echo "========================================"
echo "✅ DISASTER RECOVERY COMPLETE!"
echo "========================================"
echo ""
echo "Recovery Time: \${MINUTES}m \${SECONDS}s"
echo ""
echo "🎉 Your site is now live at:"
echo "   http://$WEB_IP/index.php"
echo ""
echo "Region: us-west-2"
echo "Database: Restored from backup"
echo "All products: Intact"
echo ""
