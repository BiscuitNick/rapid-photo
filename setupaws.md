⏺ 1. AWS Account and Credentials Setup

  Create an AWS Account (if you don't have one)

  1. Go to https://aws.amazon.com and create an account
  2. Verify your email and set up billing

  Create IAM User for Development

  # Option A: Use AWS Console
  # 1. Go to IAM Console: https://console.aws.amazon.com/iam
  # 2. Click "Users" → "Add users"
  # 3. Username: "rapid-photo-dev"
  # 4. Enable "Access key - Programmatic access"
  # 5. Attach policies:
  #    - AmazonEC2FullAccess
  #    - AmazonS3FullAccess
  #    - AmazonRDSFullAccess
  #    - AmazonSQSFullAccess
  #    - AWSLambda_FullAccess
  #    - AmazonECSFullAccess
  #    - AmazonCognitoPowerUser
  #    - CloudWatchFullAccess
  #    - IAMFullAccess (for creating roles)
  # 6. Save the Access Key ID and Secret Access Key

  Configure AWS CLI

  # Install AWS CLI
  brew install awscli  # macOS
  # Or download from: https://aws.amazon.com/cli/

  # Configure credentials
  aws configure
  # AWS Access Key ID: <your-access-key>
  # AWS Secret Access Key: <your-secret-key>
  # Default region name: us-east-1
  # Default output format: json

  # Test configuration
  aws sts get-caller-identity

  2. Install Required Tools

  # Terraform (1.9+)
  brew install terraform
  terraform --version

  # Docker
  # Download Docker Desktop from: https://www.docker.com/products/docker-desktop
  # Or install via:
  brew install --cask docker

  # Java 17+ (for backend)
  brew install openjdk@17
  java --version

  # Python 3.13+ (for Lambda)
  brew install python@3.13
  python3 --version

  # Node.js 20+ (for web)
  brew install node@20
  node --version

  # Flutter 3.27+ (for mobile - optional if only running web/backend)
  # Download from: https://flutter.dev/docs/get-started/install
  flutter --version

  3. AWS Amplify Gen 2 Setup

  Amplify Gen 2 handles Cognito authentication for the mobile and web apps.

  # Install Amplify CLI
  npm install -g @aws-amplify/cli@latest

  # Navigate to web or mobile directory
  cd web  # or cd mobile

  # Initialize Amplify (if not already configured)
  amplify configure project

  # Add authentication
  amplify add auth
  # Choose:
  # - Do you want to use the default authentication and security configuration? Default configuration
  # - How do you want users to be able to sign in? Email
  # - Do you want to configure advanced settings? No

  # Add storage
  amplify add storage
  # Choose:
  # - Select from one of the below mentioned services: Content (Images, audio, video, etc.)
  # - Provide bucket name: rapid-photo-uploads-dev
  # - Who should have access: Auth users only
  # - What kind of access do you want for Authenticated users? create/update, read, delete

  # Deploy Amplify backend
  amplify push

  This creates:
  - Cognito User Pool (for user authentication)
  - Cognito Identity Pool (for AWS credentials)
  - S3 bucket (for uploads, managed separately via Terraform)
  - amplify_outputs.json (configuration file)

  4. Set Up Local PostgreSQL Database

  # Start PostgreSQL via Docker
  docker run -d \
    --name rapidphoto-postgres \
    -e POSTGRES_DB=rapidphoto \
    -e POSTGRES_USER=rapidphoto \
    -e POSTGRES_PASSWORD=rapidphoto_dev \
    -p 5432:5432 \
    postgres:17.6

  # Verify it's running
  docker ps | grep rapidphoto-postgres

  # Test connection
  docker exec -it rapidphoto-postgres psql -U rapidphoto -d rapidphoto
  # Type \q to exit

  5. Configure Environment Variables

  # Copy example environment files
  cp .env.example .env
  cp web/.env.example web/.env.local

  # Edit .env (root level - for Task Master AI only)
  # Add your Anthropic API key if using Task Master
  nano .env

  Web Environment (.env.local)

  After Amplify setup, update web/.env.local:

  # Get Cognito details from Amplify
  amplify status

  # Edit web/.env.local
  cd web
  nano .env.local

  Update with your Amplify outputs:
  # AWS Cognito Configuration (from amplify_outputs.json)
  VITE_COGNITO_USER_POOL_ID=us-east-1_XXXXXXX
  VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
  VITE_COGNITO_IDENTITY_POOL_ID=us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  VITE_AWS_REGION=us-east-1

  # S3 Configuration (will be created by Terraform)
  VITE_S3_BUCKET_NAME=rapid-photo-uploads-dev

  # Backend API (local development)
  VITE_API_BASE_URL=http://localhost:8080

  6. Deploy AWS Infrastructure with Terraform

  Now deploy the main infrastructure (VPC, RDS, S3, SQS, ECS, Lambda):

  cd infrastructure

  # Initialize Terraform
  terraform init

  # Create a dev.tfvars file
  cat > environments/dev.tfvars << EOF
  environment = "dev"
  project_name = "rapid-photo"
  aws_region = "us-east-1"

  # Database
  db_instance_class = "db.t4g.micro"  # Free tier eligible
  db_multi_az = false  # Single AZ for dev
  db_deletion_protection = false  # Allow deletion in dev
  db_skip_final_snapshot = true  # Skip snapshot for dev

  # ECS
  ecs_min_capacity = 1  # Minimal for dev
  ecs_max_capacity = 2
  ecs_task_cpu = 512  # Smaller for dev
  ecs_task_memory = 1024

  # Lambda
  lambda_reserved_concurrency = 10  # Lower for dev

  # Monitoring
  create_sns_topic = false  # No alarms for dev
  alarm_email_endpoints = []
  EOF

  # Preview what will be created
  terraform plan -var-file=environments/dev.tfvars

  # Apply infrastructure (this will create all AWS resources)
  terraform apply -var-file=environments/dev.tfvars
  # Type 'yes' to confirm

  # Save important outputs
  terraform output > ../outputs.txt

  This creates:
  - VPC with public/private subnets
  - RDS PostgreSQL 17.6 database
  - S3 buckets for uploads, thumbnails, processed images
  - SQS queue for image processing
  - ECS Fargate cluster for backend API
  - Lambda function for image processing
  - ALB (Application Load Balancer)
  - CloudWatch dashboards and alarms

  Note: This will incur AWS costs. The dev configuration above uses minimal resources.

  7. Build and Deploy Applications

  Backend (Spring Boot)

  cd backend

  # Build the Docker image
  ./gradlew clean build
  docker build -t rapid-photo-backend:latest .

  # Get ECR repository URI from Terraform outputs
  cd ../infrastructure
  ECR_URI=$(terraform output -raw ecr_repository_url)  # If you created one

  # Or create ECR repository manually
  aws ecr create-repository --repository-name rapid-photo/backend --region us-east-1

  # Get the repository URI
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  ECR_URI="${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/rapid-photo/backend"

  # Login to ECR
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

  # Tag and push
  docker tag rapid-photo-backend:latest ${ECR_URI}:latest
  docker push ${ECR_URI}:latest

  # Update Terraform with the image
  cd ../infrastructure
  terraform apply -var-file=environments/dev.tfvars -var="backend_docker_image=${ECR_URI}:latest"

  Lambda (Image Processor)

  cd lambda

  # Create deployment package
  mkdir -p dist
  pip install -r requirements.txt -t dist/
  cp -r src/* dist/
  cd dist && zip -r ../lambda.zip . && cd ..

  # Deploy via Terraform
  cd ../infrastructure
  terraform apply -var-file=environments/dev.tfvars -target=module.compute.aws_lambda_function.image_processor

  Web App

  cd web

  # Install dependencies
  npm install

  # Run locally (for testing)
  npm run dev
  # Visit http://localhost:5173

  # Build for production
  npm run build

  # Deploy to S3 (if you want to host on AWS)
  aws s3 mb s3://rapid-photo-web-dev-$ACCOUNT_ID
  aws s3 sync dist/ s3://rapid-photo-web-dev-$ACCOUNT_ID/ --delete

  8. Verify Everything Works

  # Check ECS service is running
  aws ecs describe-services \
    --cluster rapid-photo-dev-cluster \
    --services rapid-photo-dev-backend

  # Get ALB URL
  cd infrastructure
  terraform output alb_url

  # Test backend API
  curl http://<alb-url>/actuator/health

  # Check Lambda
  aws lambda list-functions | grep rapid-photo

  # Test Lambda
  aws lambda invoke \
    --function-name rapid-photo-dev-image-processor \
    --payload '{"test": true}' \
    output.json

  Quick Start for Local Development

  If you just want to run locally without full AWS deployment:

  # 1. Start local PostgreSQL
  docker run -d --name rapidphoto-postgres \
    -e POSTGRES_DB=rapidphoto \
    -e POSTGRES_USER=rapidphoto \
    -e POSTGRES_PASSWORD=rapidphoto_dev \
    -p 5432:5432 \
    postgres:17.6

  # 2. Set up Amplify Auth (minimal)
  cd web && amplify add auth && amplify push

  # 3. Run backend locally
  cd backend
  ./gradlew bootRun

  # 4. Run web locally
  cd web
  npm install && npm run dev

  Cost Estimates

  Dev Environment (Terraform deployed):
  - RDS db.t4g.micro: ~$15/month
  - ECS Fargate (1 task): ~$15/month
  - Lambda (100K invocations): ~$0.20/month
  - S3 storage (100GB): ~$2.30/month
  - Total: ~$35-40/month

  To minimize costs:
  - Use Terraform to destroy when not in use: terraform destroy -var-file=environments/dev.tfvars
  - Use AWS Free Tier resources where possible

  Next Steps

  1. Which approach do you prefer?
    - Full AWS deployment with Terraform
    - Local development only
    - Hybrid (local backend + AWS Amplify Auth)
  2. What's your immediate goal?
    - Test the application locally
    - Deploy to AWS for production
    - Set up CI/CD pipeline

  Let me know and I can help you proceed with the specific setup!

  Todos
  ☐ Set up AWS account and credentials
  ☐ Install required tools (AWS CLI, Terraform, Docker, etc.)
  ☐ Configure AWS Amplify Gen 2 for authentication
  ☐ Deploy infrastructure with Terraform
  ☐ Set up local development environment
  ☐ Configure environment variables
  ☐ Test deployment and verify services