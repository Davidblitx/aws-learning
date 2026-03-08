# Week 8 Review: AWS EC2 & Compute

## What I Learned This Week

### Core Concepts
1. **EC2 Fundamentals**
   - Virtual machines in the cloud
   - Instance types and families (t3, m5, c5, r5)
   - AMIs (Amazon Machine Images)
   - Pricing models (On-Demand, Reserved, Spot)

2. **Automation**
   - User Data scripts (bash automation on first boot)
   - Instance metadata service (169.254.169.254)
   - Zero-touch deployment
   - Infrastructure as Code thinking

3. **IAM Integration**
   - EC2 instance profiles
   - IAM roles for services
   - Temporary credentials
   - No hardcoded secrets

4. **Security**
   - Security groups (stateful firewall)
   - SSH hardening
   - fail2ban (intrusion prevention)
   - Host-level firewalls (firewalld)
   - Automatic security updates
   - Defense in depth

### Technical Skills Gained

**I can now:**
- Launch and configure EC2 instances via Console
- SSH into instances using key pairs
- Write User Data scripts for automation
- Harden SSH (custom port, disable root, key-only auth)
- Configure firewalls (security groups + firewalld)
- Install and configure fail2ban
- Attach IAM roles to EC2 instances
- Access AWS services from EC2 without credentials
- Deploy production-ready infrastructure

**I understand:**
- Why automation > manual configuration
- How instance metadata works
- The difference between security groups and host firewalls
- Why IAM roles are better than access keys
- How to think about defense in depth
- Cost optimization (free tier, instance sizing)

## Before Week 8 vs After Week 8

**Before Week 8, I could:**
- Explain what cloud computing is (theory)
- Understand IAM concepts (Week 7)
- Think about security (conceptually)

**After Week 8, I can:**
- Deploy actual infrastructure in AWS
- Automate server configuration
- Secure production systems
- Integrate IAM with compute resources
- Build complete, working solutions

**The difference:** Theory → Practice

## Challenges Faced & Overcome

### Challenge 1: User Data Script Variables
**Problem:** Used literal strings instead of variables in S3 integration script
**Solution:** Learned proper bash variable syntax `${VARIABLE}` vs `${literal-string}`
**Lesson:** Syntax matters. Test scripts before deploying.

### Challenge 2: Security Group vs SSH Port Mismatch
**Problem:** Changed SSH to port 2222 in instance, but security group still allowed port 22
**Solution:** Updated security group to allow port 2222 (Custom TCP)
**Lesson:** Security has multiple layers - changes must be coordinated

### Challenge 3: AWS Console Type Restrictions
**Problem:** Couldn't change port from 22 to 2222 when Type was "SSH"
**Solution:** Changed Type from "SSH" to "Custom TCP" to unlock port field
**Lesson:** AWS has helpful defaults, but they can be restrictive for custom configs

### Challenge 4: Connection Timeout vs Connection Refused
**Problem:** Different error messages, different meanings
**Solution:** Learned to diagnose: timeout = security group, refused = service not listening
**Lesson:** Error messages are data - learn to read them

## Key Insights

**1. Automation from Day 1**
> "If you SSH into a server to configure it manually, you're doing it wrong."

Manual setup doesn't scale. User Data scripts ensure consistency and repeatability.

**2. Security is a Foundation, Not a Feature**
> "You can't bolt on security after deployment. It must be built in from the start."

Hardening during initial deployment is 100x easier than retrofitting later.

**3. Defense in Depth**
> "One security measure is a single point of failure. Multiple layers create resilience."

Security groups + host firewall + fail2ban + SSH hardening = overlapping protection.

**4. The Power of Roles**
> "Credentials that don't exist can't be stolen."

IAM roles eliminate the entire category of "hardcoded secrets" vulnerabilities.

## Real-World Connections

**This week's skills apply to:**
- Every web application deployment
- Every microservice architecture
- Every DevOps pipeline
- Every cloud migration
- Every startup MVP
- Every enterprise infrastructure

**Industries that use this:**
- Fintech (Paystack, Flutterwave, Kuda)
- E-commerce (Jumia, Konga)
- SaaS companies
- Gaming platforms
- Media streaming
- AI/ML infrastructure

## Week 8 by the Numbers

- **Days spent:** 7 (planned), completed in concentrated effort
- **EC2 instances launched:** 6+
- **User Data scripts written:** 4
- **Security measures implemented:** 7
- **Lines of code:** ~300 (bash scripts)
- **Manual SSH configs:** 0 (all automated)
- **Hardcoded credentials:** 0 (all role-based)
- **Production-ready deployments:** 1 (weekend project)

## Self-Assessment

### Confidence Levels (1-10)

**EC2 Basics:** 8/10
- Can launch, configure, and manage instances confidently
- Understand instance types and pricing
- Know when to use EC2 vs other services

**User Data Automation:** 7/10
- Can write working User Data scripts
- Understand bash automation
- Still learning advanced scripting patterns

**IAM Roles for EC2:** 7/10
- Understand the concept deeply
- Can attach roles and verify access
- Still learning complex permission scenarios

**Security Hardening:** 8/10
- Can implement production-ready security
- Understand defense in depth
- Know common attack vectors and mitigations

**Overall EC2 Competency:** 7.5/10
- Solid foundation for real-world work
- Ready for entry-level DevOps tasks
- Still learning advanced topics (Auto Scaling, Load Balancers)

## Questions I Can Now Answer

**Interview Questions:**

1. **"What is EC2 and why would you use it?"**
   > EC2 is AWS's virtual machine service. You use it when you need compute resources that you can provision in seconds, scale dynamically, and pay only for what you use. It's the foundation of most cloud applications.

2. **"How do you automate EC2 instance configuration?"**
   > User Data scripts - bash scripts that run on first boot. This ensures every instance is configured identically and eliminates manual setup errors.

3. **"How should EC2 instances access other AWS services securely?"**
   > IAM roles attached via instance profiles. This provides temporary credentials that auto-rotate, eliminating hardcoded secrets.

4. **"Walk me through hardening an EC2 instance."**
   > Change SSH port, disable root login, enforce key-only auth, configure fail2ban, enable host firewall, set up automatic security updates, implement security groups, attach IAM roles.

5. **"What's the difference between a security group and a firewall?"**
   > Security groups are AWS's network-level stateful firewall (controls traffic to instances). Host firewalls (like firewalld) are instance-level protection. Use both for defense in depth.

## What's Next: Week 9 Preview

**Topics:**
- S3 fundamentals (object storage)
- EBS volumes (block storage)
- Storage classes and lifecycle policies
- Backup and disaster recovery
- Cost optimization strategies

**Why it matters:**
- Storage is where data lives
- Backups prevent data loss
- Understanding storage = understanding cloud architecture

## Reflection

**Biggest win this week:**
Building a production-hardened server completely automated via User Data. This isn't a tutorial project - it's real infrastructure I could deploy in a real company.

**Biggest challenge:**
Learning to think in layers - security groups, firewalls, SSH config, fail2ban all work together. Cloud infrastructure isn't one thing, it's orchestrating many things.

**Most valuable skill:**
User Data automation. This changed how I think - not "how do I configure this server" but "how do I write code that configures any server automatically."

**What surprised me:**
How much security is baked into AWS if you use it correctly. IAM roles, security groups, CloudTrail - the tools exist, you just have to use them.

**How I feel:**
Confident. Not expert-level, but capable. I could walk into an interview and discuss EC2 intelligently. I could join a team and contribute to infrastructure work.

---

**Week 8: COMPLETE ✅**
**Next: Week 9 - Storage (S3 & EBS)**




