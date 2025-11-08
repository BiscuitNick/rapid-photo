# Backend Workspace

Spring Boot 3.5.3 WebFlux backend service for RapidPhotoUpload.

## Technology Stack
- Java 17+
- Spring Boot 3.5.3 (WebFlux)
- R2DBC for reactive database access
- PostgreSQL 17.6
- Flyway for database migrations
- AWS Cognito (Amplify) for authentication
- Spring Cloud AWS for S3/SQS integration

## Structure
- `src/main/java/` - Application source code
- `src/main/resources/` - Configuration files
- `src/test/java/` - Test source code

## Getting Started
Prerequisites and setup instructions will be added during implementation.

### Running with Local Environment Variables

The backend expects several AWS/Cognito/Postgres variables. Copy `backend/.env.example` to `backend/.env` and adjust as needed.  
Running `./gradlew bootRun` will now automatically load any key/value pairs from that `.env` file, so you no longer need to prefix the command with lengthy `KEY=value` sequences. If you prefer, you can still export the variables manually (e.g. via `source .env`) and the application will pick them up in the same way.
