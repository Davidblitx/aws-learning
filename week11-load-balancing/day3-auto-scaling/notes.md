# Week 11 Day 3: Auto Scaling Groups (ASG)

## What I Built

**Self-healing, auto-scaling infrastructure:**
- Launch Template (blueprint for EC2 instances)
- Auto Scaling Group (manages instance lifecycle)
- Target tracking scaling policy (CPU-based scaling)
- Integration with existing ALB and target group
- Automated instance replacement (self-healing)
- Dynamic scaling based on demand

**Architecture:**
```
User → ALB → Target Group ← Auto Scaling Group
                              ↓
                        Automatically manages:
                        - Instance launches
                        - Instance terminations
                        - Target group registration
                        - Health monitoring
                        - Capacity scaling
```

---

## Components Created

### 1. Launch Template

**Name:** web-server-template

**Purpose:** Blueprint for ASG to create identical instances

**Configuration:**
- **AMI:** Amazon Linux 2023
- **Instance type:** t3.micro
- **Security group:** web-server-sg
- **Key pair:** my-ec2-key
- **User Data:** Automated nginx installation and configuration

**Why Launch Template?**
- Consistency (all instances identical)
- Version control (can update template, roll out to new instances)
- Reusability (use same template for multiple ASGs)

**User Data Script:**
- Installs nginx
- Creates custom HTML page with instance metadata
- Creates /health endpoint for health checks
- Logs completion to /var/log/user-data.log

---

### 2. Auto Scaling Group

**Name:** web-servers-asg

**Configuration:**
- **Launch template:** web-server-template
- **VPC:** david-prod-vpc
- **Subnets:** private-subnet-1a, private-subnet-1b (multi-AZ)
- **Target group:** web-servers-tg (ALB integration)
- **Health checks:** ELB + EC2
- **Health check grace period:** 300 seconds (5 minutes)

**Capacity settings:**
- **Minimum:** 2 instances (always maintained)
- **Desired:** 2 instances (starting point)
- **Maximum:** 4 instances (scale-up limit)

**What this means:**
- ASG will ALWAYS keep at least 2 instances running
- Starts with 2 instances
- Can scale up to 4 during high demand
- Can scale down to 2 during low demand (never below)

---

### 3. Scaling Policy

**Type:** Target tracking scaling policy

**Name:** cpu-target-tracking

**Configuration:**
- **Metric:** Average CPU Utilization across all instances
- **Target value:** 50%

**How it works:**
```
If average CPU > 50% for 5 minutes:
  → ASG launches additional instance(s)
  → Distributes load across more instances
  → CPU returns to ~50%

If average CPU < 50% for 15 minutes:
  → ASG terminates extra instance(s) (but keeps min 2)
  → Reduces cost
  → CPU returns to ~50%
```

**Why 50% target?**
- Leaves headroom for traffic spikes (not running at 100%)
- Balances cost vs performance
- Industry standard for most web applications

---

## Auto Scaling Concepts Learned

### What is Auto Scaling?

**Auto Scaling = Automatically adjust number of EC2 instances based on demand**

**Problems it solves:**

**1. Manual instance management:**
- Instance crashes → Manual replacement (slow, error-prone)
- Traffic spikes → Manual scaling (too late, users affected)
- Low traffic → Paying for unused capacity (waste money)

**2. Lack of redundancy:**
- Single instance = single point of failure
- Manual multi-instance = still need manual replacement

**3. Cost inefficiency:**
- Over-provisioned → Wasting money on idle instances
- Under-provisioned → Poor user experience during peak

---

### Auto Scaling Benefits

**1. High Availability (Self-Healing)**

**What I tested:**
- Terminated an instance manually
- ASG detected instance count dropped below desired (2)
- ASG automatically launched replacement
- Total recovery time: ~6 minutes
- No manual intervention needed ✅

**Real-world scenario:**
- Instance crashes at 3 AM
- ASG detects and replaces it
- Service continues
- You wake up, check logs, see "instance replaced automatically"
- Crisis averted while you slept ✅

---

**2. Cost Optimization (Dynamic Scaling)**

**Example scenario:**
```
12 AM - 6 AM (low traffic):     2 instances → $20/month
6 AM - 9 AM (morning spike):    3 instances → $30/month
9 AM - 5 PM (business hours):   4 instances → $40/month
5 PM - 8 PM (evening spike):    3 instances → $30/month
8 PM - 12 AM (declining):       2 instances → $20/month
```

**Without Auto Scaling:** 4 instances 24/7 = $120/month

**With Auto Scaling:** Average 2.5 instances = $75/month

**Savings: 37%** (pay only for what you need)

---

**3. Performance (Automatic Capacity)**

**Traffic spike scenario:**

**Without Auto Scaling:**
```
Normal traffic: 2 instances, fast response
Traffic spike (2x): 2 instances, slow response (overloaded)
Users experience: Slow website, timeouts, frustration
```

**With Auto Scaling:**
```
Normal traffic: 2 instances, fast response
Traffic spike detected (CPU > 50%): ASG launches instances
Traffic spike (2x): 4 instances, fast response maintained
Users experience: Fast website, no degradation ✅
```

---

**4. Predictable Scaling (Scheduled Actions)**

**Use case: E-commerce Black Friday sale**

**Without scheduled scaling:**
```
9 AM: Sale starts
9:05 AM: Traffic spike, website slow
9:10 AM: Finally scale up manually
9:15 AM: New instances healthy
Result: Lost sales during 15 min of poor performance
```

**With scheduled scaling:**
```
8:45 AM: Scheduled action scales to 10 instances
9:00 AM: Sale starts, already scaled
Result: Fast website from minute 1 ✅
```

---

### Auto Scaling Group Lifecycle

**Instance states:**

**1. Pending**
- ASG launched instance
- EC2 starting up
- User Data running

**2. InService**
- Instance running
- Passed health checks
- Registered with target group
- Receiving traffic ✅

**3. Terminating**
- ASG decided to terminate (scale-in or unhealthy)
- Deregistered from target group
- Connection draining (finish existing requests)

**4. Terminated**
- Instance stopped
- Removed from ASG

---

### Health Checks Deep Dive

**Two types enabled:**

**1. EC2 Health Checks**
- AWS checks: Is instance running? Network reachable?
- System status: Hardware OK?
- Instance status: OS booted, network configured?

**Fails if:** Instance stopped, terminated, or system/instance status check fails

---

**2. ELB Health Checks (Enabled)**
- ALB sends HTTP request to /health
- Expects 200 OK response

**Fails if:**
- Nginx not running
- Health endpoint doesn't exist
- Instance not responding (app crashed)

---

**Which takes priority?**

**Both must pass for instance to be healthy:**
```
EC2 Health: ✅  ELB Health: ✅  → Healthy, receives traffic
EC2 Health: ✅  ELB Health: ❌  → Unhealthy, ASG terminates
EC2 Health: ❌  ELB Health: ✅  → Unhealthy, ASG terminates
```

**Best practice:** Enable both (what we did)
- EC2 catches infrastructure failures
- ELB catches application failures

---

### Health Check Grace Period

**Setting:** 300 seconds (5 minutes)

**Why needed?**

**Timeline of new instance:**
```
T+0s:   Instance launched (state: Pending)
T+30s:  Instance running, User Data starts executing
T+60s:  dnf update running
T+90s:  nginx installing
T+120s: nginx started, pages created
T+150s: Instance fully ready
```

**Without grace period:**
```
T+30s:  Health check runs (nginx not ready yet)
T+30s:  Health check fails → ASG marks unhealthy → Terminates
T+30s:  Launches new instance
T+60s:  New instance same issue → Terminates again
Result: Death spiral, never becomes healthy
```

**With 300s grace period:**
```
T+0s - T+300s: Health checks ignored
T+300s: First real health check (app is ready by now)
T+330s: Second health check passes
T+330s: Instance marked healthy ✅
```

**Rule of thumb:**
- Simple app (nginx): 300s
- Complex app (Java, database migration): 600s+
- Measure actual boot time, add 50% buffer

---

## Testing Results

### Test 1: Initial Launch

**Action:** Created ASG with desired capacity 2

**Timeline:**
- T+0s: ASG created
- T+0s: ASG launched 2 instances
- T+2min: Instances running, User Data executing
- T+5min: Health check grace period ended
- T+6min: Both instances passed health checks
- T+6min: Both registered with target group
- T+6min: ALB started routing traffic

**Verification:**
- Opened ALB DNS in browser ✅
- Saw "Auto Scaled Web Server" page ✅
- Refreshed multiple times, traffic distributed ✅

**Result:** Auto Scaling + Load Balancing working perfectly

---

### Test 2: Self-Healing (Instance Failure)

**Action:** Terminated one instance to simulate crash

**What I observed:**

**Immediate (T+0):**
- Instance state: Running → Shutting down → Terminated
- ASG detected: Actual capacity (1) < Desired capacity (2)

**ASG Activity Log:**
```
[Timestamp] Terminating EC2 instance: i-[OLD-INSTANCE]
Cause: An instance was taken out of service in response to a user request.

[Timestamp] Launching a new EC2 instance: i-[NEW-INSTANCE]
Cause: An instance was started in response to a difference between desired and actual capacity.
```

**Timeline:**
- T+0s: Terminated instance
- T+0s: ASG launched replacement (IMMEDIATELY)
- T+2min: New instance running
- T+5min: Health check grace period
- T+6min: New instance healthy, registered with ALB

**User impact:**
- Service continued on remaining healthy instance ✅
- No downtime ✅
- Slight performance degradation (1 instance instead of 2) for ~6 minutes
- After 6 min: Back to 2 instances, full capacity restored ✅

**Key insight:** This is true self-healing. No human intervention.

---

### Test 3: Scaling Policy (CPU-Based)

**Action:** [DESCRIBE YOUR TEST - stress test OR scheduled scaling]

**Method used:**
- [ ] Option A: Stress test (generated CPU load)
- [ ] Option B: Scheduled scaling (set scale-up time)

**What I observed:**
[FILL IN YOUR OBSERVATIONS]

**Example for stress test:**
```
- Installed stress tool on one instance
- Ran: stress --cpu 4 --timeout 300
- CPU spiked to 90% on that instance
- Average across 2 instances: ~45% (below 50% threshold)
- Did not trigger scaling (would need both instances at high CPU)
```

**Example for scheduled scaling:**
```
- Created scheduled action: scale to 3 instances in 2 minutes
- After 2 minutes: ASG launched 1 additional instance
- Total: 3 instances running
- Created scale-down: back to 2 instances in 5 minutes
- After 5 minutes: ASG terminated extra instance
```

**Learning:** Scaling policies take time to react (by design, avoid flapping)

---

## Auto Scaling vs Manual Management

### Without Auto Scaling (Manual - What We Had Before)

**Scenario:** Instance crashes at 2 AM

**Timeline:**
```
2:00 AM: Instance crashes
2:00 AM - 8:00 AM: Website running on 1 instance (degraded)
8:00 AM: You wake up
8:15 AM: Check monitoring, discover crash
8:30 AM: Launch replacement instance manually
8:35 AM: Instance running, register with target group
8:40 AM: Back to 2 instances

Downtime: 0 (had second instance)
Degraded performance: 6 hours 40 minutes
Manual effort: 25 minutes
```

---

### With Auto Scaling (What We Have Now)

**Scenario:** Instance crashes at 2 AM

**Timeline:**
```
2:00 AM: Instance crashes
2:00 AM: ASG detects (health check fails)
2:00 AM: ASG launches replacement
2:06 AM: New instance healthy, registered
2:06 AM: Back to 2 instances

Downtime: 0
Degraded performance: 6 minutes
Manual effort: 0 minutes
You: Sleeping peacefully 😴
```

**This is the difference Auto Scaling makes.**

---

## Production Architecture Achieved

**What we've built over 3 days:**
```
                    Internet
                        ↓
                Internet Gateway
                        ↓
            ┌───────────┴───────────┐
            │                       │
    ┌───────────────┐       ┌───────────────┐
    │ Public Subnet │       │ Public Subnet │
    │   (AZ-a)      │       │   (AZ-b)      │
    │               │       │               │
    │  [ALB]────────┼───────┼────[ALB]      │
    └───────┬───────┘       └───────┬───────┘
            │                       │
    ┌───────┴───────┐       ┌───────┴───────┐
    │Private Subnet │       │Private Subnet │
    │   (AZ-a)      │       │   (AZ-b)      │
    │               │       │               │
    │ Auto Scaling Group                    │
    │ ┌─────────┐   │       │ ┌─────────┐   │
    │ │EC2 (ASG)│   │       │ │EC2 (ASG)│   │
    │ └─────────┘   │       │ └─────────┘   │
    │  (min 2, max 4, auto-managed)         │
    └───────────────┘       └───────────────┘
```

**Features:**
- ✅ Multi-AZ high availability
- ✅ Load balancing (distribute traffic)
- ✅ Auto-healing (replace failed instances)
- ✅ Auto-scaling (add/remove based on demand)
- ✅ Cost-optimized (scale down during low traffic)
- ✅ Security (private subnets, security groups)
- ✅ Zero-touch deployment (launch template + User Data)

**This is production-grade infrastructure.**

---

## Real-World Use Cases

### Nigerian Fintech Example: Paystack

**Scenario:** Payment processing platform

**Traffic patterns:**
- 2 AM - 6 AM: Low (2 instances)
- 12 PM - 2 PM: Lunch hour spike (4 instances)
- 6 PM - 9 PM: Evening peak (6 instances)
- Month end: Salary day spike (10 instances)

**Auto Scaling configuration:**
```
Min: 2 (always available)
Max: 10 (handle salary day)
Target: 40% CPU (payment processing is CPU-intensive)
Scheduled scaling: Month end (scale up preemptively)
```

**Benefits:**
- **High availability:** Self-healing, multi-AZ
- **Performance:** Scale up during peaks
- **Cost:** Average 3 instances vs always 10 instances (70% savings)
- **Reliability:** 99.9% uptime SLA

---

### E-commerce Example: Black Friday Sale

**Scenario:** Online store expects 10x traffic

**Without Auto Scaling:**
- Guess capacity (maybe 20 instances?)
- Over-provision (expensive) or under-provision (crash)
- Manual scaling during sale (reactive, slow)

**With Auto Scaling:**
```
Normal: Min 2, Max 4, Desired 2
Black Friday: Min 10, Max 50, Desired 10
Scheduled: Scale to 10 at 8 AM, back to 2 at 11 PM
Target tracking: 50% CPU (auto-adjust during sale)
```

**Result:**
- Pre-scaled before traffic hits
- Auto-scales up to 50 if needed
- Auto-scales down after sale
- Cost-optimized (pay for spike only during spike)

---

## Cost Analysis

### Manual Management (Before Auto Scaling)

**Configuration:** 3 instances running 24/7 (over-provisioned for peak)

**Cost:**
- t3.micro: $0.0104/hour × 3 instances × 730 hours/month = **$22.78/month**
- ALB: $16/month
- **Total: $38.78/month**

**Problems:**
- Over-provisioned during off-peak (wasting money)
- Under-provisioned during peak (performance issues)

---

### Auto Scaling (Current Setup)

**Configuration:** 2-4 instances, scales based on demand

**Realistic usage:**
```
Off-peak (18 hours/day): 2 instances
Peak (6 hours/day): 3 instances
```

**Cost calculation:**
- Off-peak: 2 instances × 18 hours × 30 days = 1,080 instance-hours
- Peak: 3 instances × 6 hours × 30 days = 540 instance-hours
- Total: 1,620 instance-hours/month
- Cost: 1,620 × $0.0104 = **$16.85/month**
- ALB: $16/month
- **Total: $32.85/month**

**Savings: $5.93/month (15% reduction)**

**For larger scale:**
- Manual: 10 instances 24/7 = $75.92/month
- Auto Scaling (avg 6 instances): $45.55/month
- **Savings: 40%**

---

## Scaling Policy Deep Dive

### Target Tracking Explained

**Our policy: Keep average CPU at 50%**

**How ASG calculates required capacity:**

**Current state:**
```
2 instances
CPU: 70% (under load)
Target: 50%
```

**Math:**
```
Required capacity = Current instances × (Current metric / Target metric)
Required capacity = 2 × (70 / 50)
Required capacity = 2 × 1.4 = 2.8
Round up to: 3 instances
```

**Action:** ASG launches 1 instance

**After scaling:**
```
3 instances
CPU: ~47% (close to 50% target)
```

---

### Cooldown Periods

**Why scaling is intentionally slow:**

**Scale-out (adding instances):**
```
T+0:    High CPU detected (70%)
T+5min: Still high (wait to confirm, not brief spike)
T+5min: Launch instance
T+10min: Instance healthy
T+10min: Metric re-evaluated with new instance
```
**Total: 10-15 minutes**

---

**Scale-in (removing instances):**
```
T+0:     Low CPU detected (30%)
T+15min: Still low (long wait, avoid flapping)
T+15min: Terminate 1 instance
T+20min: Connection draining complete
T+20min: Metric re-evaluated
```
**Total: 20-30 minutes**

---

**Why different speeds?**

**Scale-out = Urgent (users affected):**
- High CPU = slow response times
- Users experiencing poor performance
- Need capacity NOW

**Scale-in = Not urgent (saving money):**
- Low CPU = no user impact
- Avoid "flapping" (scale up, down, up, down)
- Conservative approach

---

### Alternative Scaling Policies

**We used Target Tracking (simplest). Other options:**

**1. Step Scaling (more control):**
```
If CPU 50-60%: Add 1 instance
If CPU 60-75%: Add 2 instances
If CPU 75%+:   Add 3 instances
```

**When to use:** Need precise control over scaling speed

---

**2. Scheduled Scaling (predictable patterns):**
```
8 AM weekdays:  Scale to 5 instances (business hours)
6 PM weekdays:  Scale to 2 instances (off-hours)
Saturday:       Scale to 1 instance (minimal traffic)
```

**When to use:** Predictable traffic patterns (business hours, weekly cycles)

---

**3. Predictive Scaling (ML-based):**
```
AWS analyzes historical traffic
Predicts future load
Pre-scales before traffic hits
```

**When to use:** Large-scale applications with historical data

---

## Commands Reference

**View ASG status:**
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-servers-asg
```

**View scaling activities:**
```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name web-servers-asg \
  --max-records 10
```

**Manually set desired capacity (for testing):**
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name web-servers-asg \
  --desired-capacity 3
```

**View current instances in ASG:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=web-servers-asg" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table
```

---

## Best Practices Implemented

**1. Minimum capacity = High availability**
```
Min: 2 (never below)
```
**Result:** Always redundant, survives single instance failure

---

**2. Multi-AZ distribution**
```
Subnets: private-subnet-1a, private-subnet-1b
```
**Result:** Survives entire AZ failure

---

**3. Health check grace period**
```
Grace period: 300 seconds
```
**Result:** Avoids premature termination during boot

---

**4. Both EC2 and ELB health checks**
```
Health checks: EC2 + ELB
```
**Result:** Catches both infrastructure and application failures

---

**5. Conservative max capacity**
```
Max: 4 (not 100)
```
**Result:** Prevents runaway scaling from bugs (e.g., infinite loop causing high CPU)

---

**6. Target tracking (simple, effective)**
```
Target: 50% CPU
```
**Result:** ASG handles scaling logic, we just set target

---

## Monitoring and Troubleshooting

### Key Metrics to Watch

**1. Desired vs Actual Capacity**
```
ASG → Monitoring tab → Group metrics
```
**Healthy:** Desired = Actual (e.g., 2 = 2)
**Problem:** Desired 2, Actual 1 (instance failing health checks repeatedly)

---

**2. Healthy vs Unhealthy Instances**
```
Target Group → Targets tab
```
**Healthy:** All instances healthy
**Problem:** Instances unhealthy → Check health check logs, User Data

---

**3. Scaling Activity**
```
ASG → Activity tab
```
**Look for:**
- Frequent scaling (flapping - adjust policy)
- Failed launches (permission issues, quota limits)
- Health check failures (app not starting correctly)

---

### Common Issues

**Issue 1: Instances fail health checks immediately**

**Symptoms:**
- Instance launches, becomes InService, then Terminating
- Repeat cycle (death spiral)

**Cause:** Health check grace period too short, app not ready

**Fix:**
```
Increase grace period: 300 → 600 seconds
```

---

**Issue 2: ASG not scaling despite high CPU**

**Symptoms:**
- CPU at 80%, but only 2 instances (should scale to 3+)

**Cause:** 
- Scaling policy not configured
- Cooldown period active
- Already at max capacity

**Fix:**
- Verify scaling policy exists
- Check Activity tab for cooldown messages
- Increase max capacity if needed

---

**Issue 3: Instances launching in wrong subnet**

**Symptoms:**
- Instances have public IPs (should be private)
- Not registering with ALB

**Cause:** ASG configured with public subnet instead of private

**Fix:**
```
ASG → Edit → Network → Select private subnets only
```

---

## Week 11 Complete: Production Infrastructure

**Day 1:** Application Load Balancer
- Distributes traffic across instances
- Health checks detect failures
- Multi-AZ for high availability

**Day 2:** High Availability Testing
- Tested failover (kill instance, service continues)
- Optimized health check settings
- Observed automated recovery

**Day 3:** Auto Scaling Groups (TODAY)
- Self-healing (automatic instance replacement)
- Auto-scaling (capacity adjusts to demand)
- Cost optimization (pay for what you use)

---

**What this architecture provides:**

**1. High Availability (99.9%+ uptime)**
- Multi-AZ deployment
- Redundant instances
- Automated failover
- Self-healing

**2. Performance**
- Load balancing (distribute traffic)
- Auto-scaling (add capacity during peaks)
- Fast health checks (detect issues quickly)

**3. Cost Efficiency**
- Scale down during low traffic
- Pay only for needed capacity
- 15-40% cost savings vs static capacity

**4. Operational Excellence**
- Zero manual intervention for failures
- Automated capacity management
- Predictable performance

**5. Security**
- Private subnets (instances not internet-accessible)
- Security groups (defense in depth)
- Principle of least privilege

---

## Next Steps

**Week 12: Monitoring with CloudWatch**
- Metrics (CPU, requests, latency)
- Alarms (notify when things go wrong)
- Dashboards (visualize infrastructure health)
- Logs (debug issues)

**Week 13-14: Infrastructure as Code (Terraform)**
- Rebuild entire Week 11 setup with code
- Version control infrastructure
- Repeatable, automated deployments

**Week 15-16: CI/CD Pipeline**
- Automated testing
- Automated deployments
- Zero-downtime releases

---

## Questions I Can Answer

**Q: What happens if ASG tries to launch instance but hits AWS limit?**
A: Launch fails, ASG retries periodically. Activity log shows "InsufficientInstanceCapacity" error. Request limit increase from AWS.

**Q: Can ASG span multiple VPCs?**
A: No. ASG is per-VPC. For multi-VPC, create separate ASGs and use different load balancers.

**Q: What if I want different instance types (t3.micro during off-peak, t3.medium during peak)?**
A: Use multiple launch templates + scheduled scaling actions to swap templates. Or use mixed instance policy (advanced).

**Q: How does ASG choose which instance to terminate during scale-in?**
A: Default: Oldest launch template, then instance closest to next billing hour. Can customize termination policy.

**Q: What's the difference between ASG and ECS/EKS auto-scaling?**
A: ASG = EC2 instances. ECS/EKS = containers. Containers are more efficient, but EC2 is simpler for beginners.

---

**Status:** Week 11 Day 3 COMPLETE ✅

**Skills mastered:**
- Launch Templates (reusable instance blueprints)
- Auto Scaling Groups (automated capacity management)
- Scaling policies (CPU-based target tracking)
- Self-healing infrastructure
- Dynamic scaling (up and down)
- Cost optimization through auto-scaling
- Production architecture design

**Week 11 COMPLETE ✅**

**Infrastructure achieved:**
- Multi-AZ, load-balanced, auto-scaling, self-healing web application
- Production-grade reliability
- Enterprise architecture patterns
- 99.9%+ availability capability

**This is what DevOps engineers build. You just built it.** 🚀
