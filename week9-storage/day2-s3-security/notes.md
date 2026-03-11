# Week 9 Day 2: S3 Permissions & Security

## What I Learned

### Three Ways to Control S3 Access

**1. IAM Policies (User/Role-Based)**
- Attached to IAM users, groups, or roles
- Controls what that identity can do
- Example: "Alice can read/write to any S3 bucket"

**2. Bucket Policies (Resource-Based)**
- Attached to the bucket itself
- Controls who can access the bucket
- Example: "This bucket allows read from EC2 role X"

**3. ACLs (Access Control Lists) - LEGACY**
- Deprecated, not recommended
- Use IAM policies and bucket policies instead

### IAM Policy vs Bucket Policy

**When to use IAM policies:**
- Managing permissions for your team
- User-centric access control
- "What can David do?"

**When to use bucket policies:**
- Bucket-centric access control
- Cross-account access
- Public access (static websites)
- "Who can access this bucket?"

**Often use both together:**
- IAM policy: "David has S3 access"
- Bucket policy: "This bucket allows David's account"

### Permission Evaluation

**AWS checks in order:**
1. Explicit DENY? → Access denied (deny always wins)
2. Explicit ALLOW? → Access granted
3. No explicit allow? → Access denied (default deny)

## Hands-On Tasks Completed

### Created Bucket Policy for EC2 Role Access

**Policy created:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEC2RoleReadAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::024596526245:role/EC2-S3-ReadOnly-Role"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::david-learning-bucket-20260309",
        "arn:aws:s3:::david-learning-bucket-20260309/*"
      ]
    }
  ]
}
```

**What this allows:**
- EC2 instances with EC2-S3-ReadOnly-Role can list bucket and download objects
- **Cannot** upload, delete, or modify objects (read-only)

### Tested Bucket Policy with EC2 Instance

**Launched EC2 instance:**
- Instance: s3-test-instance (t3.micro, Amazon Linux 2023)
- IAM role: EC2-S3-ReadOnly-Role attached

**Test results:**
```bash
# List buckets - SUCCESS ✅
aws s3 ls
# Showed all 8 buckets

# List bucket contents - SUCCESS ✅
aws s3 ls s3://david-learning-bucket-20260309/
# Showed documents/, images/, 3 files

# Download file - SUCCESS ✅
aws s3 cp s3://david-learning-bucket-20260309/test.txt /tmp/test.txt
# Downloaded successfully

# Upload file - FAILED ✅ (Expected behavior)
aws s3 cp /tmp/upload-test.txt s3://david-learning-bucket-20260309/
# Error: AccessDenied - User not authorized to perform s3:PutObject
```

**Outcome:** Bucket policy working perfectly. Read works, write blocked.

### Added HTTPS-Only Enforcement

**Policy updated to require HTTPS:**
```json
{
  "Sid": "DenyInsecureTransport",
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:*",
  "Resource": [
    "arn:aws:s3:::david-learning-bucket-20260309",
    "arn:aws:s3:::david-learning-bucket-20260309/*"
  ],
  "Condition": {
    "Bool": {
      "aws:SecureTransport": "false"
    }
  }
}
```

**Result:** All HTTP (non-TLS) requests are denied. Only HTTPS allowed.

### Verified Encryption at Rest

**Settings confirmed:**
- Default encryption: SSE-S3 (Amazon S3-managed keys)
- All objects automatically encrypted when uploaded
- No additional cost for SSE-S3

## S3 Encryption Types

**Encryption at Rest (stored data):**
- **SSE-S3:** S3-managed keys (free, automatic)
- **SSE-KMS:** AWS KMS keys (audit logs, more control)
- **SSE-C:** Customer-provided keys (you manage keys)

**Encryption in Transit (data moving):**
- HTTPS/TLS always recommended
- HTTP deprecated for security

## Security Best Practices Implemented

✅ **Block all public access** (unless hosting public website)  
✅ **Enable default encryption** (SSE-S3 minimum)  
✅ **Enforce HTTPS only** (deny HTTP via bucket policy)  
✅ **Use IAM roles** (not access keys) for EC2/Lambda  
✅ **Principle of least privilege** (read-only when write not needed)  
✅ **Bucket policies for resource-level control**  

## Real-World Applications

**This configuration is used for:**
- Application data storage (user uploads, backups)
- Cross-account data sharing (partner integrations)
- Compliance (encryption required for PCI-DSS, HIPAA)
- Secure file distribution (pre-signed URLs)

## Key Insights

**1. Defense in depth**
- IAM policy + bucket policy + encryption = multiple layers
- If one layer fails, others protect

**2. Deny always wins**
- Explicit deny in any policy blocks access
- Use for "never allow this user to delete"

**3. Roles > Access keys**
- EC2 uses temporary credentials via role
- No secrets to manage or leak
- Auto-rotates credentials

**4. HTTPS is non-negotiable in production**
- Always enforce HTTPS-only
- Prevents man-in-the-middle attacks

## What's Next

**Day 3:** S3 Versioning & Lifecycle Policies (protect against accidental deletes, auto-archive old data)
