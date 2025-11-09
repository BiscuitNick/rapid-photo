package com.rapidphoto.features.gallery.application;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.context.annotation.Lazy;
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
 */
@Slf4j
@Service
public class S3DownloadUrlService {

    private final S3Presigner s3Presigner;

    // Self-reference to enable Spring AOP proxy for @Cacheable to work
    private S3DownloadUrlService self;

    @Value("${aws.s3.bucket-name}")
    private String bucketName;

    @Value("${aws.s3.download-url-expiration:15}")
    private int downloadUrlExpirationMinutes;

    @Autowired
    public S3DownloadUrlService(S3Presigner s3Presigner) {
        this.s3Presigner = s3Presigner;
    }

    /**
     * Inject self-reference to get Spring proxy.
     * This allows @Cacheable to work when called from within the same class.
     */
    @Autowired
    public void setSelf(@Lazy S3DownloadUrlService self) {
        this.self = self;
    }

    /**
     * Generate a presigned GET URL for downloading a file.
     * Results are cached by S3 key to avoid regenerating URLs.
     *
     * @param s3Key S3 key of the file
     * @return Presigned download URL
     */
    public Mono<DownloadUrlResult> generatePresignedGetUrl(String s3Key) {
        log.debug("📞 Request for presigned URL: {}", s3Key);
        // Use self-reference to invoke through Spring proxy, enabling @Cacheable
        return Mono.fromCallable(() -> {
            DownloadUrlResult result = self.generatePresignedGetUrlCached(s3Key);
            log.debug("📦 Returning URL for {}: {}...", s3Key,
                     result.downloadUrl().substring(0, Math.min(80, result.downloadUrl().length())));
            return result;
        });
    }

    /**
     * Internal cached method for generating presigned URLs.
     * Cache key is the S3 key, ensuring same URL is returned for same file.
     * Must be public for Spring AOP proxy to work properly.
     */
    @Cacheable(value = "presignedUrls", key = "#s3Key")
    public DownloadUrlResult generatePresignedGetUrlCached(String s3Key) {
        log.info("🔄 CACHE MISS: Generating NEW presigned URL for s3Key: {}", s3Key);

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

        log.info("✅ Generated and cached presigned URL for s3Key: {} (URL: {}...)",
                 s3Key, url.substring(0, Math.min(100, url.length())));

        return new DownloadUrlResult(url, downloadUrlExpirationMinutes);
    }

    /**
     * Result containing presigned download URL details.
     */
    public record DownloadUrlResult(
            String downloadUrl,
            int expirationMinutes
    ) {}
}
