## Root Account Security

### Current State
- Root account being used for daily work
- No MFA enabled
- Access keys exist
- High risk of compromise

### Target State
- Root account locked down
- MFA enabled with physical device backup
- No access keys
- Only used for emergency account recovery
- Activity monitored via CloudTrail

### Implementation Steps
1. Enable MFA on root account
2. Delete all root access keys
3. Document root credentials in secure location (password manager)
4. Create IAM admin user for daily work
5. Test: Verify root can't be used without MFA

### Verification
- [ ] Root MFA enabled
- [ ] Root access keys deleted
- [ ] Root not used for 7+ days (check CloudTrail)


## IAM Users

### Naming Convention
Format: `firstname.lastname`
Examples: alice.developer, bob.developer, david.devops

### Users to Create
1. **alice.developer**
   - Role: Backend Developer
   - Group: Developers
   - MFA: Required

2. **bob.developer**
   - Role: Frontend Developer
   - Group: Developers
   - MFA: Required

3. **david.devops** (me)
   - Role: DevOps Engineer
   - Group: DevOps
   - MFA: Required

4. **charlie.analyst**
   - Role: Data Analyst
   - Group: Analysts
   - MFA: Required

5. **diana.ceo**
   - Role: CEO
   - Group: ReadOnly
   - MFA: Required

### Password Policy
- Minimum length: 14 characters
- Require: uppercase, lowercase, number, symbol
- Password expiration: 90 days
- Prevent reuse: 5 passwords
- Allow users to change own password: Yes

## IAM Groups

### Group 1: Developers
**Members:** alice.developer, bob.developer

**Permissions Needed:**
- EC2: Launch, stop, terminate instances in `dev` environment only
- RDS: Connect to development databases
- S3: Full access to `payfast-dev-*` buckets only
- CloudWatch: Read logs
- Lambda: Deploy functions to dev
- API Gateway: Configure dev APIs

**Permissions NOT Granted:**
- Production environment access
- IAM changes
- Billing access
- Root account access
- CloudTrail modifications

**Policies to Attach:**
- Custom: `PayFast-Developer-Policy` (to be created)
- AWS Managed: `CloudWatchReadOnlyAccess`

---

### Group 2: DevOps
**Members:** david.devops (me)

**Permissions Needed:**
- Full EC2 access (all environments)
- Full RDS access (all environments)
- Full S3 access (all buckets)
- IAM: Create/modify roles (but not users/groups)
- CloudTrail: Read-only
- VPC: Full access
- Terraform state bucket: Full access
- CI/CD: Full access to deployment pipelines

**Permissions NOT Granted:**
- IAM user/group creation (only admin can)
- Billing account settings
- Root account access

**Policies to Attach:**
- AWS Managed: `PowerUserAccess`
- Custom: `PayFast-DevOps-IAM-Limited` (IAM role management only)

---

### Group 3: Analysts
**Members:** charlie.analyst

**Permissions Needed:**
- S3: Read-only access to `payfast-data-*` buckets
- RDS: Read-only access to analytics database
- Athena: Query data
- QuickSight: Create dashboards
- CloudWatch: Read logs and metrics

**Permissions NOT Granted:**
- Write access to any production data
- Infrastructure changes
- Code deployment

**Policies to Attach:**
- Custom: `PayFast-Analyst-Policy`
- AWS Managed: `AmazonAthenaFullAccess`

---

### Group 4: ReadOnly (For CEO and auditors)
**Members:** diana.ceo

**Permissions Needed:**
- View all resources (EC2, S3, RDS, etc.)
- View CloudWatch metrics and dashboards
- View billing and cost information
- View CloudTrail logs

**Permissions NOT Granted:**
- Modify any resources
- Deploy code
- Change configurations

**Policies to Attach:**
- AWS Managed: `ReadOnlyAccess`
- AWS Managed: `Billing` (view costs)


## Custom IAM Policies

### Policy 1: PayFast-Developer-Policy

**Purpose:** Allow developers full access to dev environment, no access to prod

**JSON:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2DevEnvironment",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Environment": "dev"
        }
      }
    },
    {
      "Sid": "S3DevBuckets",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::payfast-dev-*",
        "arn:aws:s3:::payfast-dev-*/*"
      ]
    },
    {
      "Sid": "RDSDevDatabase",
      "Effect": "Allow",
      "Action": [
        "rds:Describe*",
        "rds-db:connect"
      ],
      "Resource": "arn:aws:rds:*:*:db:payfast-dev-*"
    },
    {
      "Sid": "DenyProductionAccess",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Environment": "prod"
        }
      }
    }
  ]
}
```

**Explanation:**
- Allows EC2 actions only on instances tagged with `Environment=dev`
- Allows S3 access only to buckets starting with `payfast-dev-`
- Allows RDS connection to dev databases
- Explicitly DENIES any action on resources tagged `Environment=prod`

---

### Policy 2: PayFast-Analyst-Policy

**Purpose:** Read-only access to data, no infrastructure access

**JSON:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3DataBucketReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::payfast-data-*",
        "arn:aws:s3:::payfast-data-*/*"
      ]
    },
    {
      "Sid": "RDSAnalyticsReadOnly",
      "Effect": "Allow",
      "Action": [
        "rds:Describe*",
        "rds-db:connect"
      ],
      "Resource": "arn:aws:rds:*:*:db:payfast-analytics"
    },
    {
      "Sid": "AthenaQueryAccess",
      "Effect": "Allow",
      "Action": [
        "athena:StartQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyWriteOperations",
      "Effect": "Deny",
      "Action": [
        "*:Put*",
        "*:Create*",
        "*:Delete*",
        "*:Update*",
        "*:Modify*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Explanation:**
- Allows reading from data buckets
- Allows querying with Athena
- Allows connecting to analytics database (read-only)
- Explicitly DENIES all write operations


## IAM Roles

### Role 1: PayFast-EC2-App-Server-Role

**Purpose:** Allow application servers to access required AWS services

**Trust Policy (Who can assume):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Permissions Policy (What it can do):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ConfigAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::payfast-config/*"
    },
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:payfast/db/*"
    },
    {
      "Sid": "CloudWatchLogging",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

**Why this exists:**
- App servers need to read config from S3
- Need to retrieve database credentials from Secrets Manager
- Need to send logs to CloudWatch
- NO hardcoded credentials in application code

---

### Role 2: PayFast-Lambda-Payment-Processor-Role

**Purpose:** Allow Lambda functions to process payments

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Permissions Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/payfast-transactions"
    },
    {
      "Sid": "SQSQueueAccess",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "arn:aws:sqs:*:*:payfast-payment-queue"
    },
    {
      "Sid": "LambdaLogging",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

**Why this exists:**
- Lambda needs to read/write transaction data
- Needs to send messages to SQS queue
- Needs to log execution


## Security Controls

### 1. MFA Enforcement
**Policy:** `PayFast-Require-MFA`
- All users must have MFA enabled
- Without MFA, users can only set up MFA (can't access any resources)
- Attached to ALL groups

### 2. CloudTrail
**Configuration:**
- Trail name: `payfast-audit-trail`
- All regions: Enabled
- Management events: Read + Write
- S3 bucket: `payfast-cloudtrail-logs-[account-id]`
- Encryption: Enabled
- Log validation: Enabled

**Purpose:** Audit trail of all API calls for security investigations

### 3. IAM Access Analyzer
**Configuration:**
- Analyzer name: `payfast-access-analyzer`
- Scope: Account
- Purpose: Detect publicly accessible resources

### 4. Password Policy
- Minimum length: 14 characters
- Complexity: Uppercase, lowercase, number, symbol
- Expiration: 90 days
- No reuse: 5 previous passwords
- Allow self-change: Yes

### 5. Access Key Rotation
**Policy:**
- All access keys rotated every 90 days
- Automated reminder via CloudWatch Event + SNS
- Keys older than 90 days flagged in weekly review


## Implementation Results

### What Was Built

#### 1. Root Account
✅ MFA enabled
✅ Access keys deleted
✅ Not used for daily operations

#### 2. IAM Users Created
- alice.developer (Developers group)
- bob.developer (Developers group)
- david.devops (DevOps group)
- charlie.analyst (Analysts group)
- diana.ceo (ReadOnly group)

#### 3. IAM Groups Created
- Developers: 2 members, 3 policies attached
- DevOps: 1 member, 2 policies attached
- Analysts: 1 member, 3 policies attached
- ReadOnly: 1 member, 2 policies attached

#### 4. Custom Policies Created
- PayFast-Developer-Policy
- PayFast-Analyst-Policy
- PayFast-Require-MFA

#### 5. IAM Roles Created
- PayFast-EC2-App-Server-Role
- PayFast-Lambda-Payment-Processor-Role

#### 6. Security Controls Enabled
✅ CloudTrail (all regions)
✅ IAM Access Analyzer
✅ Strong password policy
✅ MFA enforcement

### Architecture Diagram
```
┌─────────────────────────────────────────────┐
│         ROOT ACCOUNT (Locked Down)          │
│         - MFA Enabled                       │
│         - No Access Keys                    │
│         - Emergency Use Only                │
└─────────────────────────────────────────────┘
                     │
      ┌──────────────┴──────────────┐
      │                             │
┌─────▼─────┐              ┌────────▼────────┐
│  GROUPS   │              │     ROLES       │
├───────────┤              ├─────────────────┤
│Developers │              │EC2-App-Server   │
│  DevOps   │              │Lambda-Processor │
│ Analysts  │              └─────────────────┘
│ ReadOnly  │
└───────────┘
      │
┌─────▼──────────────────────────────────┐
│            IAM USERS                   │
├────────────────────────────────────────┤
│ alice.developer  → Developers          │
│ bob.developer    → Developers          │
│ david.devops     → DevOps              │
│ charlie.analyst  → Analysts            │
│ diana.ceo        → ReadOnly            │
└────────────────────────────────────────┘
```

### Testing Results

#### Test 1: Developer Access
**Test:** Can alice.developer access dev S3 bucket?
**Result:** ✅ Success

**Test:** Can alice.developer access prod S3 bucket?
**Result:** ✅ Denied (as designed)

#### Test 2: MFA Enforcement
**Test:** Can user without MFA access EC2?
**Result:** ✅ Denied (can only set up MFA)

#### Test 3: EC2 Role
**Test:** EC2 instance with role can read from S3?
**Result:** ✅ Success (no hardcoded keys needed)

#### Test 4: CloudTrail
**Test:** Are API calls being logged?
**Result:** ✅ Success (checked Event history)

### Security Audit Checklist

✅ Root account secured (MFA, no keys)
✅ All users organized in groups
✅ Least privilege applied (developers can't access prod)
✅ MFA enforced on all users
✅ CloudTrail enabled (audit logging)
✅ IAM Access Analyzer running
✅ Strong password policy
✅ Roles used instead of access keys
✅ No hardcoded credentials

### What I Learned
Through this project, I moved from "Click-Ops" to "Security Architect." The biggest takeaways were:

By using ec2:ResourceTag/Environment is far more scalable than listing every instance ID in a policy. It allows the infrastructure to grow without needing to update IAM every time a new server is launched.

I learned that Deny statements are the "ultimate authority." By adding an explicit Deny for prod resources in the developer policy, I’ve created a safety net that prevents accidental access even if a broad Allow is added later.

I Understood that a service (EC2/Lambda) needs an identity just as much as a human does. This eliminates the "Secret in Code" anti-pattern.

### What Would I Do Differently in Production

1. Add AWS Organizations for multi-account structure
2. Enable GuardDuty for threat detection
3. Set up automated access key rotation
4. Implement break-glass procedure for emergencies
5. Add AWS Config for continuous compliance
6. Set up automated IAM policy reviews