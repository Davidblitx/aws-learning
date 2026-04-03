# Week 12 Day 2: CloudWatch Alarms

## What I Built

**Automated monitoring system with email notifications:**
- SNS topic for infrastructure alerts
- Email subscription (confirmed and tested)
- 4 CloudWatch alarms for critical metrics
- Tested alarm triggering and recovery

**Purpose:** Detect and notify about problems before users notice

---

## SNS Topic Configuration

**Topic Name:** infrastructure-alerts
**Subscription:** Email to onojadavison@gmail.com
**Status:** Confirmed ✅

**Test:** Sent test message, received email successfully

---

## Alarms Created

### 1. Unhealthy Targets Alarm

**Metric:** ALB UnhealthyHostCount
**Threshold:** > 0
**Evaluation:** 2 consecutive 1-minute periods
**Action:** Email notification via SNS

**Purpose:** Detect instance health check failures
**Urgency:** Critical (immediate investigation needed)

**What triggers it:**
- Instance crashes
- Application stops responding
- Health check endpoint fails

**Expected behavior:**
- Alarm within 2 minutes of failure
- Email notification sent
- OK notification when ASG replaces instance

---

### 2. High CPU Alarm

**Metric:** ASG CPUUtilization (average)
**Threshold:** > 75%
**Evaluation:** 3 consecutive 5-minute periods (15 min total)
**Action:** Email notification

**Purpose:** Detect sustained high CPU (performance warning)
**Urgency:** Warning (investigate, verify auto-scaling working)

**What triggers it:**
- Traffic spike (ASG should scale, this is backup alert)
- Infinite loop in application
- Resource leak (memory leak causing high CPU)

**Expected behavior:**
- ASG scaling policy should handle (target 50%)
- This alarm = safety net if scaling not working
- 15 min delay avoids false alarms from brief spikes

---

### 3. Slow Response Time Alarm

**Metric:** ALB TargetResponseTime (average)
**Threshold:** > 1 second
**Evaluation:** 2 consecutive 5-minute periods
**Action:** Email notification

**Purpose:** Detect performance degradation
**Urgency:** Warning (user experience affected)

**What triggers it:**
- Database slowness
- Overloaded instances (CPU, memory)
- Network issues
- Application bugs (slow queries, inefficient code)

**Expected behavior:**
- Normal: <200ms for static content
- 1 second = something definitely wrong
- Investigate: logs, CPU, database

---

### 4. Application Errors Alarm

**Metric:** ALB HTTPCode_Target_5XX_Count
**Threshold:** > 10 errors in 5 minutes
**Evaluation:** 1 out of 1 (immediate)
**Action:** Email notification

**Purpose:** Detect application-level failures
**Urgency:** Critical (users seeing errors)

**What triggers it:**
- Application bugs (code errors)
- Database connection failures
- Dependency failures (API calls to external services)
- Configuration errors

**Expected behavior:**
- 1-2 errors = transient (don't alarm)
- 10+ errors = pattern (alarm immediately)
- Investigate: application logs, recent deployments

---

## Testing Results

### Test 1: Unhealthy Target Alarm

**Action:** Terminated one ASG instance

**Timeline:**
- T+0s: Instance terminated
- T+20s: Health check failed, target marked unhealthy
- T+2min: Alarm triggered (2 consecutive periods)
- T+2min: Email received ✅

**Email content:**
```
Subject: ALARM: UnhealthyTargets-david-web-alb
State: ALARM
Reason: Threshold Crossed: 2 datapoints [1.0, 1.0] were greater than threshold (0.0)
```

**Recovery:**
- T+8min: ASG launched replacement, new instance healthy
- T+10min: OK notification received ✅

**Learning:** 
- Detection time: 2 minutes (fast enough)
- Recovery automated (ASG self-healing)
- Notifications working perfectly

---

### Test 2: High CPU Alarm

**Method:** skipped

**Alternative:** Verified alarm configured correctly, would trigger at 75% for 15 minutes

---

### Test 3: Other Alarms

**Response Time Alarm:**
- State: OK (response time <100ms consistently)
- Would trigger if: Application slow, database issues

**5xx Error Alarm:**
- State: OK (no application errors)
- Would trigger if: Application bugs, crashes

---

## Alarm States Explained

**OK (Green):**
- Metric within threshold
- System healthy
- No action needed

**ALARM (Red):**
- Metric exceeded threshold
- Problem detected
- Notification sent

**INSUFFICIENT_DATA (Gray):**
- Not enough data to evaluate
- Common for new alarms
- Wait 2-5 minutes, should transition to OK

---

## Email Notification Format

**ALARM notification:**
```
Subject: ALARM: [AlarmName] in [Region]
Body:
  You are receiving this email because your alarm [AlarmName] 
  in the [Region] region has entered the ALARM state.
  
  Alarm Details:
  - Name: UnhealthyTargets-david-web-alb
  - Description: Alert when any target is unhealthy
  - State Change: OK -> ALARM
  - Reason: Threshold Crossed: 2 datapoints [1.0, 1.0] > threshold (0.0)
  - Timestamp: 2026-04-01 14:32:15 UTC
  
  Metric:
  - Namespace: AWS/ApplicationELB
  - Name: UnhealthyHostCount
  - Current Value: 1.0
```

**OK notification:**
```
Subject: OK: [AlarmName] in [Region]
Reason: Threshold Crossed: 2 datapoints [0.0, 0.0] <= threshold (0.0)
```

---

## Key Learnings

### 1. Alarms Are Proactive Monitoring

**Without alarms:**
- Wait for users to report problems
- Reactive (problem already affecting users)
- Manual checking (refresh dashboards constantly)

**With alarms:**
- Notified before users notice (or immediately after)
- Proactive (detect early, fix fast)
- Automated (no manual checking)

---

### 2. Evaluation Periods Prevent False Alarms

**1 datapoint = too sensitive:**
- Brief CPU spike triggers alarm
- False alarm fatigue (ignore real alerts)

**Multiple datapoints = confirms sustained issue:**
- 2-3 consecutive periods
- Confirms it's not transient
- Real problems only

**Balance:**
- Critical metrics (unhealthy targets): 2 minutes
- Warning metrics (high CPU): 15 minutes

---

### 3. Different Metrics = Different Urgency

**Critical (immediate action):**
- Unhealthy targets (capacity loss)
- 5xx errors (users seeing errors)
- Detection: 2-5 minutes

**Warning (investigate soon):**
- High CPU (may need scaling)
- Slow response (performance degrading)
- Detection: 10-15 minutes

---

### 4. OK Notifications Matter

**Why they're important:**
- Know when problem is resolved
- Calculate incident duration
- Verify automated recovery worked
- Sleep better (don't wake up wondering "is it still broken?")

**Example incident:**
```
2:00 AM: ALARM (unhealthy target)
2:06 AM: OK (ASG recovered)
Incident duration: 6 minutes
Resolution: Automated (ASG self-healing)
Manual intervention: None needed
```

---

### 5. Alarms Are Part of Architecture

**Production systems need:**
- Infrastructure (VPC, ALB, ASG) ✅ (Week 10-11)
- Monitoring (Metrics, Alarms) ✅ (Week 12)
- Both together = Reliable system

**Without alarms:**
- Infrastructure works
- But you don't know WHEN it breaks
- Manual discovery (too slow)

**With alarms:**
- Infrastructure works
- You're notified immediately when it doesn't
- Automated discovery (fast)

---

## Best Practices Applied

**1. Descriptive naming:**
```
UnhealthyTargets-david-web-alb (not "Alarm1")
HighCPU-web-servers-asg (not "Test")
```

**2. Appropriate thresholds:**
```
Unhealthy targets: >0 (any is bad)
CPU: >75% (leaves headroom, not too sensitive)
Response time: >1s (definitely slow)
5xx errors: >10 in 5min (pattern, not transient)
```

**3. Layered monitoring:**
```
Critical: Unhealthy targets, 5xx errors
Warning: High CPU, slow response
```

**4. Multiple evaluation periods:**
```
Fast detection: 2 minutes (critical)
Avoid false alarms: 15 minutes (warning)
```

---

## Real-World Application

### Scenario: 3 AM Production Incident

**Without alarms:**
```
3:00 AM: Database connection pool exhausted
3:00 AM: Application returns 500 errors
3:00 AM - 7:00 AM: Users can't access website
7:00 AM: First user complaint via support ticket
8:00 AM: Team discovers issue, investigates
9:00 AM: Issue resolved
Downtime: 6 hours
```

**With alarms:**
```
3:00 AM: Database connection pool exhausted
3:00 AM: Application returns 500 errors
3:05 AM: 5xx error alarm triggers (>10 errors in 5min)
3:05 AM: Email/SMS sent to on-call engineer
3:10 AM: Engineer checks logs, identifies database issue
3:15 AM: Increases connection pool, restarts app
3:20 AM: OK notification (errors stopped)
Downtime: 20 minutes
```

**Alarms reduced downtime from 6 hours to 20 minutes.**

---

## Commands Reference

**View alarm history:**
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name UnhealthyTargets-david-web-alb \
  --max-records 10
```

**Manually set alarm state (testing):**
```bash
aws cloudwatch set-alarm-state \
  --alarm-name UnhealthyTargets-david-web-alb \
  --state-value ALARM \
  --state-reason "Manual test"
```

**List all alarms:**
```bash
aws cloudwatch describe-alarms
```

---

## Next Steps

**Day 3: CloudWatch Logs**
- Send nginx logs to CloudWatch
- Query logs with Logs Insights
- Find errors, slow requests, patterns

**Day 4: Cost Monitoring**
- AWS Cost Explorer
- Budget alerts
- Cost allocation tags

---

**Status:** Week 12 Day 2 COMPLETE ✅

**Skills learned:**
- SNS topic creation and subscription
- CloudWatch alarm configuration
- Threshold and evaluation period design
- Alarm testing and validation
- Production incident response patterns

**Infrastructure now has:**
- Load balancing ✅
- Auto-scaling ✅
- Self-healing ✅
- **Automated monitoring and alerting** ✅

**The nervous system is in place. You'll know when things break.** 🚨
