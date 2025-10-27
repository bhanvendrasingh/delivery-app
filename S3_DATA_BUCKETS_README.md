# S3 Data Buckets Configuration

This document describes the S3 bucket configuration for the Go-Bharat application's file storage needs.

## 📦 Bucket Overview

The Go-Bharat infrastructure includes two types of S3 buckets:

### 1. Website Bucket (`go-bharat-{env}-website`)
- **Purpose**: Static website hosting for the frontend application
- **Access**: Private (accessed via CloudFront only)
- **Region**: Same as main infrastructure (ap-south-2)
- **Features**: Versioning enabled, public access blocked

### 2. Data Bucket (`go-bharat-{env}-data`)
- **Purpose**: File uploads and user-generated content
- **Access**: Public read access for uploaded files
- **Region**: us-east-1 (for global accessibility)
- **Features**: Versioning enabled, lifecycle management

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudFront    │────│  Website Bucket  │    │   Data Bucket   │
│  Distribution   │    │  (Static Files)  │    │ (File Uploads)  │
│                 │    │                  │    │                 │
│ - Global CDN    │    │ - React/Vue App  │    │ - User Photos   │
│ - SSL/TLS       │    │ - CSS/JS Assets  │    │ - Documents     │
│ - Caching       │    │ - Images/Icons   │    │ - Media Files   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────────┐
                    │   Go-Bharat App    │
                    │   (ECS Services)    │
                    │                     │
                    │ - API Gateway       │
                    │ - Customer Service  │
                    │ - Restaurant Svc    │
                    │ - Order Service     │
                    └─────────────────────┘
```

## 🔧 Configuration Details

### Website Bucket Configuration

```hcl
# Secure static website hosting
resource "aws_s3_bucket" "website" {
  bucket = "${var.project}-${var.environment}-website"
  
  # Security: Block all public access
  # Content served via CloudFront only
}

# Features:
- Versioning enabled for rollback capability
- Public access completely blocked
- CloudFront Origin Access Control (OAC) for secure access
- Integrated with CloudFront for global distribution
```

### Data Bucket Configuration

```hcl
# Public file storage for uploads
resource "aws_s3_bucket" "data" {
  bucket   = "${var.project}-${var.environment}-data"
  provider = aws.us_east_1  # Global region for accessibility
  
  # Public access enabled for file downloads
}

# Features:
- Cross-region deployment (us-east-1)
- Public read access for uploaded files
- Versioning enabled (30-day retention for old versions)
- Lifecycle management for cost optimization
- Multipart upload cleanup (7 days)
```

## 📁 File Organization

### Website Bucket Structure
```
go-bharat-{env}-website/
├── index.html              # Main application entry point
├── static/
│   ├── css/               # Stylesheets
│   ├── js/                # JavaScript bundles
│   └── images/            # Static images and icons
├── assets/                # Application assets
└── manifest.json          # PWA manifest
```

### Data Bucket Structure
```
go-bharat-{env}-data/
├── uploads/
│   ├── customers/
│   │   ├── profiles/      # Customer profile pictures
│   │   └── documents/     # ID verification documents
│   ├── restaurants/
│   │   ├── logos/         # Restaurant logos
│   │   ├── menus/         # Menu images
│   │   └── photos/        # Food and restaurant photos
│   ├── orders/
│   │   └── receipts/      # Order receipts and invoices
│   └── delivery/
│       └── proofs/        # Delivery proof photos
└── temp/                  # Temporary uploads (auto-cleanup)
```

## 🔐 Security Configuration

### Website Bucket Security
- **Public Access**: Completely blocked
- **Access Method**: CloudFront Origin Access Control only
- **Encryption**: Server-side encryption enabled
- **Versioning**: Enabled for content rollback

### Data Bucket Security
- **Public Access**: Read-only for uploaded files
- **Upload Access**: Controlled via IAM roles and policies
- **Encryption**: Server-side encryption enabled
- **CORS**: Configured for web application uploads

### IAM Policies

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::go-bharat-*-data/uploads/*"
    }
  ]
}
```

## 🔄 Lifecycle Management

### Data Bucket Lifecycle Rules

1. **Version Management**
   - Non-current versions deleted after 30 days
   - Reduces storage costs while maintaining recent history

2. **Multipart Upload Cleanup**
   - Incomplete multipart uploads aborted after 7 days
   - Prevents storage waste from failed uploads

3. **Temporary File Cleanup**
   - Files in `/temp/` folder deleted after 1 day
   - Automatic cleanup of temporary uploads

## 📊 Monitoring & Metrics

### CloudWatch Metrics
- **Storage Usage**: Monitor bucket size and object count
- **Request Metrics**: Track GET/PUT request patterns
- **Error Rates**: Monitor 4xx/5xx error responses
- **Data Transfer**: Track bandwidth usage

### Cost Optimization
- **Storage Classes**: Automatic transition to IA/Glacier for old files
- **Lifecycle Policies**: Automatic cleanup of temporary and old files
- **CloudFront Caching**: Reduced origin requests for static content

## 🚀 Usage Examples

### Frontend File Upload
```javascript
// Upload user profile picture
const uploadFile = async (file, userId) => {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await fetch(`/api/upload/customer/${userId}/profile`, {
    method: 'POST',
    body: formData,
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  return response.json(); // Returns S3 URL
};
```

### Backend File Processing
```javascript
// Generate signed URL for secure upload
const generateUploadUrl = (key, contentType) => {
  return s3.getSignedUrl('putObject', {
    Bucket: process.env.DATA_BUCKET_NAME,
    Key: key,
    ContentType: contentType,
    Expires: 3600 // 1 hour
  });
};
```

## 🔧 Environment Variables

### Required Environment Variables
```bash
# Website bucket (for CloudFront integration)
WEBSITE_BUCKET_NAME=go-bharat-qa-website
CLOUDFRONT_DISTRIBUTION_ID=E1234567890ABC

# Data bucket (for file uploads)
DATA_BUCKET_NAME=go-bharat-qa-data
DATA_BUCKET_REGION=us-east-1
DATA_BUCKET_URL=https://go-bharat-qa-data.s3.amazonaws.com
```

## 📋 Deployment Checklist

### QA Environment
- [ ] Website bucket created with versioning
- [ ] Data bucket created in us-east-1
- [ ] CloudFront distribution configured
- [ ] CORS policy applied to data bucket
- [ ] Lifecycle policies configured
- [ ] IAM roles have proper S3 permissions

### Production Environment
- [ ] All QA checklist items completed
- [ ] Custom domain configured for CloudFront
- [ ] SSL certificate attached
- [ ] WAF rules applied to CloudFront
- [ ] Enhanced monitoring enabled
- [ ] Backup and disaster recovery tested

## 🆘 Troubleshooting

### Common Issues

1. **CORS Errors**
   - Verify CORS policy on data bucket
   - Check allowed origins and methods

2. **Upload Failures**
   - Verify IAM permissions for upload service
   - Check bucket policy and ACLs

3. **CloudFront Cache Issues**
   - Create invalidation for updated static files
   - Review cache behaviors and TTL settings

4. **Cross-Region Access**
   - Ensure data bucket region is correctly configured
   - Verify cross-region IAM permissions

### Useful Commands

```bash
# Check bucket configuration
aws s3api get-bucket-location --bucket go-bharat-qa-data
aws s3api get-bucket-versioning --bucket go-bharat-qa-website

# Monitor bucket usage
aws s3 ls s3://go-bharat-qa-data --recursive --human-readable --summarize

# Test CORS configuration
curl -H "Origin: https://app.gobharatfresh.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://go-bharat-qa-data.s3.amazonaws.com/

# CloudFront invalidation
aws cloudfront create-invalidation \
    --distribution-id E1234567890ABC \
    --paths "/*"
```