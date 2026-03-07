# Week 8 Day 3: IAM Roles for EC2

## What I Learned
- IAM roles provide temporary credentials to EC2 instances
- No hardcoded access keys needed
- Verified role access via AWS CLI
- Read-only policy correctly blocked write operations

## Proof
- aws s3 ls worked (read access via role)
- aws s3 cp failed with AccessDenied (write blocked)
- No credentials in ~/.aws/credentials (pure role auth)

## Key Concept
EC2 + IAM Role = Secure access to AWS services without secrets

## Status
Core concept understood and verified via CLI.
Browser display had User Data bug (variable syntax) - minor technical detail.
