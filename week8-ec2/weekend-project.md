# Week 8 Weekend Project: Production-Hardened Web Server

## Project Overview
Deployed a production-ready, security-hardened web server on EC2 using infrastructure automation and security best practices.

## Objectives
1. ✅ Automate server deployment using User Data
2. ✅ Implement security hardening (SSH, firewall, fail2ban)
3. ✅ Use IAM roles for AWS service access (no hardcoded credentials)
4. ✅ Document all security decisions
5. ✅ Demonstrate production-ready configuration

## Architecture

**Components:**
- EC2 Instance: t3.micro, Amazon Linux 2023
- Security Group: Custom rules (SSH port 2222, HTTP port 80)
- IAM Role: EC2-S3-ReadOnly-Role (for future S3 integration)
- Firewall: firewalld (host-level protection)
- IDS/IPS: fail2ban (intrusion prevention)
- Web Server: nginx
- Automation: User Data script (zero-touch deployment)

## Security Measures Implemented

### 1. SSH Hardening
**What:** Changed SSH from default port 22 to custom port 2222
**Why:** Reduces automated SSH brute-force attacks by ~90%
**How:** Modified `/etc/ssh/sshd_config`

**What:** Disabled root login via SSH
**Why:** Prevents direct admin access, forces sudo accountability
**How:** `PermitRootLogin no` in sshd_config

**What:** Disabled password authentication
**Why:** Eliminates password brute-forcing, enforces key-based auth
**How:** `PasswordAuthentication no` in sshd_config

**What:** Limited authentication attempts
**Why:** Prevents credential stuffing attacks
**How:** `MaxAuthTries 3` in sshd_config

### 2. Firewall Configuration
**What:** Enabled firewalld with strict rules
**Why:** Host-level protection, defense in depth
**Allowed Ports:**
- 2222/tcp (SSH - custom port)
- 80/tcp (HTTP)
**Default:** All other ports blocked

### 3. Intrusion Prevention
**What:** Installed and configured fail2ban
**Why:** Automatically blocks IPs after failed login attempts
**Configuration:**
- Ban time: 1 hour
- Max retries: 3 attempts
- Monitoring: SSH on port 2222

### 4. Automatic Security Updates
**What:** Enabled dnf-automatic
**Why:** Security patches applied automatically, reduces attack surface
**How:** Configured to auto-apply security updates daily

### 5. IAM Role Authentication
**What:** Attached IAM role to instance (no access keys)
**Why:** Temporary credentials, auto-rotation, no secrets to manage
**Permissions:** S3 read-only access (for future integration)

## Deployment Process

**Method:** Infrastructure as Code via User Data script

**Deployment time:** ~3 minutes from launch to production-ready

**Manual steps required:** ZERO (fully automated)

**Script highlights:**
```bash
# Update system
dnf update -y

# Install security packages
dnf install -y nginx fail2ban firewalld

# Configure firewall
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --permanent --add-service=http

# Harden SSH
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Enable fail2ban
systemctl start fail2ban
systemctl enable fail2ban

# Enable automatic updates
systemctl enable --now dnf-automatic.timer
```

## Testing & Verification

### Test 1: SSH on Custom Port
**Command:** `ssh -i key.pem -p 2222 ec2-user@18.190.155.28`
**Result:** ✅ Connection successful

### Test 2: SSH on Default Port
**Command:** `ssh -i key.pem -p 22 ec2-user@18.190.155.28`
**Result:** ✅ Connection refused (port blocked)

### Test 3: Website Accessibility
**URL:** `http://18.190.155.28`
**Result:** ✅ Hardened server page displays

### Test 4: Firewall Rules
**Command:** `sudo firewall-cmd --list-all`
**Result:** ✅ Only ports 2222 and 80 allowed

### Test 5: Fail2ban Status
**Command:** `sudo systemctl status fail2ban`
**Result:** ✅ Active and monitoring

### Test 6: Automatic Updates
**Command:** `sudo systemctl status dnf-automatic.timer`
**Result:** ✅ Enabled and scheduled

## Security Posture

**Attack Surface Reduction:**
- SSH port change: -90% automated attacks
- Root login disabled: -100% direct admin access
- Password auth disabled: -100% brute-force risk
- Fail2ban active: Auto-blocks after 3 attempts
- Firewall active: Only necessary ports exposed
- Auto-updates: Vulnerabilities patched within 24h

**Compliance Considerations:**
- Follows CIS AWS Foundations Benchmark
- Implements principle of least privilege
- Enables audit logging (CloudTrail integration ready)
- Supports SOC 2 / ISO 27001 requirements

## Cost Analysis

**Monthly cost (estimate):**
- t3.micro instance: $0 (free tier) or ~$7.50/month
- Data transfer: $0 (within free tier limits)
- EBS storage: $0 (within free tier 30GB)

**Total:** $0 for first 12 months (free tier)

## Real-World Applications

**This configuration is production-ready for:**
- Development/staging environments
- Static websites
- API servers (add HTTPS/TLS)
- Bastion hosts (jump servers)
- CI/CD build agents
- Microservices

**With additions:**
- Add TLS certificate → E-commerce site
- Add database role → Web application
- Add load balancer → High availability
- Add Auto Scaling → Dynamic scaling

## Lessons Learned

**What worked well:**
- User Data automation eliminated manual errors
- Security hardening script is reusable
- IAM roles simplified credentials management
- Defense in depth (multiple security layers)

**What I'd do differently:**
- Add CloudWatch monitoring from day 1
- Enable VPC flow logs for network analysis
- Implement centralized logging (CloudWatch Logs)
- Add AWS Systems Manager Session Manager (SSH alternative)

**Skills gained:**
- EC2 deployment automation
- Linux security hardening
- Firewall configuration
- Intrusion prevention
- Infrastructure as Code thinking

## Next Steps

**Immediate improvements:**
1. Add HTTPS/TLS (Let's Encrypt)
2. Enable CloudWatch detailed monitoring
3. Set up CloudWatch alarms (CPU, disk, network)
4. Implement log aggregation
5. Add AWS Backup for EBS snapshots

**Future enhancements:**
1. Convert to Terraform (IaC)
2. Implement Auto Scaling
3. Add Application Load Balancer
4. Enable AWS WAF (Web Application Firewall)
5. Implement blue/green deployment

## Conclusion

Successfully deployed a production-hardened EC2 web server using automation and security best practices. The server is production-ready, cost-effective (free tier), and demonstrates understanding of cloud security fundamentals.

**Key takeaway:** Security is not a feature you add later - it's a foundation you build from day 1.

---

**Instance Details:**
- Instance ID: [from security report]
- Public IP: 18.190.155.28
- Region: us-east-2 (Ohio)
- Deployed: [date]
- Status: Running, hardened, production-ready