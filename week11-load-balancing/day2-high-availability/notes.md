# Week 11 Day 2: High Availability Testing & Monitoring

## What I Tested

**Simulated real-world server failure:**
- Terminated web-server-1a (simulated crash/hardware failure)
- Monitored ALB automated failure detection
- Observed health checks in action
- Tested user experience during failover
- Launched replacement instance
- Verified recovery and redundancy restoration

## Timeline of Events

### Initial State (Healthy System)
- 2 instances: web-server-1a, web-server-1b
- Both healthy
- Traffic distributed evenly
- ALB DNS: [YOUR-ALB-DNS]

### Failure Simulation

**Time:** [YOUR-TIMESTAMP when you terminated]

**Action:** Terminated web-server-1a

**Detection Timeline:**
- T+0s: Instance terminated
- T+30s: First health check failed (1 of 2)
- T+60s: Second health check failed, marked unhealthy
- **Total detection time: 60 seconds**

**Target Group Status Changes:**
```
Before: 2 healthy, 0 unhealthy
During: 1 healthy, 1 unhealthy (web-server-1a removed)
```

### User Impact During Failure

**Browser testing:**
- T+0 to T+60s: [DESCRIBE WHAT YOU SAW - errors? slow responses?]
- T+60s+: All requests successful, routed to web-server-1b

**Terminal testing (curl loop):**
- [PASTE YOUR ACTUAL RESULTS]
- Observed HTTP status codes: [200? 503? Mix?]

**Conclusion:** 
- Downtime experienced: [YOUR OBSERVATION - likely 0-60 seconds of potential errors]
- After detection: Zero errors ✅

### Recovery Process

**Time:** [TIMESTAMP when you launched new instance]

**Action:** Launched web-server-1a-new

**Steps:**
1. Launched new instance in private-subnet-1a
2. User Data automated nginx setup
3. Registered in target group
4. Health checks verified instance (2 consecutive successes)
5. Instance marked healthy
6. Traffic distribution resumed

**Recovery Timeline:**
- Instance launch to healthy: ~5-6 minutes
- Health check verification: 60 seconds (2 checks at 30s interval)

**Final State:**
```
web-server-1a-new    healthy ✅
web-server-1b        healthy ✅
Total: 2 healthy, 0 unhealthy
```

## Key Learnings

### 1. High Availability = Automated Failure Handling

**What I observed:**
- ALB detected failure without human intervention
- Failed instance automatically removed from rotation
- Service continued with reduced capacity
- Users experienced minimal disruption

**This is production-grade HA.**

### 2. Health Checks Are Critical

**How they work:**
- ALB sends GET request to /health every [interval] seconds
- If 2 consecutive failures → mark unhealthy
- If 2 consecutive successes → mark healthy
- Unhealthy targets removed from rotation

**Settings impact:**
- Shorter interval = faster detection, more requests
- Higher threshold = slower detection, fewer false positives

**Our settings:**
- Interval: 30s (then optimized to 10s)
- Threshold: 2 checks
- Detection time: 60s (then 20s after optimization)

### 3. Graceful Degradation

**System behavior during failure:**
- Didn't go completely down ❌
- Continued with 1 instance ✅
- Slower response time (1 server vs 2)
- But AVAILABLE ✅

**This is the difference between:**
- 99% availability (3.65 days downtime/year)
- 99.9% availability (8.76 hours downtime/year)

### 4. Recovery Requires Redundancy Restoration

**What happened:**
- Failed instance removed → Single point of failure
- New instance launched → Redundancy restored
- Both instances healthy → HA architecture complete

**In production:**
- Auto Scaling does this automatically
- Self-healing infrastructure
- No manual intervention needed

### 5. Detection Time vs Cost Trade-off

**Original settings:**
- 30s interval = 2,880 checks/day per instance
- 60s detection time

**Optimized settings:**
- 10s interval = 8,640 checks/day per instance
- 20s detection time
- 3x more checks, 3x faster detection

**Cost impact:**
- Health checks are cheap (~$0.0001 per check)
- For small scale: Negligible cost increase
- For large scale: Worth it for faster recovery

## Real-World Scenarios This Handles

### Scenario 1: Application Crash
**Cause:** Memory leak, infinite loop, null pointer exception

**What happens:**
- Nginx process crashes
- Health check fails (no response)
- ALB removes instance
- Developers notified, debug, fix, redeploy
- Service continues on other instances

### Scenario 2: Hardware Failure
**Cause:** Disk failure, memory failure, power loss

**What happens:**
- Instance stops responding
- Health checks fail
- ALB removes instance
- AWS notices hardware issue
- Auto Scaling launches replacement

### Scenario 3: Datacenter Failure (Entire AZ Down)
**Cause:** Power outage, network failure at AWS datacenter

**What happens:**
- All instances in that AZ fail
- ALB has instances in OTHER AZ (us-east-2b)
- Service continues from other AZ ✅
- This is why multi-AZ is critical

### Scenario 4: Bad Deployment
**Cause:** Developer deploys code with critical bug

**What happens:**
- New code crashes on requests
- Health checks fail
- Instances marked unhealthy
- Rollback to previous version
- Service continues on healthy instances with old code

## Health Check Optimization

### Before Optimization
```
Interval: 30 seconds
Timeout: 5 seconds
Healthy threshold: 2
Unhealthy threshold: 2
Detection time: 60 seconds
```

### After Optimization
```
Interval: 10 seconds
Timeout: 5 seconds
Healthy threshold: 2
Unhealthy threshold: 2
Detection time: 20 seconds
```

**Impact:**
- 3x faster failure detection
- 3x more health check requests
- Minimal cost increase
- Better user experience

## Production Best Practices Learned

### 1. Always Multi-AZ
- Never deploy to single AZ
- Spread instances across at least 2 AZs
- Protects against datacenter-level failures

### 2. Set Appropriate Health Check Intervals
- Critical applications: 5-10 seconds
- Standard applications: 10-30 seconds
- Internal tools: 30-60 seconds

### 3. Monitor Health Check Metrics
- Track unhealthy instance count
- Alert when instances fail
- Investigate patterns (are instances failing at same time? specific time of day?)

### 4. Automate Recovery
- Use Auto Scaling Groups (Day 3)
- Self-healing infrastructure
- No manual intervention needed

### 5. Test Failure Scenarios
- What we did today
- Regularly test failover
- Chaos engineering (intentionally break things to verify recovery)

## Questions I Can Answer Now

**Q: What happens if BOTH instances fail?**
A: ALB has no healthy targets → Returns 503 Service Unavailable → Service down. This is why we need Auto Scaling (automatically launches new instances).

**Q: How fast should failure detection be?**
A: Depends on application criticality. Payment processing: 5-10s. Blog: 30-60s. Trade-off between cost and recovery speed.

**Q: What if health check endpoint crashes but app still works?**
A: Instance marked unhealthy even though app works. This is why health check should verify actual app functionality, not just return "OK".

**Q: Can I have different health checks for different targets?**
A: No, health checks are per target group. All targets in a group use same health check settings.

**Q: What's the difference between target group and Auto Scaling Group?**
A: Target group = where ALB routes traffic. Auto Scaling Group = automatically launches/terminates instances based on demand. Often used together.

## Cost Considerations

**Load Balancer costs:**
- ALB: ~$16-20/month (hourly charge)
- LCU (Load Balancer Capacity Unit): ~$0.008 per LCU-hour
- Health checks: Nearly free (included in LCU)

**Total for this setup:** ~$20-30/month

**In production:**
- Worth it for high availability
- Alternative (single instance): $10/month but ZERO redundancy

**The $10-20 extra buys:**
- Automated failure handling
- Zero downtime during failures
- Peace of mind

## Next Steps

### Day 3: Auto Scaling Groups
- Automatically launch instances when needed
- Scale up during high traffic
- Scale down during low traffic
- Self-healing infrastructure

### Day 4: CloudWatch Monitoring
- Metrics (CPU, requests, latency)
- Alarms (notify when things go wrong)
- Dashboards (visualize infrastructure health)

---

**Status:** Week 11 Day 2 COMPLETE ✅

**Skills mastered:**
- High availability testing
- Failover simulation
- Health check optimization
- Recovery procedures
- Production failure handling
- HA architecture principles

**Key insight:** Load balancing isn't just distribution. It's resilience. The system that survives failures without users noticing is the system that's built correctly.
