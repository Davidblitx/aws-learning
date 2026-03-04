# Simple IAM Exercise - My Own S3 Access

## What I Built
- S3 bucket: david-work-bucket-20260226
- IAM policy: DavidWorkBucketAccess
- IAM user: david-limited (with only this policy)

## The Policy (What I Wrote)
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SeeBucketList",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        },
        {
            "Sid": "AccessSpecificBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::david-work-bucket-20260226",
                "arn:aws:s3:::david-work-bucket-20260226/*"
            ]
        }
    ]
}

## Test Results

### Test 1: See S3 buckets
Result: Success
Why: Because of the action "s3:ListAllMyBuckets" in the policy

### Test 2: View files in my bucket
Result: Success
Why: Because of the action "s3:ListBucket"

### Test 3: Download file
Result: Success
Why: Because of the action "s3:GetObject"

### Test 4: Upload file
Result: Success
Why: Because of the action "s3:PutObject"

### Test 5: Delete file
Result: FAILED
Why: Because no DeleteObject in policy

### Test 6: Access EC2
Result: FAILED
Why: Because no EC2 permissions

## What I Learned

1. **Policies are whitelists, not blacklists**
   - In AWS, everything is Denied by default. A "whitelist" means you must explicitly name every single action you want to allow. If you don't specifically say "Allow Delete," AWS assumes it's a "No," even if you have "Allow All" for other S3 actions.
   
2. **Why you need ListAllMyBuckets for Console**
   - The AWS S3 Console is a visual dashboard that tries to show you a list of every bucket name in your account as soon as you open it. Without s3:ListAllMyBuckets applied to the "All Resources" (*) level, the console can't populate that list, and you get a red "Access Denied" error box immediately.

3. **Difference between bucket and object permissions**
   - arn:aws:s3:::bucket-name (the bucket itself) - Permissions here let you do "container" level things, like s3:ListBucket (seeing the list of files inside).

   - arn:aws:s3:::bucket-name/* (objects inside) - The /* is a wildcard that applies to the actual files. You need this for s3:GetObject (download) and s3:PutObject (upload).

4. **What "least privilege" means in practice**
   - In this exercise, it meant giving david-limited exactly what he needed to do his job (Upload/Download) but not giving him the power to delete his mistakes or browse the company's EC2 servers.

## Questions I Can Now Answer

**Q: Why did delete fail even though upload succeeded?**
A: Because IAM is granular. s3:PutObject and s3:DeleteObject are completely separate permissions. Just because you have the "key" to put something in a room doesn't mean you have the "authority" to throw things away.

**Q: Why use two separate Statement blocks in the policy?**
A: Because they have different Scopes. The first block needs to look at everything (*) just to show the bucket names on the dashboard. The second block needs to be restricted only to your specific work bucket for security.

**Q: Could david-limited access OTHER S3 buckets?**
A: He could see the names of other buckets because of s3:ListAllMyBuckets, but he could not see the files inside them or interact with them in any way. AWS would block him because those buckets aren't listed in his "Resource" section.

## Time Taken: _10__ minutes

## Confidence Level: _6-7_/10
[How confident are you that you understand this?]