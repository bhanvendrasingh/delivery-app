# Go-Bharat Infrastructure as Code

This repository contains the Terraform infrastructure code for the Go-Bharat application, supporting both QA and Production environments on AWS.

## 🏗️ Architecture Overview

The infrastructure is built using a modular approach with separate environments:

- **QA Environment**: Cost-optimized setup for testing and development
- **Production Environment**: High-availability, secure setup for production workloads

### Key Components

- **ECS Cluster**: Container orchestration with EC2 launch type
- **Application Load Balancer**: Traffic distribution and SSL termination
- **RDS MariaDB**: Managed database service
- **VPC**: Isolated network with public/private subnets
- **Auto Scaling**: Automatic scaling based on demand
- **ECR**: Container image repositories
- **CloudWatch**: Monitoring and logging

## 📁 Repository Structure

```
├── environments/
│   ├── qa/                    # QA environment configuration
│   │   ├── main.tf
│   │   ├── providers.tf
│   │   └── terraform.tfvars
│   └── prod/                  # Production environment configuration
│       ├── main.tf
│       ├── providers.tf
│       └── terraform.tfvars
├── modules/
│   ├── backend/               # Terraform state backend
│   └── infrastructure/        # Main infrastructure module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── locals.tf
│       ├── iam.tf
│       ├── security_groups.tf
│       ├── autoscaling.tf
│       ├── ecs.tf
│       ├── database.tf
│       ├── load_balancer.tf
│       └── templates/
├── legacy/                    # Legacy code (reference only)
│   └── README.md
└── .gitlab-ci.yml            # CI/CD pipeline
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

### Environment Variables

Each environment has its own `terraform.tfvars` file with environment-specific configurations:

#### QA Environment
- Smaller instance types (t3.small)
- Single AZ deployment
- Minimal backup retention
- HTTP only (no SSL)

#### Production Environment
- Larger instance types (t3.medium+)
- Multi-AZ deployment
- Extended backup retention
- HTTPS with SSL certificate
- Enhanced monitoring

### Key Variables

| Variable | Description | QA Default | Prod Default |
|----------|-------------|------------|--------------|
| `instance_types` | EC2 instance types | `["t3.small"]` | `["t3.medium", "t3a.medium"]` |
| `spot_instances.min` | Minimum instances | `1` | `2` |
| `spot_instances.max` | Maximum instances | `2` | `6` |
| `database.instance_class` | RDS instance class | `db.t3.micro` | `db.t3.small` |
| `database.multi_az` | Multi-AZ deployment | `false` | `true` |
| `enable_https` | Enable HTTPS | `false` | `true` |

## 🔐 Security

### IAM Roles
- **ECS Task Execution Role**: Pulls images and accesses secrets
- **ECS Task Role**: Application runtime permissions
- **ECS Instance Role**: EC2 instances in ECS cluster

### Security Groups
- **ALB Security Group**: HTTP/HTTPS access from internet
- **ECS Security Group**: Application ports from ALB only
- **RDS Security Group**: Database access from ECS only

### Secrets Management
- Database credentials stored in AWS Systems Manager Parameter Store
- Sensitive values marked as `SecureString`
- Application secrets injected as environment variables

## 📊 Monitoring

### CloudWatch Integration
- **Container Insights**: ECS cluster and service metrics
- **Log Groups**: Application and system logs
- **Custom Metrics**: Application-specific monitoring

### Alarms (Production)
- High CPU utilization
- Memory usage
- Database connections
- Application response time

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

1. **State Lock**: If Terraform state is locked, check DynamoDB table
2. **AMI Not Found**: Update AMI filters in `autoscaling.tf`
3. **Capacity Issues**: Check EC2 limits in your AWS account
4. **Database Connection**: Verify security group rules

### Useful Commands

```bash
# Check ECS cluster status
aws ecs describe-clusters --clusters go-bharat-qa-cluster

# View running tasks
aws ecs list-tasks --cluster go-bharat-qa-cluster

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View logs
aws logs tail /ecs/go-bharat-qa/webapp --follow
```

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