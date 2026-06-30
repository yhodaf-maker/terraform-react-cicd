# React CI/CD Web Hosting with Terraform & GitHub Actions OIDC

An end-to-end automated deployment pipeline that provisions secure, high-performance static website hosting on AWS using Terraform and deploys a React application with a fully secure CI/CD pipeline using GitHub Actions and OpenID Connect (OIDC).

---

## 🏗️ Architecture Overview

The pipeline leverages secure-by-default architecture separating deployment credentials from infrastructure code:

```
                    +----------------------+
                    |      Developer       |
                    +----------+-----------+
                               |
                               | git push (to main)
                               ▼
                    +----------------------+
                    | GitHub Repository    |
                    +----------+-----------+
                               |
                               ▼
                    +----------------------+
                    | GitHub Actions       |
                    |----------------------|
                    | 1. Run TF Validate   |
                    | 2. Build React App   |
                    | 3. Authenticate OIDC |
                    | 4. Upload to S3      |
                    | 5. Invalidate CDN    |
                    +----------+-----------+
                               |
                               ▼
                    +----------------------+
                    | AWS IAM Role (OIDC)  |
                    +----------+-----------+
                               |
                               ▼
                    +----------------------+
                    | Amazon S3 Bucket     | (Blocked public access)
                    +----------+-----------+
                               |
                               ▼
                    +----------------------+
                    | Amazon CloudFront    | (Caching / HTTPS / OAC)
                    +----------+-----------+
                               |
                               ▼
                    +----------------------+
                    | Browser / End Users  |
                    +----------------------+
```

### Flow Descriptions:
1. **Deployment Flow**: The developer pushes changes to the `app/` directory on the `main` branch. GitHub Actions triggers, validates Terraform configs, builds the React bundle, logs into AWS securely using an OIDC Role (no static keys), syncs the static files to S3, and invalidates the CloudFront cache.
2. **User Request Flow**: End users request the website through the CloudFront URL. CloudFront fetches the static resources from S3 via Origin Access Control (OAC), caches them globally, and serves them securely over HTTPS.

---

## 🛠️ AWS Component Explanations

- **Amazon S3**: Serves as the storage backend hosting all the static assets (HTML, CSS, JS, images) of the React application.
- **Amazon CloudFront**: A Global Content Delivery Network (CDN) that caches application files at edge locations globally to reduce latency and serves the site securely over HTTPS.
- **Origin Access Control (OAC)**: Secures the S3 bucket by blocking all direct public access and permitting *only* the CloudFront distribution to request files.
- **AWS IAM Role (OIDC)**: Creates a secure trust relationship between GitHub and AWS. GitHub Actions authenticates using short-lived tokens, eliminating the need to store long-lived AWS Access Keys in GitHub Secrets.

---

## 🚀 Deployment Instructions

### Phase 1: Provision Infrastructure with Terraform

1. Ensure you have the **AWS CLI** configured with administrator credentials.
2. Navigate to the `terraform/` folder:
   ```bash
   cd terraform
   ```
3. Initialize the Terraform workspace (installs providers):
   ```bash
   terraform init
   ```
4. Format and validate the configuration files:
   ```bash
   terraform fmt
   terraform validate
   ```
5. Deploy the resources to AWS:
   ```bash
   terraform apply
   ```
6. Take note of the printed outputs:
   - `s3_bucket_name`
   - `cloudfront_domain_name` (Your production website URL)

---

### Phase 2: Configure GitHub Repository Secrets

To connect your GitHub repository with AWS, add the following secrets in **Settings > Secrets and variables > Actions > Repository secrets**:

| Secret Name | Description | Source |
|------|------|------|
| `AWS_ROLE_ARN` | The ARN of the AWS IAM Role created for GitHub OIDC | AWS IAM Console |
| `AWS_S3_BUCKET_NAME` | The name of the created S3 assets bucket | Terraform Output (`s3_bucket_name`) |
| `CLOUDFRONT_DISTRIBUTION_ID` | The ID of the CloudFront distribution | AWS CloudFront / Terraform |

---

### Phase 3: Trigger the Pipeline

1. Make changes to your React app under the `app/` directory (e.g. edit `app/src/App.tsx`).
2. Add, commit, and push your changes to the `main` branch:
   ```bash
   git add .
   git commit -m "update application content"
   git push origin main
   ```
3. Monitor your pipeline execution under the **Actions** tab of your GitHub repository.
4. Once completed, your changes will instantly be visible at your CloudFront URL.
