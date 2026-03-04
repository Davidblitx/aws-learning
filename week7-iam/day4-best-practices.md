# Week 7 Day 4: IAM Best Practices & Security Hardening

## What I Configured Today

### 1. Root Account Hardening
- ✅ MFA enabled (already done Monday)
- ✅ Access keys deleted
- ✅ Not used for daily work

### 2. MFA Enforcement
- Created: `Force-MFA-Policy`
- Attached to: Developers group
- Effect: Users without MFA can only set up MFA

### 3. CloudTrail Enabled
- Trail name: management-events-trail
- Scope: All regions
- Logs: Management events (read + write)
- Storage: S3 bucket cloudtrail-logs-XXXXX

### 4. IAM Access Analyzer
- Enabled: default-analyzer
- Findings: [list any findings and how you addressed them]

### 5. Password Policy
- Minimum length: 14 characters
- Complexity: uppercase, lowercase, number, symbol
- Expiration: 90 days
- No reuse: 5 previous passwords

## The 12 Best Practices (Summary)

1. Never use root for daily work
2. Enable MFA on all humans
3. Apply least privilege
4. Use groups for permissions
5. Rotate access keys (90 days)
6. Enable CloudTrail
7. Use Organizations (multi-account)
8. Monitor for security issues
9. Use SCPs (advanced)
10. Enable MFA Delete (critical data)
11. Set password policy
12. Review permissions regularly

## Security Audit Checklist
- Root account:
✅ MFA enabled
✅ No access keys
✅ Not used for daily work

- IAM users:
✅ All have MFA (or policy enforces it)
✅ Following least privilege
✅ Organized in groups
✅ Password policy enabled

- IAM roles:
✅ EC2 instances use roles (not access keys)
✅ Trust policies are restrictive

- Monitoring:
✅ CloudTrail enabled
✅ IAM Access Analyzer running
✅ Billing alerts set up

- Access keys:
✅ No root access keys
✅ User access keys <90 days old (or deleted if not used)

## Questions I Can Answer

**1. Why should root account never have access keys?**
If the Root account has Access Keys, those keys have total, un-revocable power over your entire AWS billing and infrastructure. Unlike an IAM user, you cannot restrict Root's permissions with a policy. If those keys leak, a hacker can delete your entire account, including your backups, and lock you out permanently.

**2. What does the Force-MFA-Policy do?**
It acts as a "Conditional Gate." It uses a Deny statement that says: "Deny every action unless the user is authenticated with MFA." The only exception is the ability to manage their own IAM credentials so they can actually set up their MFA. This ensures that even if a password is stolen, the account remains useless to the hacker.

**3. What is CloudTrail and why is it critical?**
CloudTrail is the "Security Camera" of AWS. It records who did what, where, and when. Without it, if your account is hacked, you would have no way of knowing how the hacker got in or what resources they modified. It is the first thing auditors or forensic investigators look at during a breach.

**4. What's the principle of least privilege? Give an example.**
It means giving a user or service the minimum permissions they need to perform their job and nothing more.

Example: If a developer only needs to upload logs to one specific S3 bucket, you give them s3:PutObject for that bucket only, rather than AdministratorAccess or even S3FullAccess.

**5. Why use IAM roles instead of hardcoded credentials?**
Hardcoded credentials (Access Keys) are "static"—they live forever until deleted. Roles provide temporary, auto-rotating credentials. By using roles, you eliminate the risk of a "forgotten" key being discovered in a code repository or a configuration file.

## Real-World Security Lessons
The Capital One Breach (2019)
What went wrong: A misconfigured "Web Application Firewall" (WAF) was assigned an IAM Role with too much power. The hacker used an SSRF (Server-Side Request Forgery) attack to steal the temporary credentials of that role.

Lesson: Even when using Roles, apply Least Privilege. If that role only had access to what the WAF needed, the hacker couldn't have reached the S3 buckets containing 100 million customer records.

The Uber Breach (2022)
What went wrong: A hacker used "MFA Fatigue" (spamming the employee with MFA requests until they clicked 'Approve') to gain access. Once inside, they found hardcoded admin credentials in a PowerShell script on an internal network drive.

Lesson: MFA is great, but internal "secrets" must be stored in services like AWS Secrets Manager, never in plain-text scripts or code.

## What I'd Do Differently in Production

- Enable CloudWatch Logs for CloudTrail (real-time monitoring)
- Set up automated alerts for security findings
- Enable GuardDuty (threat detection)
- Use AWS Config (compliance monitoring)
- Implement automated remediation (Lambda functions)

## Next: Friday - Review & Practice