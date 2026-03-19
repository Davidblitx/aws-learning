# Week 10 Day 1: VPC Fundamentals

## What I built
Today I designed the network foundation of a production-style AWS environment by creating a Virtual Private Cloud and dividing it into structured subnets across multiple availability zones.

### VPC 
- Name: david-prod-vpc
- CIDR: 10.0.0.0/16

This VPC acts as my private network inside AWS.

Instead of deploying servers directly on the internet, all infrastructure lives inside this logically isolated network boundary. Only resources that I explicitly expose will be reachable from the internet.

The /16 CIDR block means this VPC has a large address space, allowing it to scale to tens of thousands of instances and services if needed.

### Subnet Architecture
Inside the VPC I create four subnets distributed across two Availabilty zones

VPC: 10.0.0.0/16
│
├─ AZ: us-east-2a
│  ├─ Public Subnet: 10.0.1.0/24
│  └─ Private Subnet: 10.0.11.0/24
│
└─ AZ: us-east-2b
   ├─ Public Subnet: 10.0.2.0/24
   └─ Private Subnet: 10.0.12.0/24

This structure mirros real architectures used by companies running high-availability systems in AWS.

### Public Subnets
- 10.0.1.0/24
- 10.0.2.0/24

Public subnets are designed to host infrastructure that must communicate with the internet.

Examples include:
- Load balancers
- Bastion hosts
- Public-facing APIs
- Reverse proxies

Instances inside these subnets can be reachable from the internet once an Internet Gateway and routing rules are configured.
However, public access is still controlled through security groups and firewall rules.

### Private Subnets
- 10.0.11.0/24
- 10.0.12.0/24

Private subnets host infrastructure that should never be directly exposed to the internet.

Typical resources include:
- Application servers
- Microservices
- Databases
- Internal processing systems

These systems communicate with the public layer internally but remain invisible to external traffic, reducing the attack surface.

### Multi-AZ Deployment
The subnets are spread across two Availability Zones:
- us-east-2a
- us-east-2b

Each Availability Zone represents a separate physical data center within the same AWS region.
This architecture improves fault tolerance and high availability.
If one data center fails, workloads can continue running in the other zone.
This pattern is a core principle in resilient cloud architecture.


## What I Learned
#### 1. VPC = Isolated Network in AWS
A VPC functions like a private corporate network inside Amazon's infrastructure.
It provides:
- IP addressing control
- Network segmentation
- Routing control
- Security boundaries

This isolation ensures that resources belonging to different AWS customers cannot interact unless explicitly connected.

#### 2. CIDR Notation
CIDR (Classless Inter-Domain Routing) defines the size of a network.

Example:
- 10.0.0.0/16

The /16 indicates that the first 16 bits define the network portion of the address, leaving the remaining bits for host addresses.

This results in:
- 2^(32−16) = 65,536 possible IP addresses

CIDR allows flexible network sizing instead of rigid class-based networks used in early internet architecture.

#### 3. Subnets = Network Segmentation
Subnets divide the VPC into smaller logical networks.
Benefita include:
- Security isolation
- Workload seperation
- Traffic control
- Easier scaling

For example:
- 10.0.1.0/24 - public services
- 10.0.11.0/24 - private services

This segmentation allows different routing rules and security policies to be applied to different parts of the infrastructure.

#### 4. Public vs Private Subnets
The difference between public and private subnets is determined by routing configuration.

- Public subnet: Route to Internet Gateway
- Private subnet: No direct route to Internet Gateway

This design ensures that sensitive systems remain protected while still allowing public services to interact with users.

#### 5. Availability Zones and High Availability
Cloud systems must be designed assuming failures will occur.

By distributing infrastructure across multiple Availability Zones, applications can survive:
- Data center outages
- power failures
- Hardware failures
- Network disruptions

This concept is fundamental in DevOps reliability engineering and cloud architecture design.

## CIDR Block Understanding

CIDR notation determines how large or small a network is.

Examples:
/32 = 1 IP address
/24 = 256 IP addresses
/16 = 65,536 IP addresses

In practice:
/24 subnet = ~251 usable addresses

#### Why Not All IPs Are Usable
AWS reserves five IP addresses in every subnet.

Example for 10.0.1.0/24:
Reserved addresses:
- 10.0.1.0   → network address
- 10.0.1.1   → VPC router
- 10.0.1.2   → DNS
- 10.0.1.3   → future AWS use
- 10.0.1.255 → broadcast

Remaining usable addresses:
- 256 - 5 = 251

This is important when planning large-scale deployments.