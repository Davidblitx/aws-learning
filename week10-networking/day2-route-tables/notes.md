# Week 10 Day 2: Route Tables & Internet Gateway

## What I Built
- Internet Gateway: david-prod-igw (attached to VPC)
- Public route table (routes to IGW)
- Private route table (local only, for now)
- Tested internet connectivity from public subnet ✅
- Verified private subnet isolation ✅

## Route Table Configuration

**Public Route Table:**
- 10.0.0.0/16 → local
- 0.0.0.0/0 → igw-xxxxx

**Private Route Table:**
- 10.0.0.0/16 → local
- (No internet route - will add NAT Gateway tomorrow)

## Key Learnings
- Route tables = GPS for packets
- 0.0.0.0/0 = all internet traffic
- Internet Gateway = VPC's door to internet
- Public subnet needs: IGW + route table + public IP
- Private subnet can't reach internet without NAT Gateway

## Test Results
- Public EC2 → Internet: ✅ Works
- Private EC2 → Internet: ❌ Fails (expected, no NAT yet)
- Public EC2 → Private EC2: ✅ Works (VPC internal)

## Next: NAT Gateway for private subnet internet access
