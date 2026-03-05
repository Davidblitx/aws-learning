# Week 8 Day 2: User Data Scripts & Automation

## What I Built
- Automated web server deployment using User Data
- Dynamic HTML page pulling instance metadata
- Zero manual configuration required

## User Data Script (Basic Version)
{#!/bin/bash
# User Data Script - Automatically configure nginx web server

# Update all packages
dnf update -y

# Install nginx
dnf install nginx -y

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Create custom HTML page
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Automated AWS Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background: rgba(0,0,0,0.3);
            padding: 50px;
            border-radius: 20px;
        }
        h1 { font-size: 48px; margin-bottom: 20px; }
        .badge {
            background: #10b981;
            padding: 10px 20px;
            border-radius: 20px;
            font-size: 18px;
            margin: 20px 0;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 Automated Server Deployment</h1>
        <div class="badge">✨ Zero Manual Configuration</div>
        <p>This server configured itself on launch</p>
        <p>User Data Script executed automatically</p>
        <p><strong>Built by:</strong> David - Week 8 Day 2</p>
    </div>
</body>
</html>
EOF

# Log completion
echo "User Data script completed at $(date)" >> /var/log/user-data.log}


## User Data Script (Dynamic Version)
{#!/bin/bash
# Enhanced User Data - Dynamic content from metadata

dnf update -y
dnf install nginx -y
systemctl start nginx
systemctl enable nginx

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create dynamic HTML with actual instance info
cat > /usr/share/nginx/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Dynamic AWS Server</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 50px auto;
            background: rgba(0,0,0,0.3);
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 { font-size: 42px; margin-bottom: 30px; text-align: center; }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 30px 0;
        }
        .info-box {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #10b981;
        }
        .label { 
            font-size: 14px; 
            opacity: 0.8;
            margin-bottom: 5px;
        }
        .value { 
            font-size: 20px; 
            font-weight: bold;
            font-family: 'Courier New', monospace;
        }
        .badge {
            background: #10b981;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            display: inline-block;
            margin: 10px 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Dynamic AWS Infrastructure</h1>
        
        <div style="text-align: center; margin: 20px 0;">
            <span class="badge">✨ Auto-Configured</span>
            <span class="badge">🤖 Zero Touch Deployment</span>
            <span class="badge">📊 Live Metadata</span>
        </div>

        <div class="info-grid">
            <div class="info-box">
                <div class="label">Instance ID</div>
                <div class="value">$INSTANCE_ID</div>
            </div>
            <div class="info-box">
                <div class="label">Instance Type</div>
                <div class="value">$INSTANCE_TYPE</div>
            </div>
            <div class="info-box">
                <div class="label">Availability Zone</div>
                <div class="value">$AVAILABILITY_ZONE</div>
            </div>
            <div class="info-box">
                <div class="label">Public IP</div>
                <div class="value">$PUBLIC_IP</div>
            </div>
        </div>

        <div style="text-align: center; margin-top: 40px; font-size: 18px;">
            <p><strong>Deployed by:</strong> David - Week 8 Day 2</p>
            <p style="font-size: 14px; opacity: 0.8;">This page generated automatically from instance metadata</p>
        </div>
    </div>
</body>
</html>
EOF

echo "Dynamic server setup completed at $(date)" >> /var/log/user-data.log}

## Test Results

**Basic automated server:**
- Instance name: automated-web-server
- Launched at: Thu Mar  5 09:22:05 UTC 2026
- Website live at: 09:25:18 (3 minutes after launch)
- Manual steps required: ZERO

**Dynamic server:**
- Instance name: dynamic-web-server  
- Instance ID shown on page: i-0ca0c8e8adf02afbf
- Instance type shown: t3.micro
- All metadata populated correctly: YES

## Key Learnings

**What is User Data:**
- Bash script that runs once on first boot
- Root privileges (runs as root user)
- Output logged to /var/log/cloud-init-output.log
- Use case: Automate server configuration

**Instance Metadata:**
- Available at 169.254.169.254
- Provides instance info (ID, type, IP, AZ)
- Scripts can query this to adapt behavior
- Not accessible from outside the instance

**Why This Matters:**
Automation is superior to manual configuration because it ensures consistency and speed. In a manual setup, a human might forget to start Nginx or misconfigure a file. With User Data, every instance is a perfect clone of the last, eliminating "human error" and allowing you to scale from 1 server to 1,000 without extra effort.

## Metadata Commands I Used
These commands allowed the server to "know" itself:

curl -s http://169.254.169.254/latest/meta-data/instance-id → Returned: i-0ca0c8e8adf02afbf

curl -s http://169.254.169.254/latest/meta-data/instance-type → Returned: t3.micro

curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone → Returned: us-east-2a (or your specific AZ)

curl -s http://169.254.169.254/latest/meta-data/public-ipv4 → Returned: 18.222.193.219]

## Questions I Can Answer

**1. What's the difference between User Data and SSH-ing in to configure?**
User Data happens automatically before the user even logs in. SSH-ing is manual and doesn't scale. If you have 100 servers, you can't SSH into all of them, but you can give all of them the same User Data script.

**2. When does User Data execute?**
It executes exactly once, during the very first boot cycle of the instance. If you stop and start the instance, it will not run again.

**3. Can you change User Data after launch?**
You can modify the User Data in the settings, but it will not take effect unless you terminate the instance and launch a new one, or manually trigger the script.

**4. What's the 169.254.169.254 IP address?**
This is the link-local address used to access the Instance Metadata Service (IMDS). It is only reachable from within the EC2 instance itself

**5. How would you troubleshoot if User Data didn't work?**
I would SSH into the instance and check the logs at /var/log/cloud-init-output.log. This file records every success or failure of the script commands.

## Real-World Applications

**This is how:**
- Auto Scaling launches pre-configured instances
- Infrastructure as Code (Terraform) provisions servers
- CI/CD pipelines deploy applications
- Production environments maintain consistency

## Time Saved
- Manual setup: ~15 minutes per server
- Automated setup: 0 minutes per server
- For 100 servers: 25 hours saved

## Next: Day 3 - IAM Roles for EC2