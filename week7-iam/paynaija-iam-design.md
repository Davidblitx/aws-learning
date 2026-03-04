## 1. Account Structure
Root Account: This is "God Mode". Once IAM is set up, we lock the credentials in a physical safe and never use it for daily work.

Security: * Enable hardware-based MFA immediately. Delete all Root Access Keys so no one can script against the root account. Set up a "Break Glass" email address (e.g., security-admin@paynaija.com).

## 2. IAM Users
Who: Every human (3 Developers, 1 DevOps Engineer, 1 Data Analyst, 1 CEO) gets a unique IAM user. No sharing.

Naming Convention: first.last (e.g., alice.chima, segun.devops).

MFA: Non-negotiable. No MFA = No access to any AWS services.

## 3. IAM Groups
**Group: Developers**
- Members: Alice, Bob, Charlie
- Permissions needed:
  - EC2: Launch, stop, terminate instances in dev environment
  - RDS: Connect to dev database (not prod)
  - S3: Read/write to dev-code-bucket
  - CloudWatch: View logs
- Why: Developers need to test code in dev environment
- What they DON'T get: Production access, IAM changes, billing access

**Group: Admin**
- Members: David(DevOps Engineer)
- Permissions needed:
  - IAM: Full control to create users, groups, and roles.
  - Organization-wide: Full access to all services (EC2, S3, RDS, etc.) across the account.
  - Security: Ability to enable CloudTrail and manage GuardDuty.
- Why: The DevOps engineer needs "God Mode" to build the entire infrastructure from scratch and fix high-level blocking issues.
- What they DON'T get: Ideally, they shouldn't use the Root Account for daily tasks; they should perform all admin work via this IAM group.

**Group: DataAnalyst**
- Members: Tunde
- Permissions needed:
  - S3: GetObject and ListBucket for the transaction-data-bucket
  - Athena/Redshift: Ability to run queries on processed data.
  - QuickSight: Permission to create and view visualization dashboards.
- Why: The analyst needs to see transaction trends to help the startup make business decisions.
- What they DON'T get: They cannot delete data, access raw "payment-secrets" buckets, or change any server configurations.

**Group: Executive**
- Members: CEO
- Permissions needed:
  - Billing: Full access to the Billing Dashboard, Cost Explorer, and Invoices.
  - ReadOnly: Global ReadOnlyAccess to see what resources are running without the ability to click "Delete".
  - Support: Ability to open support cases with AWS.
- Why: The CEO needs to monitor the "burn rate" (costs) and verify that the team is actually building the platform.
- What they DON'T get: Any "Write" or "Delete" permissions. They shouldn't be able to accidentally shut down a database or change a security group.

## 4. IAM Roles
**Role: EC2-App-Server-Role**
- Trust: EC2 service
- Permissions:
  - RDS: Connect to prod database
  - S3: Read from config-bucket, write to logs-bucket
  - Secrets Manager: Read database credentials
- Use case: Production app servers assume this role to access resources
- Why: No hardcoded credentials in application code

**Role: Lambda-Payment-Processor-Role**
- Trust: Lambda service
- Permissions:
  - DynamoDB: dynamodb:PutItem and dynamodb:UpdateItem for the Transactions table.
  - SNS: sns:Publish to send payment confirmation SMS/Emails to customers.
  - SCloudWatch Logs: Permission to create log groups and upload logs (for debugging).
- Use Case: This role is for our serverless functions that handle the actual "Pay" button clicks.
- Why: Lambdas are "short-lived." This role ensures that the code only has permission to touch the database during the few seconds it takes to process a transaction.

**Role: DevOps-Admin-CrossAccount-Role**
- Trust: arn:aws:iam::[Your-Dev-Account-ID]:root (Allows your main DevOps user to jump into this account).
- Permissions:
  - AdministratorAccess (or a restricted version for auditing).
- Use Case: This allows you (the DevOps Engineer) to log into the Production account from your Development account without having a separate set of passwords for each.
- Why: It reduces "Credential Fatigue." You stay logged into one dashboard and "Switch Roles" to manage different environments safely.

## 5. Policies (Custom JSON)
**Developer Policy (Specific S3 + Console Access)**
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3Dashboard",
            "Effect": "Allow",
            "Action": ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
            "Resource": "*"
        },
        {
            "Sid": "DevBucketFullAccess",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::paynaija-dev-data",
                "arn:aws:s3:::paynaija-dev-data/*"
            ]
        }
    ]
}

**CEO Read-Only Policy**
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ce:*", 
                "organizations:Describe*",
                "s3:Get*"
            ],
            "Resource": "*"
        }
    ]
}

## 6. Security Controls
- CloudTrail: Enabled (All Regions). Critical for PayNaija because if a payment fails or money goes missing, we need an audit trail of every API call.

- MFA: Required for everyone. If MFA is not active, the Force-MFA-Policy kicks in and blocks all actions.

- Password Policy: 14 characters minimum, must change every 90 days, cannot reuse the last 5 passwords.

- Access Key Rotation: Automated rotation every 90 days via script for any service users (though we prefer Roles!).

## 7. Onboarding 
Onboarding: 
1. Create first.last user -> 
2. Attach Force-MFA-Policy -> 
3. Generate one-time password -> 
4. User logs in, changes password, sets up MFA -> 
5. Add to Group.

## 8. Offboarding
Offboarding: 
1. Disable IAM User Console Access -> 
2. Deactivate/Delete Access Keys -> 
3. Remove from all Groups -> 
4. Revoke active sessions.
