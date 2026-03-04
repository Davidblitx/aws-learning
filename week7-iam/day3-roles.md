# Week 7 Day 3: IAM Roles

## What I Built Today

### 1. EC2-S3-ReadOnly-Role
- Trust policy: EC2 service
- Permissions: AmazonS3ReadOnlyAccess
- Tested: EC2 instance accessed S3 without credentials

### 2. EC2-S3-ReadWriteSpecific-Role
- Trust policy: EC2 service
- Custom permissions:
  - Read from: source-data-bucket-12345
  - Write to: destination-data-bucket-67890
- Tested: Worked as expected, other buckets blocked

## Key Learnings

### Why Roles Exist
You are working on a project that involves api keys. If you put those keys in your code and push it to GitHub, a hacker can steal them in seconds and run up a $50,000 bill on your account. Roles solve this by removing the need for permanent keys entirely. They allow services to talk to each other securely without a human ever touching a password or a key.

### How Roles Work
When you attach a role to an EC2 instance, the instance uses the Instance Metadata Service (IMDS) to "assume" the role. Behind the scenes, AWS generates Temporary Security Credentials (an Access Key, Secret Key, and a Session Token). These credentials expire every few hours and are automatically rotated by AWS, so even if one set is somehow stolen, it becomes useless very quickly.

### Trust Policy vs Permissions Policy
Trust Policy: This is the "Who can wear the hat?" rule. It defines which service (like EC2 or Lambda) is allowed to "assume" the role.

Permissions Policy: This is the "What can I do while wearing the hat?" rule. It defines the actual actions (like s3:GetObject) the service can perform once it has the role.

## Questions I Can Answer

**1. What's the difference between IAM role and IAM user?**
An IAM User is a permanent identity for a person or a specific app, usually with long-term passwords or keys. An IAM Role is a temporary identity that can be "assumed" by anyone or any service that is trusted. Users are like having a permanent Staff ID card; Roles are like a "Visitor Badge" you pick up at the front desk for a specific task and return when you're done.

**2. How does an EC2 instance get credentials from a role?**
The instance retrieves them from its own internal metadata service (at the magic IP 169.254.169.254). When your code (like boto3) runs, it automatically checks this IP, finds the temporary credentials, and uses them to sign your requests.

**3. Why are roles more secure than access keys?**
Access Keys are permanent and static—if they leak, they stay valid until you manually delete them. Roles use temporary and dynamic credentials. There is no "key" sitting in a file for a hacker to find, and since they rotate automatically, the "window of risk" is tiny.

**4. What's a trust policy?**
A trust policy is a JSON document that defines the Principal (the entity) that is allowed to use the role. Without a trust policy, a role is like a locked door with no keyhole—nobody can get in.

**5. Can a Lambda function use an IAM user? Should it?**
Technically, you could hardcode a User's Access Keys into a Lambda, but you should never do it. Lambda functions are designed to use Roles. This ensures the function only has permissions while it is actually running and follows the best practice of "No Long-Lived Credentials."

## Real-World Scenario

**Bad way:**
```python
s3 = boto3.client('s3',
    aws_access_key_id='AKIAXXXXXX',
    aws_secret_access_key='wJalrXXXXX'
)
```

**Good way:**
```python
# EC2 instance has role attached
s3 = boto3.client('s3')  # No credentials needed!
```

## Clean Up Done
✅ EC2 instance terminated
✅ S3 buckets deleted (or kept for future use)
✅ Roles kept (no cost)

## Next: Thursday - IAM Best Practices