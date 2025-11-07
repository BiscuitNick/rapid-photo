package com.rapidphoto.features.upload.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;
import java.util.UUID;

/**
 * Service for generating S3 presigned URLs.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class S3PresignedUrlService {

    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket-name}")
    private String bucketName;

    @Value("${aws.s3.presigned-url-expiration:15}")
    private int presignedUrlExpirationMinutes;

    /**
     * Generate a presigned PUT URL for uploading a file.
     *
     * @param userId   User ID for the S3 key pattern
     * @param fileName File name
     * @param mimeType File MIME type
     * @return Presigned URL details
     */
    public Mono<PresignedUrlResult> generatePresignedPutUrl(UUID userId, String fileName, String mimeType) {
        return Mono.fromCallable(() -> {
            // Generate S3 key: originals/{userId}/{uuid}
            String fileId = UUID.randomUUID().toString();
            String s3Key = String.format("originals/%s/%s", userId, fileId);

            log.debug("Generating presigned URL for s3Key: {}, mimeType: {}", s3Key, mimeType);

            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .contentType(mimeType)
                    .build();

            PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofMinutes(presignedUrlExpirationMinutes))
                    .putObjectRequest(putObjectRequest)
                    .build();

            PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);

            log.info("Generated presigned URL for userId: {}, s3Key: {}", userId, s3Key);

            return new PresignedUrlResult(
                    presignedRequest.url().toString(),
                    s3Key,
                    presignedUrlExpirationMinutes
            );
        });
    }

    /**
     * Result containing presigned URL details.
     */
    public record PresignedUrlResult(
            String presignedUrl,
            String s3Key,
            int expirationMinutes
    ) {}
}
