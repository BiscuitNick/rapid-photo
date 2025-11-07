package com.rapidphoto.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.awspring.cloud.sqs.config.SqsMessageListenerContainerFactory;
import io.awspring.cloud.sqs.operations.SqsTemplate;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3AsyncClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.sqs.SqsAsyncClient;

import java.net.URI;

/**
 * AWS configuration for S3 and SQS services.
 */
@Slf4j
@Configuration
public class AwsConfig {

    @Value("${aws.region:us-east-1}")
    private String awsRegion;

    @Value("${aws.endpoint:#{null}}")
    private String awsEndpoint;

    /**
     * S3 Presigner for generating presigned URLs.
     */
    @Bean
    public S3Presigner s3Presigner() {
        log.info("Initializing S3Presigner with region: {}", awsRegion);

        S3Presigner.Builder builder = S3Presigner.builder()
                .region(Region.of(awsRegion))
                .credentialsProvider(DefaultCredentialsProvider.create());

        // For local development with LocalStack
        if (awsEndpoint != null && !awsEndpoint.isEmpty()) {
            log.info("Using custom AWS endpoint: {}", awsEndpoint);
            builder.endpointOverride(URI.create(awsEndpoint));
        }

        return builder.build();
    }

    /**
     * S3 synchronous client (used for some operations).
     */
    @Bean
    public S3Client s3Client() {
        log.info("Initializing S3Client with region: {}", awsRegion);

        software.amazon.awssdk.services.s3.S3ClientBuilder builder = S3Client.builder()
                .region(Region.of(awsRegion))
                .credentialsProvider(DefaultCredentialsProvider.create());

        if (awsEndpoint != null && !awsEndpoint.isEmpty()) {
            builder.endpointOverride(URI.create(awsEndpoint));
        }

        return builder.build();
    }

    /**
     * S3 async client for reactive operations.
     */
    @Bean
    public S3AsyncClient s3AsyncClient() {
        log.info("Initializing S3AsyncClient with region: {}", awsRegion);

        software.amazon.awssdk.services.s3.S3AsyncClientBuilder builder = S3AsyncClient.builder()
                .region(Region.of(awsRegion))
                .credentialsProvider(DefaultCredentialsProvider.create());

        if (awsEndpoint != null && !awsEndpoint.isEmpty()) {
            builder.endpointOverride(URI.create(awsEndpoint));
        }

        return builder.build();
    }

    /**
     * SQS async client for reactive messaging.
     */
    @Bean
    public SqsAsyncClient sqsAsyncClient() {
        log.info("Initializing SqsAsyncClient with region: {}", awsRegion);

        software.amazon.awssdk.services.sqs.SqsAsyncClientBuilder builder = SqsAsyncClient.builder()
                .region(Region.of(awsRegion))
                .credentialsProvider(DefaultCredentialsProvider.create());

        if (awsEndpoint != null && !awsEndpoint.isEmpty()) {
            builder.endpointOverride(URI.create(awsEndpoint));
        }

        return builder.build();
    }

    /**
     * SQS template for sending messages.
     */
    @Bean
    public SqsTemplate sqsTemplate(SqsAsyncClient sqsAsyncClient) {
        return SqsTemplate.newTemplate(sqsAsyncClient);
    }

    /**
     * ObjectMapper for JSON serialization.
     */
    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper()
                .findAndRegisterModules(); // Registers JavaTimeModule for Instant, etc.
    }
}
