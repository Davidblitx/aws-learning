# Week 9 Day 1: S3 Fundamentals

## What I Learned

### Core S3 Concepts
- **S3 = Simple Storage Service** (object storage)
- **Buckets:** Containers for objects, globally unique names
- **Objects:** Files + metadata, max 5 TB per object
- **Keys:** Object identifiers (look like paths, but aren't folders)
- **Regions:** Data stays in region unless explicitly replicated

### Storage Classes
- **S3 Standard:** Frequent access, 99.99% availability, 11 9s durability
- **S3 Intelligent-Tiering:** Auto-moves between tiers based on access
- **S3 Standard-IA:** Infrequent access, cheaper storage
- **S3 Glacier:** Archival storage, very cheap, longer retrieval times

### Durability vs Availability
- **Durability (11 9s):** Will my data survive? (Yes, S3 replicates across facilities)
- **Availability (4 9s):** Can I access it right now? (Yes, ~52 min downtime/year allowed)

## Hands-On Tasks Completed

### Created S3 Bucket
**Bucket name:** `david-learning-bucket-20260309`
**Region:** us-east-2 (Ohio)
**Settings:**
- Block all public access: ✅ Enabled
- Encryption: ✅ SSE-S3 (Amazon S3-managed keys)
- Versioning: Disabled (will enable in Day 3)

### Uploaded Files via Console
- Created folder structure: documents/, images/
- Uploaded test files: test.txt, notes.txt, data.json
- Verified object URLs show AccessDenied (private bucket)

### S3 CLI Operations

**List buckets:**
```bash
aws s3 ls
# Output: 8 buckets from previous weeks' work
```

**List objects:**
```bash
aws s3 ls s3://david-learning-bucket-20260309/
# Showed: documents/, images/, and 3 files
```

**Download file:**
```bash
aws s3 cp s3://david-learning-bucket-20260309/test.txt ~/downloaded-test.txt
# Downloaded successfully
```

**Sync directory:**
```bash
aws s3 sync ~/s3-test-files/ s3://david-learning-bucket-20260309/backup/
# Uploaded 3 files
```

**Delete objects:**
```bash
aws s3 rm s3://david-learning-bucket-20260309/backup/ --recursive
# Deleted all files in backup/ folder
```

## Key Commands Learned
```bash
# List all buckets
aws s3 ls

# List bucket contents
aws s3 ls s3://bucket-name/

# Upload file
aws s3 cp local-file s3://bucket-name/

# Download file
aws s3 cp s3://bucket-name/file local-file

# Sync directory (upload all)
aws s3 sync local-dir/ s3://bucket-name/prefix/

# Delete file
aws s3 rm s3://bucket-name/file

# Delete folder (recursive)
aws s3 rm s3://bucket-name/folder/ --recursive
```

## Real-World Applications

**S3 is used for:**
- Static website hosting
- Application file storage (user uploads, profile pictures)
- Backup and disaster recovery
- Data lakes (big data analytics)
- Log aggregation
- CDN origin (CloudFront)
- ML training data storage

## Key Insights

**1. S3 is not a file system**
- No mounting to EC2 like EBS
- Access via HTTP/HTTPS APIs
- "Folders" are just key prefixes

**2. Global namespace**
- Bucket names must be unique across ALL AWS accounts worldwide
- Use your name + date to ensure uniqueness

**3. Durability is insane**
- 11 9s = lose 1 object per 10 million every 10,000 years
- S3 auto-replicates across multiple facilities

**4. Pay for what you use**
- Storage cost per GB
- Request cost per API call
- Data transfer out (downloads)

## What's Next

**Day 2:** S3 Permissions & Security (bucket policies, IAM policies, encryption)
**Day 3:** S3 Versioning & Lifecycle Policies
**Day 4:** S3 Static Website Hosting
**Day 5:** EBS Volumes & Snapshots
