#!/bin/bash
# User Data - EC2 with S3 integration via IAM role

dnf update -y
dnf install nginx -y
systemctl start nginx
systemctl enable nginx

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)


BUCKET_NAME="ec2-demo-files-20260305"

# List files in S3 bucket (using IAM role, no credentials needed!)
S3_FILES=$(aws s3 ls s3://${BUCKET_NAME}/ --region ${REGION} | awk '{print $4}' | grep -v '^$')

# Generate HTML with S3 file list
cat > /usr/share/nginx/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>EC2 + S3 Integration</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 50px auto;
            background: rgba(0,0,0,0.3);
            padding: 40px;
            border-radius: 20px;
        }
        h1 { font-size: 36px; text-align: center; margin-bottom: 30px; }
        .badge {
            background: #10b981;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            display: inline-block;
            margin: 5px;
        }
        .info-box {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .file-list {
            background: rgba(0,0,0,0.2);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid #10b981;
        }
        .file-item {
            padding: 10px;
            margin: 5px 0;
            background: rgba(255,255,255,0.05);
            border-radius: 5px;
            font-family: 'Courier New', monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔗 EC2 + IAM + S3 Integration</h1>
        
        <div style="text-align: center;">
            <span class="badge">🤖 Auto-Configured</span>
            <span class="badge">🔐 IAM Role Authentication</span>
            <span class="badge">📦 Live S3 Data</span>
        </div>

        <div class="info-box">
            <strong>Instance ID:</strong> ${INSTANCE_ID}<br>
            <strong>Region:</strong> ${REGION}<br>
            <strong>S3 Bucket:</strong> ${BUCKET_NAME}
        </div>

        <div class="file-list">
            <h3>📁 Files in S3 Bucket (via IAM Role):</h3>
EOF

# Add each file to HTML
if [ -z "$S3_FILES" ]; then
    echo "<div class='file-item'>No files found in bucket</div>" >> /usr/share/nginx/html/index.html
else
    for file in $S3_FILES; do
        echo "<div class='file-item'>📄 $file</div>" >> /usr/share/nginx/html/index.html
    done
fi

# Close HTML
cat >> /usr/share/nginx/html/index.html << 'EOF'
        </div>

        <div class="info-box" style="font-size: 14px; opacity: 0.9;">
            <strong>🔒 Security Note:</strong> This instance accesses S3 using an IAM role. 
            No AWS credentials are hardcoded. The instance automatically assumes the role 
            and gets temporary credentials that rotate every few hours.
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <p><strong>Built by:</strong> David - Week 8 Day 3</p>
            <p style="font-size: 14px; opacity: 0.8;">EC2 ↔️ IAM Role ↔️ S3 Integration</p>
        </div>
    </div>
</body>
</html>
EOF

echo "S3 integration setup completed at $(date)" >> /var/log/user-data.log