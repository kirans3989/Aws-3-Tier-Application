# AWS Three-Tier Architecture Implementation Guide (Console)

This guide provides step-by-step instructions for implementing a three-tier architecture using the AWS Management Console.

## Step 1: VPC Setup

1. **Create VPC**
   - Navigate to VPC Dashboard
   - Click "Create VPC"
   - Select "VPC and More" (VPC wizard)
   - Enter:
     - Name tag: `three-tier-vpc`
     - IPv4 CIDR: `10.0.0.0/16`
     - No IPv6 CIDR block
     - Tenancy: Default
   - Click "Create VPC"

2. **Create Subnets**
   - In VPC Dashboard, click "Subnets" → "Create Subnet"
   - Select the VPC created above
   - Create the following subnets:
     
     **Public Subnets (Web Tier)**
     - Name: `web-subnet-1a`
       - AZ: us-east-1a
       - CIDR: `10.0.1.0/24`
     - Name: `web-subnet-1b`
       - AZ: us-east-1b
       - CIDR: `10.0.2.0/24`
     
     **Private Subnets (App Tier)**
     - Name: `app-subnet-1a`
       - AZ: us-east-1a
       - CIDR: `10.0.11.0/24`
     - Name: `app-subnet-1b`
       - AZ: us-east-1b
       - CIDR: `10.0.12.0/24`
     
     **Private Subnets (Database Tier)**
     - Name: `db-subnet-1a`
       - AZ: us-east-1a
       - CIDR: `10.0.21.0/24`
     - Name: `db-subnet-1b`
       - AZ: us-east-1b
       - CIDR: `10.0.22.0/24`

3. **Internet Gateway**
   - Go to "Internet Gateways" → "Create Internet Gateway"
   - Name: `three-tier-igw`
   - Click "Create"
   - Select the new IGW → "Actions" → "Attach to VPC"
   - Select your VPC and click "Attach"

4. **NAT Gateway**
   - Go to "NAT Gateways" → "Create NAT Gateway"
   - Select `web-subnet-1a`
   - Click "Allocate Elastic IP"
   - Name: `three-tier-nat`
   - Click "Create NAT Gateway"

5. **Route Tables**
   - Go to "Route Tables" → "Create Route Table"
   
   **Public Route Table**
   - Name: `public-rt`
   - Select your VPC
   - Add route: `0.0.0.0/0` → Internet Gateway
   - Associate with public subnets
   
   **Private Route Table**
   - Name: `private-rt`
   - Select your VPC
   - Add route: `0.0.0.0/0` → NAT Gateway
   - Associate with private subnets

## Step 2: Security Groups

1. **Web Tier Security Group**
   - Go to EC2 Dashboard → "Security Groups" → "Create Security Group"
   - Name: `web-tier-sg`
   - Description: "Web Tier Security Group"
   - VPC: Select your VPC
   - Inbound rules:
     - HTTP (80) from Anywhere
     - HTTPS (443) from Anywhere
   - Click "Create"

2. **App Tier Security Group**
   - Name: `app-tier-sg`
   - Description: "App Tier Security Group"
   - VPC: Select your VPC
   - Inbound rules:
     - Custom TCP (3000) from Web Tier SG
   - Click "Create"

3. **Database Security Group**
   - Name: `db-tier-sg`
   - Description: "Database Tier Security Group"
   - VPC: Select your VPC
   - Inbound rules:
     - PostgreSQL (5432) from App Tier SG
   - Click "Create"

## Step 3: RDS Setup

1. **Create Subnet Group**
   - Go to RDS Dashboard
   - Click "Subnet Groups" → "Create DB Subnet Group"
   - Enter:
     - Name: `three-tier-db-subnet`
     - Description: "Subnet group for RDS"
     - VPC: Select your VPC
     - Add both database subnets
   - Click "Create"

2. **Create RDS Instance**
   - Click "Databases" → "Create Database"
   - Choose:
     - Standard create
     - PostgreSQL
     - Free tier template
   - Settings:
     - DB instance identifier: `three-tier-db`
     - Master username: `admin`
     - Master password: (set a secure password)
   - Instance configuration:
     - db.t3.micro
   - Storage:
     - 20 GB GP2
   - Connectivity:
     - VPC: Your VPC
     - Subnet group: `three-tier-db-subnet`
     - Public access: No
     - VPC security group: `db-tier-sg`
   - Click "Create database"

## Step 4: EC2 Setup

1. **Create Launch Template for Web Tier**
   - Go to EC2 Dashboard → "Launch Templates"
   - Click "Create Launch Template"
   - Name: `web-tier-template`
   - AMI: Amazon Linux 2023
   - Instance type: t3.micro
   - Security group: `web-tier-sg`
   - User data:
     ```bash
     #!/bin/bash
     yum update -y
     yum install -y nodejs npm
     cd /opt
     git clone https://github.com/your-repo/three-tier-app.git
     cd three-tier-app
     npm install
     npm run build
     ```

2. **Create Launch Template for App Tier**
   - Name: `app-tier-template`
   - AMI: Amazon Linux 2023
   - Instance type: t3.micro
   - Security group: `app-tier-sg`
   - User data:
     ```bash
     #!/bin/bash
     yum update -y
     yum install -y nodejs npm
     cd /opt
     git clone https://github.com/your-repo/three-tier-app.git
     cd three-tier-app
     npm install
     npm start
     ```

## Step 5: Load Balancer Setup

1. **Create Application Load Balancer**
   - Go to EC2 → "Load Balancers"
   - Click "Create Load Balancer"
   - Choose "Application Load Balancer"
   - Basic configuration:
     - Name: `three-tier-alb`
     - Scheme: Internet-facing
     - IP address type: IPv4
   - Network mapping:
     - VPC: Your VPC
     - Mappings: Select both public subnets
   - Security groups: `web-tier-sg`
   - Listeners and routing:
     - HTTP:80
     - Create target group:
       - Name: `web-tier-tg`
       - Target type: Instance
       - Protocol: HTTP
       - Port: 80
   - Click "Create load balancer"

## Step 6: Auto Scaling Groups

1. **Create Web Tier ASG**
   - Go to EC2 → "Auto Scaling Groups"
   - Click "Create Auto Scaling group"
   - Name: `web-tier-asg`
   - Launch template: `web-tier-template`
   - VPC and subnets: Select public subnets
   - Load balancer: Select target group `web-tier-tg`
   - Group size:
     - Desired: 2
     - Minimum: 2
     - Maximum: 4
   - Scaling policies: Target tracking
     - Metric: Average CPU utilization
     - Target value: 70
   - Click "Create"

2. **Create App Tier ASG**
   - Name: `app-tier-asg`
   - Launch template: `app-tier-template`
   - VPC and subnets: Select app tier private subnets
   - Group size:
     - Desired: 2
     - Minimum: 2
     - Maximum: 4
   - Scaling policies: Same as web tier
   - Click "Create"

## Step 7: CloudFront Setup

1. **Create Distribution**
   - Go to CloudFront Dashboard
   - Click "Create Distribution"
   - Origin domain: Select ALB DNS name
   - Viewer protocol policy: Redirect HTTP to HTTPS
   - Allowed HTTP methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
   - Cache policy: CachingDisabled
   - Click "Create distribution"

## Step 8: Route 53 Setup

1. **Create Hosted Zone**
   - Go to Route 53 Dashboard
   - Click "Create Hosted Zone"
   - Domain name: Your domain
   - Type: Public hosted zone
   - Click "Create"

2. **Create Record**
   - Click "Create Record"
   - Record name: www or app
   - Record type: A
   - Alias: Yes
   - Route traffic to: CloudFront distribution
   - Click "Create records"

## Step 9: Monitoring Setup

1. **Create CloudWatch Dashboard**
   - Go to CloudWatch Dashboard
   - Click "Create dashboard"
   - Add widgets for:
     - ALB metrics
     - EC2 metrics
     - RDS metrics
   - Configure widgets as needed

2. **Create Alarms**
   - Go to CloudWatch Alarms
   - Click "Create alarm"
   - Select metric:
     - EC2 CPU Utilization
     - RDS CPU Utilization
     - ALB Response Time
   - Set thresholds and actions

## Verification Steps

1. **Test Connectivity**
   - Access your application through CloudFront URL
   - Verify SSL/TLS is working
   - Test database connectivity
   - Verify auto scaling triggers

2. **Security Verification**
   - Verify security group rules
   - Test private subnet isolation
   - Verify RDS is not publicly accessible
   - Check CloudWatch logs

## Maintenance Tasks

1. **Regular Updates**
   - Schedule maintenance windows
   - Update EC2 AMIs
   - Patch RDS instances
   - Rotate credentials

2. **Backup Verification**
   - Test RDS snapshots
   - Verify backup retention
   - Test restoration procedures
   - Document recovery steps