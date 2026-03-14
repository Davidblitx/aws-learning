# Week 9 Day 3: S3 Versioning & Lifecycle Policies

## What I Learned

### S3 Versioning

**What it is:**
- Keeps multiple versions of the same object in a bucket
- Each version has a unique Version ID
- Protects against accidental deletes and overwrites

**Why it matters:**
- **Disaster recovery:** Restore previous versions if something goes wrong
- **Compliance:** Keep audit trail of all changes
- **Protection:** Accidental delete doesn't mean data loss
- **Rollback:** "Oops, wrong file uploaded" → restore old version

**How it works:**
- Upload file → Version 1 created
- Upload same filename → Version 2 created (Version 1 still exists)
- Delete file → Delete marker added (all versions still exist)
- Can restore by removing delete marker

**States:**
- **Unversioned (default):** New upload overwrites old, no history
- **Versioning-enabled:** All versions kept
- **Versioning-suspended:** Stops new versions, old versions remain

**Important:** Once enabled, you can't fully disable versioning (only suspend it)

## Hands-On Completed

### Enabled Versioning

**Bucket:** `david-learning-bucket-20260309`

**Steps:**
1. S3 → Bucket → Properties → Bucket Versioning
2. Changed from "Disabled" to "Enabled"
3. Saved changes

**Result:** All future uploads now create versions instead of overwriting

### Tested Multiple Versions

**Created test file with 3 versions:**
```bash
# Version 1
echo "Version 1 - Original content" > ~/version-test.txt
aws s3 cp ~/version-test.txt s3://david-learning-bucket-20260309/

# Version 2
echo "Version 2 - Updated content" > ~/version-test.txt
aws s3 cp ~/version-test.txt s3://david-learning-bucket-20260309/

# Version 3
echo "Version 3 - Final content" > ~/version-test.txt
aws s3 cp ~/version-test.txt s3://david-learning-bucket-20260309/
```

**Verification:**
- Console: Toggled "Show versions" → Saw all 3 versions with unique IDs
- Each version stored separately
- Latest version shown by default

### Tested Delete and Restore

**Soft delete (with delete marker):**
```bash
aws s3 rm s3://david-learning-bucket-20260309/version-test.txt
```

**Result:**
- File appears deleted in normal view
- With "Show versions" → All 3 versions still exist + delete marker
- File not actually gone, just hidden

**Restore (remove delete marker):**
- Deleted the delete marker in Console
- File reappeared
- All versions intact

**Key insight:** Versioning makes deletes reversible

### Downloaded Specific Version

**List all versions:**
```bash
aws s3api list-object-versions --bucket david-learning-bucket-20260309 --prefix version-test.txt
```

**Download old version:**
```bash
aws s3api get-object --bucket david-learning-bucket-20260309 \
  --key version-test.txt \
  --version-id [VERSION-ID] \
  ~/old-version.txt
```

**Verified old content was retrieved**

## S3 Lifecycle Policies

### What They Are

**Lifecycle rules = Automated object management over time**

**Two types of actions:**
1. **Transition actions:** Move objects between storage classes
2. **Expiration actions:** Delete objects after specified time

**Why use them:**
- **Cost optimization:** Move old data to cheaper storage automatically
- **Compliance:** Auto-delete data after retention period
- **Cleanup:** Remove temporary files automatically

### Lifecycle Rules Created

**Rule 1: Move to Glacier After 90 Days**

**Configuration:**
- **Rule name:** `Move-to-Glacier-After-90-Days`
- **Scope:** All objects in bucket
- **Transition action:**
  - Current versions → Glacier Flexible Retrieval after 90 days
  - Noncurrent versions → Glacier Flexible Retrieval after 90 days

**Purpose:** Reduce storage costs for old data

**Cost impact:**
- S3 Standard: $0.023/GB/month
- Glacier: $0.0036/GB/month
- **Savings: 84% cheaper** for archived data

---

**Rule 2: Delete Old Versions After 180 Days**

**Configuration:**
- **Rule name:** `Delete-Old-Versions-After-180-Days`
- **Scope:** All objects
- **Expiration actions:**
  - Permanently delete noncurrent versions after 180 days
  - Delete expired object delete markers (cleanup)

**Purpose:** Prevent version accumulation, control storage costs

**Result:** Old versions auto-deleted, current version remains

---

**Rule 3: Delete Temporary Files (Example)**

**Configuration:**
- **Rule name:** `Delete-Temp-After-7-Days`
- **Scope:** Prefix `temp/`
- **Expiration:**
  - Delete current versions after 7 days
  - Delete noncurrent versions after 7 days

**Purpose:** Automatic cleanup of temporary uploads

## Cost Optimization Example

**Scenario:** 1 TB of log data stored for 1 year

**Without lifecycle:**
- All in S3 Standard: 1000 GB × $0.023 × 12 = **$276/year**

**With lifecycle (Standard → IA → Glacier):**
- 30 days Standard: 1000 × $0.023 × 1 = $23
- 60 days Standard-IA: 1000 × $0.0125 × 2 = $25
- 275 days Glacier: 1000 × $0.0036 × 9 = $32.40
- **Total: $80.40/year**
- **Savings: 71% ($195.60)**

## Storage Classes Comparison

| Class | Cost/GB/mo | Use Case | Retrieval Time |
|-------|-----------|----------|----------------|
| Standard | $0.023 | Frequent access | Instant |
| Standard-IA | $0.0125 | Monthly access | Instant |
| Glacier Instant | $0.004 | Quarterly access | Instant |
| Glacier Flexible | $0.0036 | Archival | Minutes-hours |
| Glacier Deep Archive | $0.00099 | Long-term compliance | 12-48 hours |

## Best Practices Learned

**1. Separate buckets by access pattern**
- Hot data → No lifecycle
- Warm data → Transition to IA
- Cold data → Move to Glacier quickly

**2. Use prefixes for different retention**
- `logs/` → Delete after 30 days
- `backups/` → Glacier after 90 days
- `temp/` → Delete after 7 days

**3. Delete incomplete multipart uploads**
- Failed uploads waste storage
- Set expiration: 7 days

**4. Monitor with S3 Storage Lens**
- Verify lifecycle rules working
- Track cost savings

**5. Test in non-production first**
- Verify transitions work correctly
- Avoid accidental data loss

## Versioning + Lifecycle Together

**Common strategy:**
- Enable versioning for data protection
- Use lifecycle to manage version accumulation
- Example: Keep current version in Standard, move old versions to Glacier after 90 days, delete after 1 year

**Balance:**
- Versioning = data safety (costs storage)
- Lifecycle = cost control (manages growth)
- Together = protected AND cost-effective

## Real-World Applications

**Use case 1: Application logs**
- Keep 30 days in Standard (debugging recent issues)
- Move to Glacier for 1 year (compliance)
- Delete after 1 year (retention policy)

**Use case 2: Database backups**
- Daily backups with versioning enabled
- Keep 7 daily in Standard
- Move to Glacier after 7 days
- Keep 1 year total

**Use case 3: User-uploaded content**
- Versioning protects against accidental overwrites
- Lifecycle moves old versions to cheaper storage
- Delete versions older than 90 days

## Commands Reference

**Enable versioning:**
```bash
aws s3api put-bucket-versioning --bucket BUCKET-NAME \
  --versioning-configuration Status=Enabled
```

**List versions:**
```bash
aws s3api list-object-versions --bucket BUCKET-NAME --prefix FILE-NAME
```

**Download specific version:**
```bash
aws s3api get-object --bucket BUCKET-NAME \
  --key FILE-NAME \
  --version-id VERSION-ID \
  output-file.txt
```

**Delete specific version permanently:**
```bash
aws s3api delete-object --bucket BUCKET-NAME \
  --key FILE-NAME \
  --version-id VERSION-ID
```

## Key Insights

**1. Versioning is insurance**
- Small cost (storage) for huge benefit (data safety)
- In production: ALWAYS enable for critical data

**2. Lifecycle rules save money automatically**
- Set it once, forget it
- Savings compound over time

**3. Storage class choice matters**
- Match access pattern to storage class
- Don't pay Standard prices for Glacier-access data

**4. Version accumulation is real**
- 100 versions of 1 GB file = 100 GB storage
- Lifecycle rules prevent runaway costs

## Questions I Can Answer

**Q: When should I enable versioning?**
A: For any data where accidental delete/overwrite would be a problem. Production databases, configuration files, important documents.

**Q: What's the difference between suspend and disable versioning?**
A: You can't disable versioning once enabled. Suspend stops new versions but keeps existing ones.

**Q: How do lifecycle rules save money?**
A: Automatically move old data to cheaper storage classes. Example: Glacier is 84% cheaper than Standard.

**Q: Can I recover a deleted file if versioning is disabled?**
A: No. Without versioning, delete is permanent.

**Q: Do lifecycle rules apply to existing objects?**
A: Yes. When you create a rule, AWS applies it to all existing objects that match the rule's scope.

## Next Steps

**Day 4:** S3 Encryption deep dive & static website hosting
**Day 5:** EBS volumes, snapshots, and backups
**Week 10:** VPC & Networking fundamentals

---

**Status:** Week 9 Day 3 COMPLETE ✅
**Skills:** S3 versioning, lifecycle policies, cost optimization, data protection strategies
