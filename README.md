<h1 align="center">AWS Educate Offical Website Backend</h1>

<p align="center">
  A fully serverless email system designed with a microservices architecture.
</p>

<p align="center">
  <a aria-label="License" href="https://github.com/aws-educate-tw/aws-educate-tpet-backend/blob/main/LICENSE">
    <img alt="" src="https://img.shields.io/github/license/aws-educate-tw/aws-educate-tpet-backend">
  </a>
  <a aria-label="Python version" href="https://www.python.org/downloads/release/python-3110/">
    <img alt="Python Version" src="https://img.shields.io/badge/python-3.11-blue.svg">
  </a>
  <a aria-label="Terraform version" href="https://github.com/hashicorp/terraform/releases/tag/v1.8.3">
    <img alt="Terraform Version" src="https://img.shields.io/badge/terraform-1.8.3-7B42BC">
  </a>
</p>

## Setup and Installation

### Prerequisites

1. **Tools**:

   - Python 3.11
   - [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.8.3 or higher)
   - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   - [Docker](https://www.docker.com/products/docker-desktop)
   - Domain Name (for CloudFront distribution & API Gateway custom domain)

2. **AWS Setup**:
   - Ensure proper AWS IAM credentials are configured.
   - Ensure that your DNS is hosted on Route 53.
   - Ensure the AWS SES Production Access is granted.
   - Ensure the shrared infrastructure is deployed (Cognito, ACM, etc.).

### Installation Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/aws-educate-tw/aws-educate-official-website-backend.git
   cd aws-educate-official-website-backend
   ```

2. Set up environment variables:

   ```bash
   export AWS_PROFILE="your-profile"
   ```

3. Initialize Terraform (Take one of the microservices as an example for deployment):

   ```bash
   cd src/file_service/terraform
   terraform init -backend-config="dev.tfbackend" -reconfigure
   ```

4. Deploy resources:

   ```bash
   terraform plan -var-file="dev.tfvars"
   terraform apply -var-file="dev.tfvars"
   ```

## Contact

If you encounter any issues, feel free to reach out at <dev@aws-educate.tw> or submit an issue.

## License

This project is licensed under the Apache-2.0 License. See the [LICENSE](LICENSE) file for details.

Copyright © 2024 AWS Educate Cloud Ambassador Taiwan
