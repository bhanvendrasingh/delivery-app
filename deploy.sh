#!/bin/bash

# Go-Bharat Infrastructure Deployment Script
# Usage: ./deploy.sh [qa|prod] [plan|apply|destroy]

set -e

ENVIRONMENT=$1
ACTION=${2:-plan}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(qa|prod)$ ]]; then
    print_error "Environment must be 'qa' or 'prod'"
    echo "Usage: $0 [qa|prod] [plan|apply|destroy]"
    exit 1
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Action must be 'plan', 'apply', or 'destroy'"
    echo "Usage: $0 [qa|prod] [plan|apply|destroy]"
    exit 1
fi

# Set working directory
WORK_DIR="${SCRIPT_DIR}/environments/${ENVIRONMENT}"

if [[ ! -d "$WORK_DIR" ]]; then
    print_error "Environment directory not found: $WORK_DIR"
    exit 1
fi

print_status "Deploying to ${ENVIRONMENT} environment"
print_status "Working directory: $WORK_DIR"
print_status "Action: $ACTION"

cd "$WORK_DIR"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed or not in PATH"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured or invalid"
    exit 1
fi

print_success "AWS credentials validated"

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

if [[ $? -ne 0 ]]; then
    print_error "Terraform validation failed"
    exit 1
fi

print_success "Terraform configuration is valid"

# Format check
print_status "Checking Terraform formatting..."
if ! terraform fmt -check; then
    print_warning "Terraform files are not properly formatted"
    print_status "Auto-formatting files..."
    terraform fmt
fi

# Execute the requested action
case $ACTION in
    plan)
        print_status "Creating Terraform plan..."
        terraform plan -out="tfplan-${ENVIRONMENT}"
        print_success "Plan created successfully. Review the plan above."
        print_status "To apply this plan, run: terraform apply tfplan-${ENVIRONMENT}"
        ;;
    apply)
        if [[ -f "tfplan-${ENVIRONMENT}" ]]; then
            print_status "Applying existing plan..."
            terraform apply "tfplan-${ENVIRONMENT}"
        else
            print_status "No existing plan found. Creating and applying..."
            if [[ "$ENVIRONMENT" == "prod" ]]; then
                print_warning "You are about to deploy to PRODUCTION!"
                read -p "Are you sure you want to continue? (yes/no): " confirm
                if [[ $confirm != "yes" ]]; then
                    print_status "Deployment cancelled"
                    exit 0
                fi
            fi
            terraform apply
        fi
        print_success "Deployment completed successfully!"
        
        # Show outputs
        print_status "Infrastructure outputs:"
        terraform output
        ;;
    destroy)
        print_warning "You are about to DESTROY the ${ENVIRONMENT} environment!"
        print_warning "This action cannot be undone!"
        read -p "Type 'destroy-${ENVIRONMENT}' to confirm: " confirm
        if [[ $confirm != "destroy-${ENVIRONMENT}" ]]; then
            print_status "Destruction cancelled"
            exit 0
        fi
        
        print_status "Destroying infrastructure..."
        terraform destroy
        print_success "Infrastructure destroyed successfully"
        ;;
esac

print_success "Operation completed successfully!"