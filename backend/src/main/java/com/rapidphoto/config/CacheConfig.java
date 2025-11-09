package com.rapidphoto.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * Configuration for caching with Caffeine.
 *
 * Caches presigned S3 URLs to avoid regenerating them on every request.
 * URLs are cached for slightly less time than their expiration to ensure validity.
 */
@Slf4j
@Configuration
@EnableCaching
public class CacheConfig {

    @Value("${aws.s3.download-url-expiration:15}")
    private int downloadUrlExpirationMinutes;

    /**
     * Configure Caffeine cache manager for presigned URLs.
     *
     * Cache TTL is set to 80% of URL expiration time to ensure URLs
     * are always valid when served from cache.
     */
    @Bean
    public CacheManager cacheManager() {
        // Calculate cache expiration as 80% of presigned URL expiration
        // This ensures URLs are refreshed before they expire
        long cacheExpirationMinutes = (long) (downloadUrlExpirationMinutes * 0.8);

        log.info("Configuring cache with {} minute TTL (presigned URLs expire in {} minutes)",
                cacheExpirationMinutes, downloadUrlExpirationMinutes);

        CaffeineCacheManager cacheManager = new CaffeineCacheManager("presignedUrls");
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .expireAfterWrite(cacheExpirationMinutes, TimeUnit.MINUTES)
                .maximumSize(10000) // Cache up to 10k URLs (adjust based on needs)
                .recordStats()); // Enable statistics for monitoring

        return cacheManager;
    }
}
