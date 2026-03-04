# Week 7 Day 5: IAM Review & Knowledge Consolidation

## Rapid Fire Questions - My Answers
Basic Concepts
1. What are the four core components of IAM?
2. What's the difference between authentication and authorization?
3. What's the difference between IAM user and IAM role?
4. What does "Explicit Deny always wins" mean?
5. What is an ARN? Write the ARN for an S3 bucket called "data-lake".

Policies (Core understanding)
6. What are the three types of IAM policies?
7. What's the difference between identity-based and resource-based policies?
8. This policy is attached to a user. What can they do?
json{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::company-docs/*"
}
9. Why use managed policies instead of inline policies?
10. Can a user have multiple policies attached? What happens if one allows an action and another denies it?

Roles (Critical for real-world)
11. How does an EC2 instance get temporary credentials from an IAM role?
12. What are the two parts every IAM role must have?
13. Why are IAM roles more secure than hardcoded access keys?
14. Can you attach an IAM role to a Lambda function? Why would you?
15. What happens when an IAM role's permissions policy is updated while an EC2 instance is using it?

Security & Best Practices (Job interview level)
16. Why should root account never be used for daily work?
17. What does "principle of least privilege" mean? Give a real example.
18. How often should access keys be rotated?
19. What does CloudTrail log? Why is it critical for security?
20. What would you do if you discovered an IAM user with AdministratorAccess who only needs S3 read access?

Real-World Scenarios (This is how you prove understanding)
21. A developer needs to run a Python script on their laptop that uploads files to S3. What's the secure way to give them access?
22. You're setting up a web application on EC2 that needs to read from RDS database and write to S3. How do you handle credentials?
23. You see an S3 bucket with public read access in IAM Access Analyzer. The team says "we need it public for our website." How do you verify this is safe?
24. A contractor leaves the company. What IAM actions do you take immediately?
25. You get a $500 AWS bill. How would you use IAM and CloudTrail to investigate what happened?

### Answers
1. Users, Groups, Roles, and Policies.

2. Authentication is "Who are you?" (Login/MFA). Authorization is "What can you do?" (Permissions).

3. A User has long-term credentials (password/keys). A Role is temporary and is "assumed" by someone or something.

4. It means if any policy says "Deny," it overrides every "Allow" policy attached to that user. Deny > Allow.

5. Amazon Resource Name. For a bucket: arn:aws:s3:::data-lake.

Policies
6. AWS Managed (by AWS), Customer Managed (by you), and Inline (embedded in a user/role).

7. Identity-based:Means attached to a User/Role ("I can touch that bucket"). Resource-based: Attached to the resource ("That user can touch me").

8. They can Download/Read (GetObject) any file inside the company-docs bucket. They cannot list the files or delete them.

9. Reusability. You can attach one managed policy to 100 users; if you update it once, all 100 are updated. Inline policies are a nightmare to manage at scale.

10. Yes. If one allows and one denies, the Deny wins and the action is blocked.

11. Roles (Real-World Utility)
Through the Instance Metadata Service (IMDS). The EC2 "asks" the internal AWS IP for temporary tokens.

12. A Permissions Policy (What can it do?) and a Trust Policy (Who can assume it?).

13. Because roles use temporary security tokens that expire. Access keys are static and never expire unless you manually rotate them.

14. Yes. To give the Lambda permission to talk to other services (like writing to DynamoDB) without hardcoding credentials.

15. The update is immediate. The next time the EC2 uses the role to make an API call, it will use the new permissions.

Security & Best Practices
16. Because it has unrestricted power. If a root account is compromised, the entire business can be deleted instantly.

17. Give only the permissions needed for the job. Example: A dev working on a frontend site needs S3 access for CSS files, not RDS "Delete Database" access.

18. Every 90 days is the industry standard (or even shorter in high-security environments).

19. Every single API call (who did what, when, and from where). It is the "security camera" of your AWS account.

20. Apply the Least Privilege rule. Revoke AdministratorAccess and attach a specific S3ReadOnly policy immediately.

Real-World Scenarios
21. Use IAM Identity Center (SSO). The developer runs aws sso login to get short-lived credentials on their laptop instead of permanent Access Keys.

22. Attach an IAM Role to the EC2 instance. The web app uses the AWS SDK to automatically fetch temporary credentials from that role.

23. Check the data. If it contains logs or PII (Personal Information), it’s a disaster. If it’s strictly public website images, it’s fine—but it's better to use CloudFront with Origin Access Control (OAC) to keep the bucket private.

24. Deactivate Access Keys, delete their IAM User, and revoke active sessions to kick them out of any current logins.

25. Use Cost Explorer to see which service cost $500, then use CloudTrail to search for the "Create" or "Run" events during that timeframe to see which IAM User launched the expensive resources.

## Hands-On Challenge: PayNaija IAM Design

See file: **week7-iam/paynaija-iam-design.md** for the full architecture including the Developers, DevOps, Analyst, and CEO roles.

## Troubleshooting Scenarios

### Scenario 1: Access Denied to S3
Process: 
1. Scope Check: Did the user try to list buckets or open one? Listing requires Resource: "*".
2. Policy Audit: Look at the attached policies in the IAM console. Is there a Deny statement (like an MFA requirement) that hasn't been met?.
3. Tab Verification: Ensure the user isn't on the Directory Buckets tab unless they specifically have s3express permissions.

### Scenario 2: EC2 Can't Access S3
Process:
1. Identity Check: Verify if an IAM Role is attached to the instance using the "Actions > Security > Modify IAM Role" menu in the EC2 console.

2. Permission Check: Does the Role’s policy allow the specific S3 action?

3. Connectivity: Ensure the instance has internet access or an S3 VPC Endpoint to talk to the service.

### Scenario 3: Password Change Blocked
Analysis: By default, IAM users cannot change their own passwords unless granted permission.
Solution: Attach the AWS Managed Policy IAMUserChangePassword to the group or user.

## Week 7 Overall Reflection

### What I Learned This Week
I learned that IAM is the "entry point" to everything in AWS. It’s not just about passwords; it’s about Identity, Authentication, and Authorization. I mastered the difference between managed and inline policies and how to stop hardcoding keys.

### How My Understanding Changed
I used to think "Admin" was the only way to work. Now I realize that "Least Privilege" makes life easier because it prevents accidental deletions. The biggest "aha!" moment was realizing that listing buckets is a global action while reading files is a resource action.

### Ready for Week 8?
Yes. I have a strong grasp of how permissions work. Moving to EC2 will feel much safer now that I know how to use Roles instead of passing around .pem keys and Access Keys.

## Next: Saturday - Week 7 Project