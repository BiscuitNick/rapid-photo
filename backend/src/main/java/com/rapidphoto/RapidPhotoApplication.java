package com.rapidphoto;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main application class for RapidPhotoUpload backend service.
 *
 * This Spring Boot application provides:
 * - Reactive WebFlux API endpoints
 * - R2DBC database access with PostgreSQL 17.6
 * - AWS Cognito (Amplify) authentication
 * - S3 presigned URL generation
 * - SQS message publishing
 * - CloudWatch metrics and X-Ray tracing
 */
@SpringBootApplication
public class RapidPhotoApplication {

    public static void main(String[] args) {
        SpringApplication.run(RapidPhotoApplication.class, args);
    }

}
