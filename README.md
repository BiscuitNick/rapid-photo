# RapidPhotoUpload v2.0

High-performance photo upload and processing platform built as a monorepo with multi-platform support.

## 🏗️ Architecture

This is a **monorepo** containing multiple workspaces:

- **backend/** - Spring Boot 3.5.3 WebFlux API (Java 17+)
- **lambda/** - Python 3.13 image processing Lambda (ARM64)
- **mobile/** - Flutter 3.27 mobile app (iOS/Android)
- **web/** - React 19 + Vite web application (TypeScript 5.7)
- **infrastructure/** - Terraform 1.9+ AWS infrastructure
- **docs/** - Project documentation

## 🚀 Features

- **Concurrent Upload**: Upload up to 100 photos simultaneously
- **Image Processing**: Automatic thumbnail and WebP conversion
- **AI Labeling**: AWS Rekognition for automatic photo tagging
- **Multi-Platform**: Native mobile (Flutter) and modern web (React 19)
- **Reactive Backend**: Non-blocking WebFlux with R2DBC
- **Cloud-Native**: AWS Amplify Gen 2 + ECS Fargate + Lambda

## 📋 Technology Stack

### Backend
- Java 17+, Spring Boot 3.5.3 (WebFlux)
- R2DBC + PostgreSQL 17.6
- AWS Cognito (Amplify), S3, SQS
- Micrometer + CloudWatch + X-Ray

### Lambda
- Python 3.13, Pillow 11.x
- boto3 1.35+, psycopg2-binary
- AWS Rekognition

### Mobile
- Flutter 3.27, Riverpod 3.0.1
- Amplify Gen 2, Material Design 3
- Dio HTTP client

### Web
- React 19, TypeScript 5.7, Vite
- Tailwind CSS + shadcn/ui
- TanStack React Query, Zustand
- Amplify Gen 2

### Infrastructure
- Terraform 1.9+
- AWS (ECS Fargate, Lambda, RDS, S3, SQS, CloudFront)
- CloudWatch dashboards + X-Ray tracing

## 🛠️ Getting Started

### Prerequisites

- Java 17+
- Python 3.13+
- Node.js 20+
- Flutter 3.27+
- Terraform 1.9+
- AWS Account with Amplify Gen 2 configured

### Quick Start

Each workspace has its own README with detailed setup instructions:

```bash
# Backend
cd backend && ./gradlew bootRun

# Lambda
cd lambda && pip install -r requirements.txt

# Mobile
cd mobile && flutter pub get && flutter run

# Web
cd web && npm install && npm run dev

# Infrastructure
cd infrastructure && terraform init && terraform plan
```

## 📚 Documentation

See the [docs/](./docs/) directory for:
- Architecture documentation
- API specifications
- Deployment guides
- Amplify setup instructions
- Development workflows

## 🤝 Contributing

This project follows a monorepo structure with workspace-specific linting and build tools:

- **EditorConfig** for consistent coding styles
- **Prettier** for code formatting (web/docs)
- **Dependabot** for automated dependency updates
- **Renovate** for advanced dependency management

### CI/CD

GitHub Actions workflows handle:
- Linting and testing
- Docker builds
- Deployments (dev/prod)
- Load testing

## 📝 License

Copyright © 2025 RapidPhotoUpload Team

## 🔗 Links

- [Backend README](./backend/README.md)
- [Lambda README](./lambda/README.md)
- [Mobile README](./mobile/README.md)
- [Web README](./web/README.md)
- [Infrastructure README](./infrastructure/README.md)
- [Documentation](./docs/README.md)
