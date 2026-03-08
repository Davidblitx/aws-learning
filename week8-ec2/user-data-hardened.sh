#!/bin/bash
# EC2 Security Hardening Script
# Implements production security best practices

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting EC2 Hardening at $(date) ==="

# Update system
echo "Updating system packages..."
dnf update -y

# Install required packages
echo "Installing security packages..."
dnf install -y nginx fail2ban firewalld

# 1. CONFIGURE FIREWALL
echo "Configuring firewall..."
systemctl start firewalld
systemctl enable firewalld

# Allow only SSH (custom port) and HTTP
firewall-cmd --permanent --add-port=2222/tcp  # Custom SSH port
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# 2. HARDEN SSH
echo "Hardening SSH configuration..."
# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Change SSH port
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Disable root login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication (key-only)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Limit authentication attempts
echo "MaxAuthTries 3" >> /etc/ssh/sshd_config

# Set login grace time (30 seconds)
echo "LoginGraceTime 30" >> /etc/ssh/sshd_config

# Restart SSH with new config
systemctl restart sshd

# 3. CONFIGURE FAIL2BAN
echo "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 2222
logpath = /var/log/secure
EOF

systemctl start fail2ban
systemctl enable fail2ban

# 4. ENABLE AUTOMATIC SECURITY UPDATES
echo "Enabling automatic security updates..."
dnf install -y dnf-automatic
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer

# 5. CONFIGURE NGINX
echo "Configuring nginx..."
systemctl start nginx
systemctl enable nginx

# Create security-focused landing page
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Hardened EC2 Server</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 50px auto;
            background: rgba(0,0,0,0.4);
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { font-size: 36px; text-align: center; margin-bottom: 30px; }
        .security-badge {
            background: #10b981;
            padding: 10px 20px;
            border-radius: 20px;
            font-size: 14px;
            display: inline-block;
            margin: 5px;
        }
        .security-list {
            background: rgba(0,0,0,0.2);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid #10b981;
        }
        .security-item {
            padding: 10px 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        .security-item:last-child {
            border-bottom: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Production-Hardened EC2 Server</h1>
        
        <div style="text-align: center; margin: 30px 0;">
            <span class="security-badge">✓ SSH Hardened</span>
            <span class="security-badge">✓ Firewall Configured</span>
            <span class="security-badge">✓ Fail2ban Active</span>
            <span class="security-badge">✓ Auto Updates</span>
        </div>

        <div class="security-list">
            <h3>🛡️ Security Measures Implemented:</h3>
            <div class="security-item">
                <strong>SSH Port:</strong> Changed from 22 to 2222 (security through obscurity + reduces automated attacks)
            </div>
            <div class="security-item">
                <strong>Root Login:</strong> Disabled (prevents direct root access)
            </div>
            <div class="security-item">
                <strong>Password Auth:</strong> Disabled (SSH key-only authentication)
            </div>
            <div class="security-item">
                <strong>Fail2ban:</strong> Active (auto-blocks IPs after 3 failed login attempts for 1 hour)
            </div>
            <div class="security-item">
                <strong>Firewall:</strong> Only ports 2222 (SSH) and 80 (HTTP) allowed
            </div>
            <div class="security-item">
                <strong>Auto Updates:</strong> Enabled (security patches applied automatically)
            </div>
            <div class="security-item">
                <strong>Max Auth Tries:</strong> 3 attempts before connection dropped
            </div>
        </div>

        <div style="background: rgba(255,193,7,0.2); padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 4px solid #ffc107;">
            <strong>⚠️ Connection Info:</strong><br>
            SSH is now on port 2222, not 22<br>
            Connect using: <code>ssh -i key.pem -p 2222 ec2-user@[IP]</code>
        </div>

        <div style="text-align: center; margin-top: 40px; font-size: 14px; opacity: 0.8;">
            <p><strong>Built by:</strong> David - Week 8 Security Project</p>
            <p>Production-ready security configuration via User Data automation</p>
        </div>
    </div>
</body>
</html>
EOF

# 6. CREATE SECURITY REPORT
cat > /home/ec2-user/security-report.txt << EOF
===========================================
EC2 SECURITY HARDENING REPORT
===========================================
Hardened at: $(date)
Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)

IMPLEMENTED SECURITY MEASURES:
-------------------------------
✓ SSH port changed: 22 → 2222
✓ Root login disabled
✓ Password authentication disabled
✓ Fail2ban installed and configured
✓ Firewall (firewalld) active
✓ Automatic security updates enabled
✓ SSH max auth tries: 3
✓ SSH login grace time: 30 seconds

FIREWALL RULES:
---------------
Allowed ports:
- 2222/tcp (SSH - custom port)
- 80/tcp (HTTP)

FAIL2BAN CONFIG:
----------------
Ban time: 1 hour
Max retries: 3
Find time: 10 minutes

NEXT STEPS:
-----------
1. Update security group to allow port 2222 instead of 22
2. Test SSH connection on new port
3. Monitor fail2ban logs: sudo tail -f /var/log/fail2ban.log
4. Check firewall status: sudo firewall-cmd --list-all

===========================================
EOF

chown ec2-user:ec2-user /home/ec2-user/security-report.txt

echo "=== Hardening completed at $(date) ==="
echo "Security report available at: /home/ec2-user/security-report.txt"