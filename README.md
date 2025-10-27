# Go-Bharat Infrastructure as Code

This repository contains the Terraform infrastructure code for the Go-Bharat food delivery application, supporting both QA and Production environments on AWS.

## 🏗️ Architecture Overview

The infrastructure is built using a modular approach with separate environments:

- **QA Environment**: Cost-optimized setup for testing and development
- **Production Environment**: High-availability, secure setup with WAF protection

### Key Components

#### Core Infrastructure
- **ECS Cluster**: Container orchestration with EC2 launch type and auto-scaling
- **Application Load Balancer**: Traffic distribution with SSL termination
- **VPC**: Multi-AZ isolated network with public/private subnets
- **CloudWatch**: Comprehensive monitoring, logging, and Container Insights

#### Data Layer
- **DocumentDB (MongoDB)**: Managed NoSQL database with multi-AZ support
- **ElastiCache (Redis/Valkey)**: In-memory caching and session storage
- **Elasticsearch**: Search and analytics engine with logging
- **Kafka on EC2**: Message streaming platform

#### Storage & CDN
- **S3 Buckets**: Website hosting and file uploads with versioning
- **CloudFront**: Global CDN with hybrid static/dynamic content delivery
- **WAF**: Web Application Firewall (Production only) with rate limiting

#### Microservices (9 Services)
- **API Gateway Service**: Main entry point and routing
- **Customer Service**: User management and profiles
- **Restaurant Service**: Restaurant data and menu management
- **Order Service**: Order processing and tracking
- **Payment Service**: Payment processing and transactions
- **Delivery Partner Service**: Driver management and tracking
- **Communication Service**: Notifications and messaging
- **Support Agent Service**: Customer support functionality
- **Data Sync Service**: Data synchronization between services

## 📁 Repository Structure

```
├── environments/
│   ├── qa/                    # QA environment configuration
│   │   └── main.tf           # QA-specific resource definitions
│   └── prod/                  # Production environment configuration
│       └── main.tf           # Production-specific resource definitions
├── modules/
│   └── infrastructure/        # Main infrastructure module
│       ├── main.tf           # Provider config and VPC setup
│       ├── variables.tf      # Input variables and validation
│       ├── outputs.tf        # Output values for other modules
│       ├── locals.tf         # Local values and naming conventions
│       ├── iam.tf           # IAM roles and policies
│       ├── security_groups.tf # Security group definitions
│       ├── autoscaling.tf    # Auto Scaling Group configuration
│       ├── ecs.tf           # ECS cluster and service definitions
│       ├── database.tf       # DocumentDB (MongoDB) cluster
│       ├── redis.tf         # ElastiCache Redis configuration
│       ├── elasticsearch.tf  # Elasticsearch domain setup
│       ├── ec2.tf           # Kafka EC2 instances
│       ├── s3.tf            # S3 buckets for website and data
│       ├── cloudfront.tf    # CloudFront distribution
│       ├── waf.tf           # WAF rules (Production only)
│       ├── load_balancer.tf # Application Load Balancer
│       └── templates/       # ECS task definition templates
└── README.md                # This documentation
```

## 🚀 Getting Started

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **SSH Key Pair** at `~/.ssh/id_rsa.pub`

### Environment Setup

#### 1. Backend State Setup

First, create the S3 bucket and DynamoDB table for Terraform state:

```bash
# For QA
cd environments/qa
terraform init
terraform apply -target=module.backend

# For Production
cd environments/prod
terraform init
terraform apply -target=module.backend
```

#### 2. Deploy Infrastructure

```bash
# QA Environment
cd environments/qa
terraform plan
terraform apply

# Production Environment
cd environments/prod
terraform plan
terraform apply
```

## 🔧 Configuration

### Environment Configurations

#### QA Environment
- **Compute**: t3.medium/large instances with spot instances for cost optimization
- **Database**: Single-instance DocumentDB with 7-day backup retention
- **Cache**: Single Redis node (cache.t3.micro)
- **Search**: Single Elasticsearch node (t3.small)
- **Kafka**: Single t3.small instance
- **Storage**: 7-day log retention, basic lifecycle policies
- **Security**: HTTPS enabled, basic security groups

#### Production Environment
- **Compute**: m5/c5 large+ instances, NO spot instances for reliability
- **Database**: Multi-AZ DocumentDB cluster (3 instances, r6g.large)
- **Cache**: Multi-AZ Redis cluster (3 nodes, cache.r6g.large)
- **Search**: Multi-AZ Elasticsearch cluster (3 nodes, r6g.large) with dedicated masters
- **Kafka**: Multi-AZ cluster (3 m5.large instances)
- **Storage**: 30-day log retention, comprehensive lifecycle policies
- **Security**: WAF protection, rate limiting, geo-blocking capabilities
- **CDN**: Global CloudFront distribution with custom domain support

### Key Configuration Differences

| Component | QA Configuration | Production Configuration |
|-----------|------------------|-------------------------|
| **ECS Services** | 1-2 replicas per service | 3-5 replicas (critical services) |
| **DocumentDB** | 1 instance, db.t3.medium | 3 instances, db.r6g.large |
| **Redis** | 1 node, cache.t3.micro | 3 nodes, cache.r6g.large |
| **Elasticsearch** | 1 node, t3.small | 3 nodes + 3 masters, r6g.large |
| **Kafka** | 1 instance, t3.small | 3 instances, m5.large |
| **WAF** | Disabled | Enabled with comprehensive rules |
| **Backup Retention** | 7 days | 30 days |
| **Deletion Protection** | Disabled | Enabled |

## 🔐 Security

### IAM Roles & Policies
- **ECS Task Execution Role**: Container image pulling and CloudWatch logging
- **ECS Task Role**: Application runtime permissions for AWS services
- **ECS Instance Role**: EC2 instances in ECS cluster with SSM access
- **Elasticsearch Service Role**: Domain management and logging

### Security Groups (Network Isolation)
- **ALB Security Group**: HTTP/HTTPS access from internet (80, 443)
- **ECS Security Group**: Application ports from ALB only (8081-9797)
- **DocumentDB Security Group**: MongoDB access from ECS only (27017)
- **Redis Security Group**: Cache access from ECS only (6379)
- **Elasticsearch Security Group**: Search access from ECS only (443, 9200)
- **Kafka Security Group**: Message streaming from ECS only (9092, 2181)

### Data Protection
- **Encryption at Rest**: All databases, S3 buckets, and EBS volumes
- **Encryption in Transit**: TLS 1.2+ for all communications
- **Network Isolation**: Private subnets for all data services
- **Access Control**: VPC endpoints and security group restrictions

### Secrets Management
- **AWS Systems Manager Parameter Store**: Database credentials and connection strings
- **Secure String Parameters**: Encrypted sensitive values
- **Environment Variables**: Secure injection into ECS tasks
- **Lifecycle Management**: Automatic password rotation support

### Production Security Features
- **WAF Protection**: SQL injection, XSS, and known bad inputs protection
- **Rate Limiting**: 2000 requests per 5-minute window per IP
- **Geo-blocking**: Configurable country-based restrictions
- **IP Whitelisting**: Allow-list for trusted IP addresses
- **CloudWatch Logging**: Comprehensive security event logging

## 📊 Monitoring & Observability

### CloudWatch Integration
- **Container Insights**: ECS cluster, service, and task-level metrics
- **Application Logs**: Centralized logging for all 9 microservices
- **Infrastructure Logs**: VPC Flow Logs, ALB access logs, WAF logs
- **Database Logs**: DocumentDB audit and profiler logs (Production)
- **Search Logs**: Elasticsearch slow query and application logs

### Log Retention Policies
- **QA Environment**: 7 days retention for cost optimization
- **Production Environment**: 30 days retention for compliance
- **WAF Logs**: Detailed request/response logging with PII redaction

### Metrics & Dashboards
- **ECS Metrics**: CPU, memory, network utilization per service
- **Database Metrics**: Connection count, query performance, storage usage
- **Cache Metrics**: Hit/miss ratios, eviction rates, connection count
- **Search Metrics**: Query latency, indexing rate, cluster health
- **Load Balancer Metrics**: Request count, latency, error rates
- **Custom Application Metrics**: Business KPIs and performance indicators

### Auto Scaling Triggers
- **CPU-based Scaling**: Scale up at 90%, scale down at 40%
- **Memory-based Scaling**: Automatic scaling based on memory utilization
- **Custom Metrics**: Application-specific scaling triggers
- **Cooldown Periods**: 5-minute cooldown to prevent flapping

## 🚀 CI/CD Pipeline

The GitLab CI pipeline includes:

1. **Validate**: Terraform syntax and formatting checks
2. **Plan**: Generate execution plan
3. **Deploy**: Apply changes (manual approval required)
4. **Destroy**: Tear down infrastructure (manual only)

### Pipeline Triggers
- **Merge Requests**: Validation and planning
- **Main Branch**: Full deployment pipeline
- **Manual**: Destroy operations

## 🔄 Deployment Process

### QA Deployment
1. Push changes to feature branch
2. Create merge request
3. Pipeline runs validation and planning
4. Merge to main branch
5. Manual approval for QA deployment

### Production Deployment
1. QA deployment successful
2. Manual approval for production planning
3. Review production plan
4. Manual approval for production deployment

## 📝 Best Practices

### Resource Naming
- Format: `{project}-{environment}-{resource-type}`
- Example: `go-bharat-prod-cluster`

### Tagging Strategy
- **Project**: go-bharat
- **Environment**: qa/prod
- **ManagedBy**: terraform
- **Owner**: Team responsible
- **CostCenter**: Billing allocation

### State Management
- Remote state in S3 with encryption
- State locking with DynamoDB
- Separate state files per environment

## 🛠️ Troubleshooting

### Common Issues

1. **State Lock**: Check DynamoDB table for stuck locks
2. **Service Deployment Failures**: Check ECS service events and task definitions
3. **Database Connection Issues**: Verify security group rules and parameter store values
4. **Load Balancer Health Checks**: Ensure services respond on health check endpoints
5. **Elasticsearch Access**: Verify VPC configuration and security groups
6. **Kafka Connectivity**: Check EC2 instance status and security group rules

### Useful Commands

```bash
# ECS Cluster Management
aws ecs describe-clusters --clusters go-bharat-qa-cluster
aws ecs list-services --cluster go-bharat-qa-cluster
aws ecs describe-services --cluster go-bharat-qa-cluster --services <service-name>

# Task and Container Debugging
aws ecs list-tasks --cluster go-bharat-qa-cluster --service-name <service-name>
aws ecs describe-tasks --cluster go-bharat-qa-cluster --tasks <task-arn>

# Load Balancer Health Checks
aws elbv2 describe-target-groups --load-balancer-arn <alb-arn>
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Database Connectivity
aws docdb describe-db-clusters --db-cluster-identifier go-bharat-qa-mongodb-cluster
aws docdb describe-db-instances --db-instance-identifier go-bharat-qa-mongodb-0

# Log Analysis
aws logs describe-log-groups --log-group-name-prefix "/ecs/go-bharat"
aws logs tail /ecs/go-bharat-qa/api-gateway-service --follow
aws logs tail /aws/elasticsearch/domains/go-bharat-qa-elasticsearch --follow

# Parameter Store Values
aws ssm get-parameters --names "/go-bharat/qa/mongodb/endpoint" "/go-bharat/qa/redis/endpoint"
aws ssm get-parameter --name "/go-bharat/qa/mongodb/connection_string" --with-decryption

# S3 and CloudFront
aws s3 ls s3://go-bharat-qa-website/
aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`go-bharat qa website distribution`]'
```

### Performance Optimization

1. **Database Performance**: Monitor DocumentDB slow queries and optimize indexes
2. **Cache Hit Ratios**: Ensure Redis cache is properly utilized
3. **Search Performance**: Monitor Elasticsearch query latency and optimize mappings
4. **CDN Optimization**: Review CloudFront cache behaviors and TTL settings
5. **Auto Scaling**: Fine-tune scaling policies based on actual usage patterns

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes to appropriate environment
3. Test in QA environment first
4. Create merge request with detailed description
5. Ensure all pipeline checks pass
6. Request review from team members

## 📞 Support

For issues and questions:
- Create GitLab issue with detailed description
- Tag relevant team members
- Include environment and error details
- Attach relevant logs or screenshots

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)