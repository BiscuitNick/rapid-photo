package com.rapidphoto.features.gallery.application;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.time.Duration;

/**
 * Service for generating presigned GET URLs for downloading photos.
 * URLs are cached to avoid regenerating them on every request.
 *
 * Spring Cache abstraction supports reactive types (Mono/Flux):
 * - The emitted object is cached
 * - Cache lookups return a Mono backed by CompletableFuture
 */
@Slf4j
@Service
public class S3DownloadUrlService {

    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket-name}")
    private String bucketName;

    @Value("${aws.s3.download-url-expiration:15}")
    private int downloadUrlExpirationMinutes;

    @Autowired
    public S3DownloadUrlService(S3Presigner s3Presigner) {
        this.s3Presigner = s3Presigner;
    }

    /**
     * Generate a presigned GET URL for downloading a file.
     * Results are cached by S3 key to avoid regenerating URLs.
     *
     * Spring's @Cacheable works with Mono<T>:
     * - On cache miss: Mono executes and emitted value is cached
     * - On cache hit: Cached value is wrapped in Mono (backed by CompletableFuture)
     *
     * @param s3Key S3 key of the file
     * @return Presigned download URL wrapped in Mono
     */
    @Cacheable(value = "presignedUrls", key = "#s3Key")
    public Mono<DownloadUrlResult> generatePresignedGetUrl(String s3Key) {
        log.info("🔄 CACHE MISS: Generating NEW presigned URL for s3Key: {}", s3Key);

        return Mono.fromSupplier(() -> {
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .build();

            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofMinutes(downloadUrlExpirationMinutes))
                    .getObjectRequest(getObjectRequest)
                    .build();

            PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
            String url = presignedRequest.url().toString();

            log.info("✅ Generated and cached presigned URL for s3Key: {} (expiry: {}min)",
                     s3Key, downloadUrlExpirationMinutes);

            return new DownloadUrlResult(url, downloadUrlExpirationMinutes);
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
