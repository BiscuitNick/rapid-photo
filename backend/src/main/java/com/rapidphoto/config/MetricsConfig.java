package com.rapidphoto.config;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for application-specific custom metrics.
 * Defines timers and counters for key business operations.
 */
@Configuration
public class MetricsConfig {

    /**
     * Timer for presigned URL generation operations.
     * Tracks duration of upload initiation requests.
     */
    @Bean
    public Timer uploadPresignedUrlTimer(MeterRegistry registry) {
        return Timer.builder("upload.presigned.url")
                .description("Time taken to generate presigned upload URLs")
                .tag("operation", "generate")
                .register(registry);
    }

    /**
     * Timer for upload confirmation operations.
     * Tracks duration of upload confirmation requests.
     */
    @Bean
    public Timer uploadConfirmTimer(MeterRegistry registry) {
        return Timer.builder("upload.confirm")
                .description("Time taken to confirm photo uploads")
                .tag("operation", "confirm")
                .register(registry);
    }

    /**
     * Timer for gallery query operations.
     * Tracks duration of photo listing and search requests.
     */
    @Bean
    public Timer galleryQueryTimer(MeterRegistry registry) {
        return Timer.builder("gallery.query.duration")
                .description("Time taken to query photo gallery")
                .tag("operation", "query")
                .register(registry);
    }

    /**
     * Counter for successful photo uploads.
     */
    @Bean
    public Counter photoUploadSuccessCounter(MeterRegistry registry) {
        return Counter.builder("photo.upload.success")
                .description("Number of successful photo uploads")
                .tag("status", "success")
                .register(registry);
    }

    /**
     * Counter for failed photo uploads.
     */
    @Bean
    public Counter photoUploadFailureCounter(MeterRegistry registry) {
        return Counter.builder("photo.upload.failure")
                .description("Number of failed photo uploads")
                .tag("status", "failure")
                .register(registry);
    }

    /**
     * Counter for photo processing events.
     */
    @Bean
    public Counter photoProcessingCounter(MeterRegistry registry) {
        return Counter.builder("photo.processing")
                .description("Number of photo processing events")
                .tag("operation", "process")
                .register(registry);
    }

    /**
     * Timer for S3 operations.
     */
    @Bean
    public Timer s3OperationTimer(MeterRegistry registry) {
        return Timer.builder("aws.s3.operation")
                .description("Time taken for S3 operations")
                .tag("service", "s3")
                .register(registry);
    }

    /**
     * Timer for database operations.
     */
    @Bean
    public Timer databaseOperationTimer(MeterRegistry registry) {
        return Timer.builder("database.operation")
                .description("Time taken for database operations")
                .tag("database", "postgresql")
                .register(registry);
    }

    /**
     * Counter for authentication attempts.
     */
    @Bean
    public Counter authenticationAttemptCounter(MeterRegistry registry) {
        return Counter.builder("authentication.attempt")
                .description("Number of authentication attempts")
                .tag("type", "jwt")
                .register(registry);
    }

    /**
     * Counter for authentication failures.
     */
    @Bean
    public Counter authenticationFailureCounter(MeterRegistry registry) {
        return Counter.builder("authentication.failure")
                .description("Number of authentication failures")
                .tag("type", "jwt")
                .register(registry);
    }
}
