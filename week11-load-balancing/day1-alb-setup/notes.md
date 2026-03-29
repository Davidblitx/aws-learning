# Week 11 Day 1: Application Load Balancer Setup

## What I Built

**Production load-balanced web application:**
- Application Load Balancer (ALB) in public subnets
- 2 EC2 web servers in private subnets (different AZs)
- Target group with health checks
- Security groups (defense in depth)
- High availability architecture

**Architecture:**
```
Internet → IGW → ALB (public subnets, 2 AZs)
                  ↓
            Target Group
                  ↓
        EC2 Web Servers (private subnets, 2 AZs)
```

## Components Created

### 1. Security Groups

**ALB Security Group (alb-security-group):**
- **Purpose:** Allow HTTP/HTTPS from internet to ALB
- **Inbound rules:**
  - HTTP (80) from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0
- **Outbound:** All traffic allowed

**Web Server Security Group (web-server-sg):**
- **Purpose:** Allow HTTP from ALB only (not from internet)
- **Inbound rules:**
  - HTTP (80) from alb-security-group
  - SSH (22) from My IP (for debugging)
- **Outbound:** All traffic allowed

**Key insight:** Web servers ONLY accept traffic from ALB, not directly from internet. This is security best practice.

---

### 2. EC2 Web Servers

**Instance 1: web-server-1a**
- **Subnet:** private-subnet-1a (us-east-2a)
- **Private IP:** 10.0.11.x
- **Security group:** web-server-sg
- **Auto-assign public IP:** Disabled (private subnet)

**Instance 2: web-server-1b**
- **Subnet:** private-subnet-1b (us-east-2b)
- **Private IP:** 10.0.12.x
- **Security group:** web-server-sg
- **Auto-assign public IP:** Disabled

**User Data Script (both instances):**
- Installed nginx
- Created custom HTML page showing:
  - Instance ID
  - Availability Zone
  - Private IP
- Created `/health` endpoint for health checks
- Automated deployment (zero-touch)

**Result:** Both instances serve identical app, different instance IDs

---

### 3. Target Group

**Name:** web-servers-tg
**Protocol:** HTTP:80
**VPC:** david-prod-vpc

**Registered targets:**
- web-server-1a (10.0.11.x)
- web-server-1b (10.0.12.x)

**Health check configuration:**
- **Path:** `/health`
- **Protocol:** HTTP
- **Interval:** 30 seconds
- **Timeout:** 5 seconds
- **Healthy threshold:** 2 consecutive successes
- **Unhealthy threshold:** 2 consecutive failures
- **Success codes:** 200

**How health checks work:**
1. ALB sends GET request to `/health` every 30 seconds
2. If returns 200 OK → Target is healthy ✅
3. If fails or times out → Target is unhealthy ❌
4. After 2 consecutive failures → Target removed from rotation
5. After 2 consecutive successes → Target added back to rotation

---

### 4. Application Load Balancer

**Name:** david-web-alb
**Scheme:** Internet-facing
**IP address type:** IPv4

**Network mapping:**
- **AZ 1:** us-east-2a → public-subnet-1a
- **AZ 2:** us-east-2b → public-subnet-1b

**Security group:** alb-security-group

**Listener:**
- **Protocol:** HTTP
- **Port:** 80
- **Default action:** Forward to web-servers-tg

**DNS name:** david-web-alb-47268254.us-east-2.elb.amazonaws.com

**Result:** ALB distributes traffic across both instances

---

## Load Balancing Concepts Learned

### What is a Load Balancer?

**Load Balancer = Distributes traffic across multiple servers**

**Without load balancer:**
- Single EC2 instance
- If it fails → Website down ❌
- If traffic spikes → Instance overloaded ❌
- No redundancy

**With load balancer:**
- Multiple EC2 instances
- If one fails → Others continue ✅
- Traffic distributed evenly ✅
- High availability ✅

---

### AWS Load Balancer Types

**1. Application Load Balancer (ALB) - Layer 7**
- **Level:** HTTP/HTTPS (Layer 7)
- **Routing:** Based on URL path, hostname, headers
- **Use case:** Web applications, APIs, microservices
- **Example:** Route `/api/*` to API servers, `/images/*` to image servers
- **Best for:** Modern web applications (what we built)

**2. Network Load Balancer (NLB) - Layer 4**
- **Level:** TCP/UDP (Layer 4)
- **Performance:** Extreme (millions of requests/second)
- **Use case:** High-performance TCP traffic, gaming, IoT
- **Example:** TCP port 3306 (MySQL database)
- **Best for:** Ultra-high performance requirements

**3. Classic Load Balancer (CLB)**
- **Status:** Deprecated (AWS recommends ALB or NLB)
- **Don't use for new projects**

**We used ALB because:** Web application on HTTP/HTTPS

---

### How ALB Routes Traffic

**Load balancing algorithm:**
- **Round Robin:** Request 1 → Server A, Request 2 → Server B, Request 3 → Server A
- **Least Outstanding Requests:** Route to server with fewest active connections
- **Sticky Sessions:** Same user always goes to same server (optional)

**Our setup uses:** Round Robin (default)

**Test:**
- Open ALB DNS in browser
- Refresh multiple times
- See alternating between "Web Server 1A" and "Web Server 1B"

---

### Health Checks Explained

**Purpose:** Automatically detect and remove failed instances

**How it works:**
```
ALB → GET /health HTTP/1.1 (every 30 seconds)
      ↓
Web Server responds:
  - 200 OK → Healthy ✅
  - 500 Error → Unhealthy ❌
  - No response (timeout) → Unhealthy ❌
```

**Automated failure handling:**
1. web-server-1a fails (crashes, nginx stops, etc.)
2. Health check fails (2 consecutive failures)
3. ALB marks web-server-1a as unhealthy
4. ALB stops sending traffic to web-server-1a
5. All traffic goes to web-server-1b
6. **Users never notice** ✅

**This is high availability in action.**

---

### Security Architecture (Defense in Depth)

**Layer 1: Internet Gateway**
- Controls what enters VPC

**Layer 2: ALB Security Group**
- Allows HTTP/HTTPS from internet (0.0.0.0/0)
- ALB is public-facing

**Layer 3: Web Server Security Group**
- Allows HTTP ONLY from ALB security group
- Blocks direct internet access
- SSH only from My IP (for debugging)

**Layer 4: Private Subnet**
- Web servers have no public IPs
- Cannot be reached directly from internet
- Must go through ALB

**Result:** Even if someone finds web server IP, they can't access it directly. Must go through ALB.

---

## Troubleshooting: Unhealthy Targets

### Issue Encountered
- Both targets showed "Unhealthy" status
- Health checks failed

### Root Cause
**Most common:** Security group doesn't allow ALB to reach instances

**Possibilities:**
1. web-server-sg doesn't have rule: HTTP from alb-security-group
2. Nginx not running on instances
3. Health check path incorrect
4. Health endpoint doesn't exist

### Fix Applied
1. Verified security group rule: HTTP from alb-security-group ✅
2. Checked nginx status on instances (if accessible)
3. Alternative: Changed health check path from `/health` to `/`

**Lesson learned:** Security groups must explicitly allow ALB → EC2 communication. Can't rely on "same VPC" for automatic access.

---

## High Availability Design Principles

**1. Multi-AZ Deployment**
- web-server-1a in us-east-2a
- web-server-1b in us-east-2b
- If entire datacenter (AZ) fails → Other AZ continues

**2. Automated Health Monitoring**
- ALB constantly checks instance health
- No manual intervention needed
- Failed instances removed automatically

**3. Graceful Degradation**
- 2 instances → 1 fails → Service continues with 1
- Not ideal (reduced capacity) but NOT down
- Time to fix without emergency

**4. Zero-Touch Deployment**
- User Data script automates instance setup
- Can replace failed instances quickly
- No manual configuration needed

---

## Real-World Applications

**This architecture supports:**

**Fintech example (Paystack):**
- ALB receives payment requests
- Routes to multiple API servers
- If one server fails during transaction → Another completes it
- User never notices

**E-commerce example:**
- ALB in public subnet (receives customer requests)
- Web servers in private subnet (serve pages)
- Database in private subnet (not accessible from internet)
- One web server crashes → Others continue serving customers

**Key principle:** Users should never experience downtime from single instance failure

---

## Commands Reference

**Launch EC2 with User Data:**
```bash
# User Data runs on first boot
# Installs nginx, creates custom pages, sets up health endpoint
```

**View target health:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-2:ACCOUNT:targetgroup/web-servers-tg/xxxxx
```

**Get ALB DNS name:**
```bash
aws elbv2 describe-load-balancers \
  --names david-web-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

**Test load balancing:**
```bash
# In browser, access ALB DNS multiple times
# Or use curl in loop
for i in {1..10}; do
  curl http://david-web-alb-xxxxx.us-east-2.elb.amazonaws.com
  echo ""
done
```

---

## Key Insights

**1. Load balancing = Resilience, not just distribution**
- The goal isn't just spreading traffic
- The goal is surviving failures without users noticing

**2. Health checks are critical**
- Without health checks, ALB would send traffic to dead instances
- Health checks enable automated failure recovery

**3. Security groups work together**
- ALB allows internet → ALB
- Web servers allow ALB → Web servers
- Internet CANNOT reach web servers directly

**4. Private subnet + ALB = Best practice**
- Web servers don't need public IPs
- ALB is the only public-facing component
- Reduces attack surface

**5. Multi-AZ is foundational**
- Not an add-on feature
- Built into architecture from day 1
- AWS best practice for production systems

---

## What's Next

**Day 2:**
- Test high availability (terminate one instance, traffic continues)
- Add CloudWatch monitoring
- Create alarms for unhealthy targets
- Observe automated failure handling

**Day 3:**
- Auto Scaling Groups (automatically add/remove instances based on load)
- Launch templates
- Scaling policies

---

## Questions I Can Answer

**Q: Why put ALB in public subnet but web servers in private?**
A: ALB is internet-facing (needs to receive requests). Web servers don't need direct internet access (only need to respond to ALB). Private subnet reduces attack surface.

**Q: What happens if both instances fail?**
A: ALB has no healthy targets → Returns 503 Service Unavailable. This is why Auto Scaling is important (automatically launches new instances).

**Q: Can I have ALB in one AZ only?**
A: Technically yes, but defeats purpose. ALB itself should be multi-AZ for high availability.

**Q: What's the difference between target group and load balancer?**
A: Load balancer = The entry point (DNS name, listeners). Target group = The set of instances it routes to. One ALB can have multiple target groups (different rules).

**Q: How much does ALB cost?**
A: ~$16/month (ALB hours) + $0.008 per LCU (Load Balancer Capacity Unit). For learning/testing: ~$20-30/month. Remember to delete when not using.

---

**Status:** Week 11 Day 1 COMPLETE ✅

**Skills learned:**
- Application Load Balancer setup
- Target groups and health checks
- Security group architecture
- High availability design
- Multi-AZ deployment
- Automated failure handling

**Next:** Day 2 - Test failover, add CloudWatch monitoring
