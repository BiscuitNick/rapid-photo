# Lightsail Monitoring Guide

## CloudWatch Metrics

### Checking Container Service Metrics

```bash
# Get container service metrics
aws lightsail get-container-service-metric-data \
  --service-name rapid-photo-dev-backend \
  --region us-east-1 \
  --metric-name CPUUtilization \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Check memory utilization
aws lightsail get-container-service-metric-data \
  --service-name rapid-photo-dev-backend \
  --region us-east-1 \
  --metric-name MemoryUtilization \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Viewing Container Logs

```bash
# Get recent logs
aws lightsail get-container-log \
  --service-name rapid-photo-dev-backend \
  --container-name backend \
  --region us-east-1

# Watch logs in real-time (refresh every 10 seconds)
watch -n 10 "aws lightsail get-container-log \
  --service-name rapid-photo-dev-backend \
  --container-name backend \
  --region us-east-1 | jq '.logEvents[-20:] | .[] | {timestamp: .createdAt, message: .message}'"
```

### CloudWatch Log Groups

The following log groups are available:
- `/aws/rds/instance/rapid-photo-dev-db/postgresql` - Database logs
- `/aws/lambda/rapid-photo-dev-image-processor` - Lambda processor logs
- Lightsail logs are accessed via `get-container-log` command

### Application Metrics

The Spring Boot application exports metrics to CloudWatch with the namespace `RapidPhoto`.

```bash
# List available metrics
aws cloudwatch list-metrics \
  --namespace RapidPhoto \
  --region us-east-1

# Get specific metric
aws cloudwatch get-metric-statistics \
  --namespace RapidPhoto \
  --metric-name http.server.requests \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average Sum \
  --region us-east-1
```

## Health Checks

### Manual Health Check

```bash
# Health endpoint
curl https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/actuator/health

# Expected response: {"status":"UP"}
```

### Automated Monitoring Script

```bash
# Run the test script
./test-lightsail-api.sh
```

## Key Metrics to Monitor

### 1. Container Health
- **CPUUtilization**: Should be < 80% average
- **MemoryUtilization**: Should be < 80% average
- **Health Check Status**: Should be passing

### 2. Database Metrics
- **Connection count**: Monitor via RDS dashboard
- **Query performance**: Check slow query logs

### 3. Application Metrics (via actuator/metrics)
- **Request count**: Total requests processed
- **Error rate**: 4xx and 5xx responses
- **Response time**: Average request duration

### 4. Lambda Processing
- **Invocation count**: Number of images processed
- **Error rate**: Failed processing attempts
- **Duration**: Processing time per image

## Alerting (Optional)

Set up CloudWatch alarms:

```bash
# CPU utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rapid-photo-dev-high-cpu \
  --alarm-description "Alert when CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/Lightsail \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --region us-east-1

# Memory utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rapid-photo-dev-high-memory \
  --alarm-description "Alert when Memory > 80%" \
  --metric-name MemoryUtilization \
  --namespace AWS/Lightsail \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --region us-east-1
```

## Troubleshooting

### If health checks are failing:

1. Check container logs:
   ```bash
   aws lightsail get-container-log \
     --service-name rapid-photo-dev-backend \
     --container-name backend \
     --region us-east-1 | jq '.logEvents[-50:]'
   ```

2. Check database connectivity:
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier rapid-photo-dev-db \
     --region us-east-1 | jq '.DBInstances[0].DBInstanceStatus'
   ```

3. Verify environment variables are set correctly:
   ```bash
   aws lightsail get-container-services \
     --service-name rapid-photo-dev-backend \
     --region us-east-1 | jq '.containerServices[0].currentDeployment.containers.backend.environment'
   ```

### If API requests are failing:

1. Check CORS configuration in SecurityConfig.java
2. Verify JWT token is valid (check Cognito user pool)
3. Check application logs for authentication errors

## Daily Monitoring Checklist

- [ ] Check health endpoint status
- [ ] Review error logs for exceptions
- [ ] Monitor CPU/Memory utilization
- [ ] Verify Lambda processing queue (SQS) is empty
- [ ] Check database connection pool metrics

## URLs

- **Backend API**: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com
- **Health Check**: https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com/actuator/health
- **AWS Console**: https://lightsail.aws.amazon.com/ls/webapp/us-east-1/container-services/rapid-photo-dev-backend
