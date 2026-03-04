# Week 7 Day 2: IAM Policies Deep Dive

## What I Built Today

### 1. Developers Group
- Created group: `Developers`
- Created custom policy: `DevelopersPolicy`
- Permissions:
  - EC2 read-only (Describe*, Get*)
  - S3 full access to `dev-projects` bucket

### 2. Test User
- Created: `alice-dev`
- Member of: Developers group
- Tested permissions: 
#### What worked
- Alice was able to login successfully.
- Alice could see the list of all buckets in the account, because of AmazonS3ReadOnlyAccess policy.
- She was able to click into the dev-projects bucket and see the files inside without any errors.
#### What didnt work
- When Alice tried to upload a new test.txt file, she got an "Access Denied" error. This is because "Read Only" means exactly that—no writing allowed.
- She tried to delete an old bucket, but the button was either greyed out or returned a permissions error.
- When she navigated to the EC2 dashboard, she saw "API Error" and "Not Authorized" banners everywhere. This proved that because I didn't explicitly give her EC2 permissions, AWS defaulted to Implicit Deny.

### 3. S3 Bucket with Resource-Based Policy
- Bucket name: `david-test-bucket-7721`
- Bucket policy: Allow GetObject for anyone in my AWS account
- Tested: 
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAccountGetObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR_ACCOUNT_ID:root"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::david-test-bucket-7721/*"
    }
  ]
}

#### Test Results
1. I logged in as a new user, `test-observer`, who had zero IAM policies attached to their name. Usually, this user would see "Access Denied" for everything in S3.

2. When `test-observer` tried to download an image from david-test-bucket-7721, it worked perfectly. This proves that a Resource-Based Policy can grant access even if the user's own identity has no permissions.

3. When the same `test-observer` tried to delete that same image, they received an "Access Denied" error. This confirmed that the bucket policy was strictly limited to the "s3:GetObject" action I defined.

I tried to access a different bucket (some-other-private-bucket) with the `test-observer` account. As expected, I got "Access Denied." This proves that the "invite" from the first bucket policy only applies to that specific resource.

## Key Concepts Learned

### Policy Structure
Think of a policy as a security guard's instructions written in JSON. It has four main parts: Effect is the "Yes/No" (Allow or Deny). Action is the "What"—the specific task like s3:GetObject or ec2:RunInstances. Resource is the "Where"—the specific bucket or server this rule applies to. Finally, Condition is the "Extra Check"—an optional rule that says "only allow this if the user has MFA turned on" or "only if they are using a specific IP address."

### Managed vs Inline Policies
Managed Policies are standalone templates you can build once and "plug" into many different users or groups. AWS provides many "AWS Managed" ones, but you can make your own "Customer Managed" ones for better control. Inline Policies, on the other hand, are "hard-coded" directly into a single user or role—they don't exist anywhere else. You should almost always use Managed Policies because they are easier to update and reuse as your team grows.

### Identity-Based vs Resource-Based
Identity-Based policies are attached to the person or entity (User, Group, or Role); they tell the person what they can do. Resource-Based policies are attached directly to the thing itself (like an S3 bucket or a KMS encryption key). A good example is a "Bucket Policy": it sits on the bucket like a bouncer and decides who gets in, regardless of what the person's own ID card says.

### ARNs
An ARN(Amazon Resource Name) is the unique "social security number" for every single resource in AWS. The format is usually arn:partition:service:region:account-id:resource-type/resource-id. Three common examples would be:

1. arn:aws:s3:::my-dev-bucket (S3 is global, so the region and account ID parts are blank).

2. arn:aws:ec2:us-east-1:123456789012:instance/i-0abcdef123456.

3. arn:aws:iam::123456789012:user/admin-dave.

## Questions I Can Answer

**1. What's the difference between IAM user and IAM group?**
An IAM User is an individual person or service. An IAM Group is a collection of users (like "Developers"). It’s best practice to give permissions to the Group so that when a new dev joins, you just drop them in the group instead of manually giving them 20 different permissions.

**2. If a user has an Allow policy and a Deny policy for the same action, what happens?**
In AWS, a Deny always wins. Even if you have ten "Allow" policies, if there is even one single "Explicit Deny" hidden somewhere, the user is blocked. Security first!

**3. What does this policy do?**
```json
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "arn:aws:s3:::my-bucket/*"
}
This policy gives full power (s3:*) over every file inside the bucket named my-bucket. However, because it has the "/*" at the end, it only applies to the objects (files) inside the bucket, not the bucket settings themselves.

**4. What's wrong with this ARN? `arn:aws:s3:us-east-1::my-bucket`**
S3 is a global service, so its ARNs do not include a region. The correct format should be arn:aws:s3:::my-bucket. You should never have us-east-1 (or any region) inside an S3 ARN!

## What I'm Still Confused About
- Trust Policies: I understand how a Role gives permissions, but I’m still a bit fuzzy on how a "Trust Relationship" allows a service (like an EC2 instance) to "assume" that role.

- Evaluation Logic: If there is no Allow and no Deny (just blank), I know it’s a "Default Deny," but I’d like to see more complex examples of how multiple policies overlap.

## Next: Wednesday - IAM Roles