package com.rapidphoto.features.gallery.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.time.Duration;

/**
 * Service for generating presigned GET URLs for downloading photos.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class S3DownloadUrlService {

    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket-name}")
    private String bucketName;

    @Value("${aws.s3.download-url-expiration:15}")
    private int downloadUrlExpirationMinutes;

    /**
     * Generate a presigned GET URL for downloading a file.
     *
     * @param s3Key S3 key of the file
     * @return Presigned download URL
     */
    public Mono<DownloadUrlResult> generatePresignedGetUrl(String s3Key) {
        return Mono.fromCallable(() -> {
            log.debug("Generating presigned download URL for s3Key: {}", s3Key);

            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .build();

            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofMinutes(downloadUrlExpirationMinutes))
                    .getObjectRequest(getObjectRequest)
                    .build();

            PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);

            log.info("Generated presigned download URL for s3Key: {}", s3Key);

            return new DownloadUrlResult(
                    presignedRequest.url().toString(),
                    downloadUrlExpirationMinutes
            );
        });
    }

    /**
     * Result containing presigned download URL details.
     */
    public record DownloadUrlResult(
            String downloadUrl,
            int expirationMinutes
    ) {}
}
