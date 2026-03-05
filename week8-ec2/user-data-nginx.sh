#!/bin/bash
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
echo "User Data script completed at $(date)" >> /var/log/user-data.log