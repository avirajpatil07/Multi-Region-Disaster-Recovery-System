# 📖 Detailed Setup Guide

This guide walks you through setting up the entire DR system from scratch.

## Prerequisites

### Required Software
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install core tools
sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    python3 \
    python3-pip \
    mysql-client

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.7.4/terraform_1.7.4_linux_amd64.zip
unzip terraform_1.7.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install Ansible
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Install Python packages
pip3 install boto3
```

### AWS Account Setup
1. Create AWS account (free tier eligible)
2. Create IAM user with AdministratorAccess
3. Generate access keys
4. Configure AWS CLI:
```bash
aws configure
# Enter: Access Key ID
# Enter: Secret Access Key
# Region: us-east-1
# Output: json
```

### SSH Key Generation
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

## Step-by-Step Deployment

### Phase 1: Infrastructure (Week 1)

**Deploy Primary Region:**
```bash
cd terraform/primary
terraform init
terraform plan
terraform apply -auto-approve
```

**Deploy Backup Region:**
```bash
cd ../backup
terraform init
terraform apply -auto-approve
```

**Save outputs:**
```bash
cd ../primary
terraform output > ../../docs/terraform-outputs.txt
```

### Phase 2: Configuration (Week 2)

**Configure Ansible inventory:**
```bash
cd ../../ansible

# Update inventory with actual IPs
PRIMARY_IP=$(cd ../terraform/primary && terraform output -raw web_public_ip)
sed -i "s/PRIMARY_IP/$PRIMARY_IP/" inventory/hosts.ini
```

**Deploy application:**
```bash
ansible-playbook playbooks/deploy.yml
```

### Phase 3: CI/CD (Week 3)

**Install Jenkins:**
```bash
sudo apt install -y openjdk-17-jdk
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
```

**Setup Jenkins jobs:**
1. Access: http://YOUR_IP:8080
2. Install suggested plugins
3. Create pipelines (see jenkins/ directory)

### Phase 4: Monitoring (Week 4)

**Install Prometheus:**
```bash
# Download and install (see monitoring/install-prometheus.sh)
```

**Install Grafana:**
```bash
# Download and install (see monitoring/install-grafana.sh)
```

**Configure dashboards:**
1. Add Prometheus data source
2. Import dashboards (IDs: 1860, 13659)

## Verification

### Test Backup
```bash
cd scripts
./run_backup.sh
```

### Test DR Restore
```bash
./restore_from_backup.sh
```

### Verify Monitoring
- Prometheus: http://YOUR_IP:9090/targets
- Grafana: http://YOUR_IP:3000

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

