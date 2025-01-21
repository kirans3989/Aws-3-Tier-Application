#!/bin/bash
yum update -y
yum install -y nodejs npm git

# Set environment variables
cat << EOF > /etc/environment
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
EOF

# Clone application code
cd /opt
git clone https://github.com/kirans3989/Aws-3-Tier-Application.git
cd three-tier-app

# Install dependencies and start application
npm install
npm start