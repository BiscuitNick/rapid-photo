# GitHub Actions Workflows

CI/CD automation workflows for RapidPhotoUpload monorepo.

## Workflows

This directory will contain workflows for:
- **Backend CI/CD** - Build, test, Docker push, ECS deploy
- **Lambda CI/CD** - Test, package, Lambda publish
- **Mobile CI/CD** - Flutter test, build (iOS/Android)
- **Web CI/CD** - Build, test, deploy to CloudFront/S3
- **Infrastructure** - Terraform validate, plan, apply
- **Load Tests** - k6/JMeter performance validation

## Workflow Triggers
- Pull requests: lint, test
- Main branch: deploy to dev
- Tags: deploy to prod
