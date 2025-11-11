# Lightsail Deployment Session Summary

**Date:** November 10, 2025  
**Task:** Deploy RapidPhotoUpload backend to AWS Lightsail (Task 11: AWS Infrastructure Cost Optimization)

## Overview

Successfully completed the deployment of the Spring Boot backend to AWS Lightsail Container Service, achieving 85-90% cost savings (~$25-30/month vs $200-300/month with ECS).

## What Was Accomplished

### 1. Infrastructure Configuration (Task 11.3)
- **Networking Architecture Decision**: Determined VPC peering NOT required for demo environment
  - Lightsail database publicly accessible with TLS enforcement
  - Lambda accesses database via public endpoint  
  - Container accesses S3/SQS via AWS public APIs
  - Documented production recommendations for VPC peering if needed

- **CloudWatch Monitoring**: Enhanced observability infrastructure
  - Added container-level alarms (CPU > 80%, Memory > 85%)
  - Created 4 new Lightsail dashboard widgets:
    * Container CPU & Memory utilization
    * Container Network I/O
    * Database CPU & Connections
    * Database Storage & Network throughput

- **Documentation**: Updated `infrastructure/README.md`
  - Platform selection guide (ECS vs Lightsail)
  - Cost comparison ($200-300/mo vs $25-30/mo)
  - Networking architecture diagrams
  - Communication paths

### 2. Spring Backend Configuration (Task 11.4)
- Created `lightsail` Spring Boot profile in `application.yml`:
  - TLS enforcement: `sslMode=require`
  - Optimized connection pools (5 initial, 10 max) for micro instance
  - Flyway migration configuration with SSL
  
- Enhanced AWS credential documentation in `AwsConfig.java`
  - Documented DefaultCredentialsProvider resolution order
  - Supports both IAM roles (ECS) and environment variables (Lightsail)

### 3. Deployment Documentation (Task 11.5)
- Created comprehensive `docs/lightsail-deployment.md`:
  - Step-by-step deployment procedures
  - Secrets management integration
  - Monitoring and troubleshooting guides
  - Rollback strategies
  - Performance tuning recommendations
  - Cost breakdown analysis

### 4. Actual Lightsail Deployment
Successfully deployed backend to Lightsail after resolving several issues:

**Environment:**
- Service: `rapid-photo-dev-backend`
- URL: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/
- Deployment Version: 4
- Container Image: `:rapid-photo-dev-backend.backend.2`
- Database: `ls-e858393db300b4cb330e16e757576d083a2dfd0b.ce7kmk6oqnug.us-east-1.rds.amazonaws.com`

## Issues Encountered and Resolutions

### Issue 1: Health Check Failures (HTTP 503)
**Problem:**  
- Lightsail health checks failing: "port 8080 is unhealthy"
- Application started successfully (87-101 second startup time)
- Health endpoint returning 503 from load balancer
- Deployments timing out before app became healthy

**Root Cause Analysis:**
1. `UserProvisioningWebFilter` running on ALL requests including `/actuator/health`
2. Filter added processing overhead for unauthenticated health checks
3. Health check configuration insufficient for slow startup:
   - `timeoutSeconds: 5`
   - `unhealthyThreshold: 3` (only ~90 seconds before failure)
   - Application takes 87-101 seconds to start
   - Health checks failed before app ready

**Resolution:**
1. **Code Fix**: Modified `UserProvisioningWebFilter.java` (backend/src/main/java/com/rapidphoto/security/UserProvisioningWebFilter.java:36-39)
   ```java
   // Skip filter for health/info endpoints - they don't need user provisioning
   if (path.equals("/actuator/health") || path.equals("/actuator/info")) {
       return chain.filter(exchange);
   }
   ```

2. **Health Check Configuration**: Updated `lightsail-deployment.json`:
   - `healthyThreshold: 2 → 3` (need 3 successful checks)
   - `unhealthyThreshold: 3 → 10` (allow 10 failed checks = ~5 min startup time)
   - Gives application sufficient time to start before marking unhealthy

3. **Deployment Process:**
   - Rebuilt JAR: `./gradlew clean bootJar`
   - Rebuilt Docker image: `docker build --platform linux/amd64`
   - Pushed to Lightsail: `:rapid-photo-dev-backend.backend.2`
   - Redeployed with updated health check config

**Result:** Health endpoint now returns HTTP 200 with `{"status":"UP"}`

### Issue 2: Docker Platform Mismatch
**Problem:** Initial Docker image built for wrong architecture  
**Solution:** Rebuilt with `--platform linux/amd64` flag

### Issue 3: lightsailctl Plugin Missing
**Problem:** AWS CLI couldn't push images to Lightsail  
**Solution:** User installed lightsailctl v1.0.7

## Current State

### ✅ Deployment Status
- **Service State:** RUNNING
- **Health Endpoint:** https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/actuator/health
- **Health Status:** `{"status":"UP"}` (HTTP 200)
- **Deployment Version:** 4 (current)

### Infrastructure Resources
**Lightsail (Active):**
- Container Service: micro power, 1 instance (~$10/month)
- PostgreSQL Database: micro_2_0 bundle (~$15/month)
- Static IP with TLS
- IAM user for S3/SQS access

**Shared Resources:**
- S3 Bucket: `rapid-photo-dev-photos-971422717446`
- SQS Queue: `rapid-photo-dev-image-processing`
- Lambda: Image processing (ARM64)
- CloudWatch: Dashboards, alarms, metrics
- Secrets Manager: Database and IAM credentials

### Configuration Files Modified

1. **backend/src/main/java/com/rapidphoto/security/UserProvisioningWebFilter.java**
   - Added health endpoint bypass logic

2. **backend/src/main/resources/application.yml**
   - Added `lightsail` Spring profile with TLS and optimized pools

3. **backend/src/main/java/com/rapidphoto/config/AwsConfig.java**
   - Enhanced credential resolution documentation

4. **infrastructure/modules/lightsail_compute/main.tf**
   - Added CloudWatch alarms for container monitoring

5. **infrastructure/modules/observability/main.tf**
   - Added 4 Lightsail dashboard widget groups

6. **infrastructure/README.md**
   - Added platform selection guide and networking architecture

7. **infrastructure/lightsail-deployment.json**
   - Updated image tag to `.backend.2`
   - Updated health check thresholds

8. **docs/lightsail-deployment.md** (NEW)
   - Complete deployment runbook

## Files to Stage for Commit

```bash
# Modified files
backend/src/main/java/com/rapidphoto/security/UserProvisioningWebFilter.java
backend/src/main/resources/application.yml
backend/src/main/java/com/rapidphoto/config/AwsConfig.java
infrastructure/modules/lightsail_compute/main.tf
infrastructure/modules/observability/main.tf
infrastructure/README.md

# New files
docs/lightsail-deployment.md
docs/lightsail-deployment-session-summary.md

# Do NOT commit (contains secrets)
infrastructure/lightsail-deployment.json
infrastructure/lightsail-deployment.json.bak
```

## Cost Analysis

### Before (ECS Platform)
- ECS Fargate (2-10 tasks): ~$100-150/month
- Multi-AZ RDS (db.t4g.medium): ~$80-100/month
- NAT Gateway: ~$30-40/month
- ALB: ~$20/month
- **Total:** ~$200-300/month

### After (Lightsail Platform)
- Lightsail Container (micro): ~$10/month
- Lightsail PostgreSQL (micro): ~$15/month
- Static IP: Free
- Lambda: ~$5/month (usage-based)
- S3/SQS: ~$1-2/month (usage-based)
- **Total:** ~$25-30/month

**Savings:** 85-90% cost reduction

## Next Steps

### Immediate Actions

1. **Commit Changes**
   ```bash
   cd /Users/nickkenkel/code/gauntlet/rapid-photo
   git add backend/src/main/java/com/rapidphoto/security/UserProvisioningWebFilter.java
   git add backend/src/main/resources/application.yml
   git add backend/src/main/java/com/rapidphoto/config/AwsConfig.java
   git add infrastructure/modules/lightsail_compute/main.tf
   git add infrastructure/modules/observability/main.tf
   git add infrastructure/README.md
   git add docs/lightsail-deployment.md
   git add docs/lightsail-deployment-session-summary.md
   git commit -m "Complete Lightsail deployment (Task 11)

- Add UserProvisioningWebFilter bypass for health endpoints
- Create lightsail Spring profile with TLS and optimized pools
- Add Lightsail CloudWatch alarms and dashboard widgets
- Document platform selection and networking architecture
- Create comprehensive Lightsail deployment runbook
- Successfully deploy backend to Lightsail (85-90% cost savings)

Fixes health check failures by:
1. Bypassing UserProvisioningWebFilter for /actuator/health
2. Increasing unhealthyThreshold to allow for ~100s startup time

Deployment verified: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/actuator/health"
   ```

2. **Update .gitignore**
   Ensure lightsail-deployment.json is NOT committed (contains secrets):
   ```bash
   echo "infrastructure/lightsail-deployment.json" >> .gitignore
   echo "infrastructure/*.bak" >> .gitignore
   ```

3. **Test API Endpoints**
   Verify all API endpoints work through Lightsail:
   ```bash
   # Health check (already verified)
   curl https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/actuator/health
   
   # Info endpoint
   curl https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/actuator/info
   
   # Test authenticated endpoint (requires valid JWT)
   curl -H "Authorization: Bearer <token>" https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/api/v1/photos
   ```

4. **Update Frontend Configuration**
   Update the mobile/web frontend to point to Lightsail backend URL:
   ```
   https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com
   ```

### Monitoring and Validation

1. **CloudWatch Dashboard**
   - Access: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=rapid-photo-dev-dashboard
   - Monitor: CPU, Memory, Network, Database connections
   - Verify: Lightsail widgets showing metrics

2. **CloudWatch Alarms**
   - Verify alarms created:
     * `rapid-photo-dev-lightsail-container-cpu` (>80%)
     * `rapid-photo-dev-lightsail-container-memory` (>85%)
     * Database CPU, connections, storage alarms

3. **Container Logs**
   ```bash
   aws lightsail get-container-log \
     --service-name rapid-photo-dev-backend \
     --container-name backend \
     --region us-east-1
   ```

### Production Considerations

Before deploying to production:

1. **Security Hardening**
   - Implement VPC peering for private communication
   - Restrict database public access
   - Use AWS PrivateLink for S3/SQS
   - Rotate secrets stored in Secrets Manager
   - Change LAMBDA_SECRET from default value

2. **Performance Tuning**
   - Monitor startup time and consider lazy initialization
   - Adjust connection pool sizes based on load
   - Consider upgrading to `small` or `medium` container power
   - Scale container instances (1-3 for micro)

3. **High Availability**
   - Multi-container deployment (scale: 2-3)
   - Database backups and retention policy
   - Disaster recovery testing
   - Health check monitoring and alerting

4. **Cognito Configuration**
   - Update COGNITO_ISSUER_URI for production user pool
   - Update COGNITO_JWK_SET_URI for production
   - Configure proper CORS origins

## Task Master Status

**Task 11: AWS Infrastructure Cost Optimization via Lightsail Migration**

- ✅ 11.1: Create Terraform modules for Lightsail (lightsail_compute, lightsail_database)
- ✅ 11.2: Implement platform toggle (backend_platform variable)
- ✅ 11.3: Configure networking and observability for Lightsail
- ✅ 11.4: Update Spring backend configuration (lightsail profile)
- ✅ 11.5: Create deployment documentation and successfully deploy

**Status:** COMPLETE

## Technical Lessons Learned

1. **Health Check Configuration is Critical**
   - Always account for application startup time in health check thresholds
   - For Spring Boot apps with Flyway migrations, allow 90-120 second startup
   - Use `unhealthyThreshold` to give sufficient time before marking deployment failed

2. **Filter Ordering Matters**
   - `@Order(0)` filters run before security filters
   - Public endpoints should bypass custom filters for performance
   - Health endpoints are frequently called - optimize their path

3. **Lightsail Limitations**
   - No built-in deployment rollback (must redeploy previous image)
   - Logs may have delay before appearing
   - Health check configuration less flexible than ALB

4. **Docker Multi-Platform Builds**
   - Always use `--platform linux/amd64` for Lightsail/ECS deployments
   - M1/M2 Macs build arm64 by default

## References

- Lightsail Deployment Guide: `docs/lightsail-deployment.md`
- Infrastructure README: `infrastructure/README.md`
- Terraform Platform Toggle: `infrastructure/main.tf`
- Spring Lightsail Profile: `backend/src/main/resources/application.yml`
- UserProvisioningWebFilter: `backend/src/main/java/com/rapidphoto/security/UserProvisioningWebFilter.java`

---

**End of Session Summary**  
*All Task 11 subtasks completed successfully. Backend running on Lightsail with 85-90% cost savings.*
