# Weeks 12-13: Monitoring, Observability & Cost Control

**Duration:** 2 weeks (compressed)
**Status:** ✅ Complete
**Focus:** Production monitoring and observability

---

## What I Learned

### Three Pillars of Observability

**1. Metrics (Numbers over time)**
- CloudWatch collects metrics from AWS services
- Examples: CPU utilization, request count, response time
- Used for: Real-time monitoring, alerting, dashboards

**2. Logs (Events that happened)**
- CloudWatch Logs stores application logs
- Logs Insights for querying (SQL-like)
- Used for: Debugging, audit trails, error analysis

**3. Traces (Request path - not covered)**
- How requests flow through system
- Advanced topic for later

---

## Key Components Built

### CloudWatch Metrics
- Viewed EC2, ALB, Auto Scaling metrics
- Understood namespaces and dimensions
- Analyzed graphs for patterns

### CloudWatch Alarms
- 4 alarms configured:
  - Unhealthy targets (2-min detection)
  - High CPU (15-min detection)
  - Slow response time (10-min detection)
  - 5xx errors (5-min detection)

### SNS Notifications
- Topic: infrastructure-alerts
- Email subscription confirmed
- Tested notification delivery

### Cost Monitoring
- AWS Cost Explorer (track spending)
- Budget alerts (prevent overruns)
- Cost allocation tags (per-project tracking)

---

## Production Patterns Learned

**Alarm Design:**
- Set appropriate thresholds (not too sensitive, not too loose)
- Use evaluation periods (avoid false alarms)
- Different urgency = different detection speed

**Incident Response:**
Alert → Check metrics → Check logs → Identify cause → Fix → Verify

**Cost Control:**
Budget → Alert at 80% → Investigate → Optimize → Track

---

## Interview-Ready Skills

✓ CloudWatch metrics analysis
✓ Alarm configuration
✓ Log querying
✓ Cost optimization
✓ Production incident response
✓ Observability architecture design

---

**Status:** Monitoring fundamentals complete
**Next:** Week 14-15 - Infrastructure as Code (Terraform)
