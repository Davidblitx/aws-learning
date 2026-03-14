# Week 9 Days 4-5: S3 Static Website & EBS Overview

## Day 4: S3 Static Website Hosting

### What I Built
- Static website hosted on S3
- URL: http://david-portfolio-site-20260315.s3-website.us-east-2.amazonaws.com
- Files: index.html, error.html
- Cost: ~$1-2/month for personal site

### Configuration
- Enabled static website hosting
- Index document: index.html
- Error document: error.html
- Made bucket publicly readable (bucket policy)

### Key Learning
- S3 can host websites without EC2
- Perfect for static sites (HTML/CSS/JS)
- Not for dynamic sites (need server-side code)
- Very cheap, very fast, very scalable

## Day 5: EBS Quick Overview

### What is EBS?
- **EBS = Elastic Block Store**
- Block storage for EC2 instances
- Like a hard drive attached to EC2
- Persists independently of instance

### EBS vs S3

| Feature | EBS | S3 |
|---------|-----|----| 
| **Type** | Block storage | Object storage |
| **Use** | Attached to EC2 | Standalone, accessed via HTTP |
| **Access** | One EC2 at a time | Multiple users simultaneously |
| **Performance** | Low latency (local disk) | Higher latency (network) |
| **Cost** | ~$0.10/GB/month | ~$0.023/GB/month |
| **Use case** | OS drives, databases | Backups, media files, static sites |

### When to Use Each

**Use EBS for:**
- EC2 root volumes (OS disk)
- Databases (MySQL, PostgreSQL)
- Applications needing low-latency disk I/O

**Use S3 for:**
- Backups and archives
- Static websites
- Media files (images, videos)
- Data lakes and analytics
- Application file uploads

### EBS Volume Types (Quick Reference)

**gp3 (General Purpose SSD):**
- Most common
- Balanced price/performance
- Use for: Boot volumes, dev/test

**io2 (Provisioned IOPS SSD):**
- High performance
- Use for: Production databases

**st1 (Throughput Optimized HDD):**
- Cheaper, slower
- Use for: Big data, data warehouses

**sc1 (Cold HDD):**
- Cheapest
- Use for: Infrequent access

### EBS Snapshots
- Point-in-time backups of EBS volumes
- Stored in S3 (you don't see them in S3 Console)
- Incremental (only changed blocks backed up)
- Can create new volumes from snapshots

### Key Insight
- **EBS = attached storage** (like USB drive)
- **S3 = networked storage** (like Dropbox)
- Use the right tool for the job

---

**Week 9 COMPLETE ✅**

**What I mastered:**
- S3 fundamentals (buckets, objects, storage classes)
- S3 security (bucket policies, IAM, encryption)
- S3 versioning & lifecycle
- S3 static website hosting
- EBS vs S3 (when to use each)

**Next:** Week 10 - VPC & Networking
