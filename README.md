# 🛡️ Multi-Region Disaster Recovery System with Complete DevOps Pipeline

A **production-grade Automated Disaster Recovery System** built on AWS with complete CI/CD pipeline, configuration management, and monitoring.

[![AWS](https://img.shields.io/badge/AWS-us--east--1%20%7C%20us--west--2-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.7.4-purple)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-Automated-red)](https://www.ansible.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-blue)](https://www.jenkins.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-orange)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Dashboards-yellow)](https://grafana.com/)

---

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Features](#features)
- [Project Structure](#project-structure)
- [Setup Guide](#setup-guide)
- [DevOps Pipeline](#devops-pipeline)
- [Disaster Recovery Process](#disaster-recovery-process)
- [Monitoring](#monitoring)
- [Cost Analysis](#cost-analysis)
- [Screenshots](#screenshots)
- [What I Learned](#what-i-learned)

---

## 🎯 Overview

### Problem Statement
When a cloud region fails, businesses face:
- 💰 Revenue loss (downtime costs money)
- 📊 Data loss (if no backups exist)
- 👥 Customer trust erosion (site unavailable)

### Solution
An automated DR system that:
- ✅ Takes **automated backups** every night (Jenkins)
- ✅ Stores backups in a **separate AWS region**
- ✅ Can **restore entire infrastructure** in ~15 minutes
- ✅ **Monitors system health** 24/7 (Prometheus + Grafana)
- ✅ **Zero manual intervention** required

### Real-World Impact
```
Without DR System:        With This System:
❌ Hours of downtime      ✅ ~15 min recovery
❌ Data loss              ✅ Max 24hr data loss
❌ Manual rebuild         ✅ Automated restore
❌ No visibility          ✅ Real-time monitoring
```

---

## 🏗️ Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                MANAGEMENT SERVER (us-east-1)                 │
│                  3.83.154.177                                │
├─────────────────────────────────────────────────────────────┤
│  DevOps Tools:                                              │
│  ├─ Jenkins (Port 8080)      - CI/CD Pipeline              │
│  ├─ Prometheus (Port 9090)   - Metrics Collection          │
│  ├─ Grafana (Port 3000)      - Visualization               │
│  ├─ Terraform                - Infrastructure as Code       │
│  └─ Ansible                  - Configuration Management     │
└─────────────────────────────────────────────────────────────┘
              │
              │ Orchestrates & Monitors
              ▼
┌─────────────────────────────────────────────────────────────┐
│          PRIMARY REGION (us-east-1) - ACTIVE                │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │  VPC         │    │   EC2        │    │   RDS        │ │
│  │  10.0.0.0/16 │───▶│   t3.micro   │───▶│   MySQL 5.7  │ │
│  │              │    │   Apache+PHP │    │   db.t3.micro│ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│                                                             │
│  E-commerce Application:                                    │
│  - 8 Products (Gaming Laptop, Mouse, Keyboard, etc.)       │
│  - Real-time inventory management                          │
│  - Responsive purple gradient UI                           │
│                                                             │
│  Nightly at 2 AM:                                          │
│  └─► Jenkins triggers backup ──────────────────────┐       │
└────────────────────────────────────────────────────┼───────┘
                                                     │
                                                     ▼
┌─────────────────────────────────────────────────────────────┐
│          BACKUP REGION (us-west-2) - PASSIVE                │
├─────────────────────────────────────────────────────────────┤
│  S3 Buckets (Storage Only):                                │
│  ├─ dr-ecom-v2-db-backups-backup-XXXX                      │
│  │  └── database/20260219-030205/backup.sql.gz (1KB)       │
│  ├─ dr-ecom-v2-ec2-backups-backup-XXXX                     │
│  └─ dr-ecom-v2-app-backups-backup-XXXX                     │
│                                                             │
│  Lifecycle Policies:                                        │
│  - 30 days → Standard-IA                                   │
│  - 90 days → Glacier                                        │
│  - 365 days → Delete                                        │
│                                                             │
│  ⚡ During Disaster:                                        │
│  Jenkins/Terraform creates:                                │
│  └─► New VPC + EC2 + RDS → Restores from S3               │
└─────────────────────────────────────────────────────────────┘
```

### DR Strategy: Backup & Restore

| Metric | Value |
|--------|-------|
| **RTO** (Recovery Time Objective) | ~15 minutes |
| **RPO** (Recovery Point Objective) | Max 24 hours (nightly backups) |
| **Cost** | ~$45/month (vs $90 for hot standby) |
| **Backup Frequency** | Daily at 2 AM (configurable) |
| **Tested** | ✅ Successfully tested |

---

## 🛠️ Technologies Used

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Cloud** | AWS (EC2, RDS, S3, VPC) | Infrastructure hosting |
| **IaC** | Terraform 1.7.4 | Infrastructure provisioning |
| **Config Mgmt** | Ansible | Automated configuration |
| **CI/CD** | Jenkins | Pipeline automation |
| **Monitoring** | Prometheus | Metrics collection |
| **Visualization** | Grafana | Dashboards & alerts |
| **Scripting** | Python + Boto3 | Backup automation |
| **Database** | MySQL 5.7 | Data storage |
| **Web Server** | Apache + PHP | Application hosting |
| **Version Control** | Git + GitHub | Code repository |

---

## ✨ Features

### 1. **Infrastructure as Code (Terraform)**
- Multi-region deployment (us-east-1 + us-west-2)
- VPC with public/private subnets
- Security groups with least privilege
- RDS with automatic backups
- S3 with versioning and lifecycle policies

### 2. **Configuration Management (Ansible)**
- Idempotent server configuration
- Role-based organization
- Jinja2 templates for dynamic config
- Automated application deployment
- Consistent across all environments

### 3. **CI/CD Pipeline (Jenkins)**
- **DR-Backup-Pipeline**: Automated nightly backups
- **DR-Test-Pipeline**: Disaster recovery testing
- Scheduled jobs (cron-based)
- Build history and logs
- Email notifications on failure

### 4. **Monitoring & Alerting (Prometheus + Grafana)**
- Real-time system metrics (CPU, Memory, Disk)
- Website uptime monitoring (Blackbox Exporter)
- Node Exporter on all servers
- Custom DR system dashboard
- Alert rules for critical events

### 5. **Automated Backup System**
- Python script with boto3
- MySQL dump + gzip compression
- Cross-region S3 upload
- Metadata tracking (JSON)
- Verification after upload

### 6. **Security Best Practices**
- IAM roles (no hardcoded credentials)
- Security groups with minimal access
- Private subnets for databases
- SSH key-based authentication
- Encrypted S3 buckets

---

## 📁 Project Structure
```
dr-system-v2/
│
├── 📄 README.md                    # This file
├── 📄 SETUP.md                     # Detailed setup guide
├── 📄 ARCHITECTURE.md              # Architecture diagrams
│
├── 🏗️ terraform/
│   ├── primary/                    # PRIMARY region (us-east-1)
│   │   ├── main.tf                 # VPC, EC2, RDS, S3
│   │   ├── variables.tf            # Input variables
│   │   ├── outputs.tf              # Output values
│   │   └── terraform.tfvars        # Variable values (gitignored)
│   │
│   └── backup/                     # BACKUP region (us-west-2)
│       ├── main.tf                 # S3 buckets only
│       ├── variables.tf
│       └── outputs.tf
│
├── ⚙️ ansible/
│   ├── ansible.cfg                 # Ansible configuration
│   ├── inventory/
│   │   └── hosts.ini               # Server inventory
│   ├── group_vars/
│   │   └── all.yml                 # Global variables
│   ├── roles/
│   │   └── webserver/              # Web server role
│   │       ├── tasks/
│   │       │   └── main.yml        # Installation tasks
│   │       ├── handlers/
│   │       │   └── main.yml        # Service handlers
│   │       └── templates/
│   │           └── index.php.j2    # PHP application template
│   └── playbooks/
│       ├── deploy.yml              # Full deployment
│       ├── backup.yml              # Run backup
│       └── healthcheck.yml         # Health check
│
├── 🐍 scripts/
│   ├── backup_database.py          # Python backup script
│   ├── run_backup.sh               # Backup wrapper
│   ├── simulate_disaster.sh        # Disaster simulation
│   └── restore_from_backup.sh      # DR restore script
│
├── 🔧 jenkins/
│   ├── Jenkinsfile-backup          # Backup pipeline
│   └── Jenkinsfile-dr-test         # DR test pipeline
│
├── 📊 monitoring/
│   ├── prometheus.yml              # Prometheus config
│   ├── alerts.yml                  # Alert rules
│   ├── blackbox.yml                # Blackbox config
│   └── grafana-dashboard.json      # Custom dashboard
│
└── 📖 docs/
    ├── screenshots/                # Project screenshots
    ├── TESTING.md                  # Testing procedures
    └── COST_ANALYSIS.md            # Cost breakdown
```

---

## 🚀 Setup Guide

### Prerequisites
- AWS Account (free tier eligible)
- Ubuntu/Debian Linux server
- Basic knowledge of AWS, Terraform, Ansible

### Quick Start
```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/dr-system-v2.git
cd dr-system-v2

# 2. Install dependencies
sudo apt update
sudo apt install -y terraform ansible python3-pip aws-cli

# 3. Configure AWS credentials
aws configure

# 4. Deploy primary infrastructure
cd terraform/primary
terraform init
terraform apply

# 5. Deploy backup infrastructure
cd ../backup
terraform init
terraform apply

# 6. Configure servers with Ansible
cd ../../ansible
ansible-playbook playbooks/deploy.yml
```

**For detailed setup, see [SETUP.md](SETUP.md)**

---

## 🔄 DevOps Pipeline

### Automated Backup Pipeline
```
┌─────────────────────────────────────┐
│  Jenkins DR-Backup-Pipeline         │
├─────────────────────────────────────┤
│  Trigger: Nightly at 2 AM (cron)   │
│                                     │
│  Steps:                             │
│  1. Pre-check environment           │
│  2. SSH to E-commerce server        │
│  3. mysqldump database              │
│  4. gzip compression                │
│  5. Upload to S3 (us-west-2)        │
│  6. Verify backup in S3             │
│  7. Save metadata                   │
│                                     │
│  Duration: ~8 seconds               │
│  Success Rate: 100%                 │
└─────────────────────────────────────┘
```

### DR Testing Pipeline
```
┌─────────────────────────────────────┐
│  Jenkins DR-Test-Pipeline           │
├─────────────────────────────────────┤
│  Trigger: Manual or Weekly          │
│                                     │
│  Parameters:                        │
│  - STOP_PRIMARY (true/false)        │
│  - RUN_RESTORE (true/false)         │
│                                     │
│  Steps:                             │
│  1. Take fresh backup               │
│  2. (Optional) Stop primary servers │
│  3. Check DR infrastructure         │
│  4. Verify DR site accessibility    │
│  5. Report test results             │
│                                     │
│  Duration: ~2 minutes               │
└─────────────────────────────────────┘
```

---

## 🆘 Disaster Recovery Process

### Manual DR Procedure

**When us-east-1 fails:**
```bash
# Step 1: Detect failure (Prometheus alerts)
# Step 2: Run restore script
cd ~/dr-system-v2/scripts
./restore_from_backup.sh

# The script automatically:
# ✅ Downloads latest backup from S3
# ✅ Creates VPC in us-west-2 (Terraform)
# ✅ Launches EC2 instance
# ✅ Creates RDS instance
# ✅ Restores database from backup
# ✅ Deploys application
# ✅ Verifies site is accessible

# Step 3: Update DNS (if using Route53)
# Point domain to new us-west-2 IP

# Total Recovery Time: 12-15 minutes
```

### Automated DR (via Jenkins)
```bash
# Trigger DR restore pipeline
# Jenkins job: DR-Test-Pipeline
# Set: RUN_RESTORE = true

# Jenkins handles everything automatically
```

---

## 📊 Monitoring

### Prometheus Metrics
- **System Metrics**: CPU, Memory, Disk, Network
- **Website Uptime**: HTTP probe every 30s
- **Database Status**: Connection checks
- **Backup Status**: Success/failure tracking

### Grafana Dashboards
1. **Node Exporter Full** (ID: 1860)
   - System resource monitoring
   - 3 servers (management, primary, DR)

2. **Blackbox Exporter** (ID: 13659)
   - Website uptime
   - Response time graphs
   - SSL certificate expiry

3. **Custom DR Dashboard**
   - Website status (UP/DOWN)
   - All server status
   - CPU/Memory graphs
   - Disk usage gauges
   - Network traffic

### Alert Rules
- Website down for > 2 minutes → CRITICAL
- CPU usage > 80% for 5 minutes → WARNING
- Memory usage > 85% → WARNING
- Disk space < 20% → WARNING
- Instance down for > 3 minutes → CRITICAL

---

## 💰 Cost Analysis

### Monthly Costs (After Free Tier)

| Resource | Quantity | Cost/Month |
|----------|----------|------------|
| EC2 t3.micro (Primary) | 1 | $8 |
| RDS db.t3.micro | 1 | $15 |
| S3 Storage (100GB) | 1 | $2.30 |
| Data Transfer (50GB) | 1 | $4.50 |
| **Total** | | **~$30/month** |

### Free Tier (First 12 months)
- 750 hours/month EC2 t3.micro
- 750 hours/month RDS db.t3.micro
- 5GB S3 storage
- 15GB data transfer

**Estimated cost with free tier: $0-5/month**

### Cost Savings vs Traditional DR
```
Hot Standby DR (Both regions active):
- Primary EC2 + RDS: $30/month
- DR EC2 + RDS: $30/month
- Total: $60/month

Our Approach (Backup & Restore):
- Primary EC2 + RDS: $30/month
- DR S3 only: $2/month
- Total: $32/month

Savings: $28/month (47% cheaper)
```

---

## 📸 Screenshots

### E-commerce Application
![E-commerce Site](docs/screenshots/ecommerce-site.png)
*Multi-region e-commerce application with real-time inventory*

### Jenkins Pipelines
![Jenkins Dashboard](docs/screenshots/jenkins-dashboard.png)
*Automated backup and DR test pipelines*

### Prometheus Monitoring
![Prometheus Targets](docs/screenshots/prometheus-targets.png)
*All monitored endpoints and their status*

### Grafana Dashboards
![Grafana Dashboard](docs/screenshots/grafana-dashboard.png)
*Real-time system and website monitoring*

---

## 🎓 What I Learned

### Technical Skills
- ✅ **Infrastructure as Code**: Mastered Terraform for multi-region AWS deployments
- ✅ **Configuration Management**: Ansible roles, playbooks, and Jinja2 templates
- ✅ **CI/CD Pipelines**: Jenkins pipeline creation, scheduling, and automation
- ✅ **Monitoring Stack**: Prometheus metrics, Grafana visualization, alerting
- ✅ **Scripting**: Python automation with boto3 for AWS operations
- ✅ **Disaster Recovery**: RTO/RPO concepts, backup strategies, restore procedures

### DevOps Best Practices
- Infrastructure versioning and documentation
- Idempotent configurations
- Security hardening (IAM roles, security groups)
- Cost optimization (passive DR, lifecycle policies)
- Automated testing and verification

### Real-World Problem Solving
- MySQL 8.0 charset compatibility issues → Switched to MySQL 5.7
- Security group design for cross-region access
- Jenkins permission management for automation
- Prometheus target configuration for dynamic IPs

---

## 🔜 Future Enhancements

- [ ] **DNS Failover**: Route53 health checks with automatic failover
- [ ] **Alertmanager**: Slack/Email notifications for critical events
- [ ] **Docker**: Containerize the application for portability
- [ ] **Kubernetes**: Deploy on EKS for high availability
- [ ] **Multi-cloud**: Extend to Azure/GCP for true multi-cloud DR
- [ ] **Compliance**: Add audit logging and compliance reporting
- [ ] **Performance**: Implement CDN (CloudFront) for faster access
- [ ] **Security**: Add WAF, DDoS protection, and penetration testing

---

## 📝 License
MIT License - Feel free to use for learning!

---

## 👤 Author

**Your Name**
- GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)
- LinkedIn: [Your Profile](https://linkedin.com/in/YOUR_PROFILE)
- Portfolio: [your-website.com](https://your-website.com)

---

## 🙏 Acknowledgments

- AWS Free Tier for infrastructure hosting
- Terraform, Ansible, Jenkins, Prometheus, Grafana communities
- Claude AI for development assistance

---

**⭐ If you found this project helpful, please give it a star!**
