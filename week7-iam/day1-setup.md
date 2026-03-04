# Week 7 Day 1: AWS Account Setup & Security

## What I Completed Today

### Account Creation
- Created AWS Free Tier account
- Account ID: [my account ID from console]
- Primary region: US East (Ohio) / us-east-2

### Security Setup
✅ Root account MFA enabled (Google Authenticator)
✅ IAM admin user created: david-admin
✅ IAM admin user MFA enabled
✅ Billing alerts configured ($1, $5, $10)
✅ IAM billing access enabled

### Console Sign-In URL
`https://[my-account-id].signin.aws.amazon.com/console`

## Key Concepts Learned

### Root Account
- Has unlimited power over AWS account
- Should NEVER be used for daily work
- Only for emergency recovery or account-level settings
- MUST have MFA enabled
- From today forward: LOCKED DOWN

### IAM Admin User
- Has AdministratorAccess policy (can do almost everything)
- This is what I use for daily work
- Also has MFA for security
- Can access billing (after root enabled IAM billing access)

### Authentication vs Authorization
**Authentication (AuthN):** Who are you?
- Root account: email + password + MFA
- IAM user: username + password + MFA
- IAM role: Assumed by services (no password)

**Authorization (AuthZ):** What can you do?
- Defined by IAM policies
- AdministratorAccess = can do everything
- Custom policies = specific permissions

### Free Tier Limits (Critical to Remember)
- **EC2:** 750 hours/month of t2.micro or t3.micro
  - = 1 instance running 24/7 for free
  - = 2 instances running 12h/day each
  - Exceeding = ~$0.01/hour charge
  
- **S3:** 5 GB storage, 20k GET requests, 2k PUT requests
  - Exceeding = ~$0.023/GB/month
  
- **RDS:** 750 hours/month of db.t2.micro, 20 GB storage
  - Exceeding = ~$0.02/hour
  
- **Data Transfer:** 100 GB outbound to internet/month
  - Exceeding = $0.09/GB

### Billing Protection Strategy
- CloudWatch billing alarms at $1, $5, $10
- Email alerts for Free Tier usage
- All billing metrics MUST be viewed in US East (N. Virginia) region
- Monthly review of Cost Explorer

## Questions I Can Answer

**1. Why should root account never be used for daily work?**

Because it has unlimited power. If compromised (password stolen, session hijacked), an attacker can:
- Delete all resources
- Spin up expensive GPU instances
- Change account settings
- Lock you out of your own account
- Steal all data

Best practice: Lock it down with MFA, use IAM users with appropriate permissions.

**2. What happens if someone gets my root password but I have MFA enabled?**

They still can't log in. MFA is "something you have" (phone with authenticator app) not just "something you know" (password). Without access to my physical phone, they can't generate the 6-digit code required to complete login.

**3. If I run 2 t2.micro instances 24/7 for a month, will I stay in free tier?**

No. Math:
- Free tier: 750 hours/month total
- 2 instances: 2 × 24 hours × 30 days = 1,440 hours
- Overage: 1,440 - 750 = 690 hours
- Cost: 690 hours × $0.0116/hour ≈ $8/month

To stay free: Run 1 instance 24/7 OR 2 instances 12h/day each.

**4. What's the difference between IAM user and IAM role?**

**IAM User:**
- For humans
- Has long-term credentials (username, password)
- Has access keys (if programmatic access needed)
- Permissions attached via policies

**IAM Role:**
- For services/applications
- No long-term credentials
- Assumed temporarily by EC2, Lambda, etc.
- Provides temporary security credentials
- Example: EC2 instance assumes role to access S3 (no hardcoded keys)

I'll learn roles in detail on Thursday.

## Security Checklist
✅ Root account: MFA enabled, not used
✅ IAM admin: MFA enabled, daily use
✅ Billing alerts: Active and confirmed
✅ Free Tier limits: Documented and understood
✅ Console sign-in URL: Bookmarked

## What I'm Uncertain About (To Learn This Week)
- How exactly do IAM policies work? (Tuesday)
- What's the syntax for writing custom policies? (Wednesday)
- How do roles differ from users in practice? (Thursday)
- What are all the IAM best practices? (Friday)

## Next: Tuesday - IAM Deep Dive
Topics: Users, Groups, Roles, Policies in detail
Goal: Understand how to structure IAM for a team