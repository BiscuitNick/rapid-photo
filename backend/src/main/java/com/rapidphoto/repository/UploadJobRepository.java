package com.rapidphoto.repository;

import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.domain.UploadJobStatus;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.UUID;

/**
 * Reactive repository for UploadJob aggregate.
 */
@Repository
public interface UploadJobRepository extends ReactiveCrudRepository<UploadJob, UUID> {

    /**
     * Find all upload jobs for a user ordered by creation time.
     */
    Flux<UploadJob> findByUserIdOrderByCreatedAtDesc(UUID userId);

    /**
     * Find upload jobs by user and status.
     */
    Flux<UploadJob> findByUserIdAndStatus(UUID userId, UploadJobStatus status);

    /**
     * Count active upload jobs for a user (INITIATED or UPLOADED status).
     */
    @Query("SELECT COUNT(*) FROM upload_jobs WHERE user_id = :userId AND status IN ('INITIATED', 'UPLOADED')")
    Mono<Long> countActiveUploadsByUserId(UUID userId);

    /**
     * Find expired upload jobs that are still in INITIATED status.
     */
    @Query("SELECT * FROM upload_jobs WHERE status = 'INITIATED' AND expires_at < :now")
    Flux<UploadJob> findExpiredInitiatedJobs(Instant now);

    /**
     * Find upload job by S3 key.
     */
    Mono<UploadJob> findByS3Key(String s3Key);

    /**
     * Delete upload jobs older than a certain date.
     */
    Mono<Void> deleteByCreatedAtBefore(Instant cutoffDate);

    /**
     * Custom save method with explicit ENUM casting for status field.
     * This is needed because R2DBC doesn't automatically cast String to PostgreSQL ENUM types.
     */
    @Query("INSERT INTO upload_jobs (id, user_id, s3_key, presigned_url, file_name, file_size, mime_type, status, expires_at, created_at) " +
           "VALUES (:id, :userId, :s3Key, :presignedUrl, :fileName, :fileSize, :mimeType, :status::upload_job_status, :expiresAt, :createdAt)")
    Mono<Void> saveWithEnumCast(UUID id, UUID userId, String s3Key, String presignedUrl,
                                String fileName, Long fileSize, String mimeType,
                                String status, Instant expiresAt, Instant createdAt);

    /**
     * Custom update method with explicit ENUM casting for status field.
     */
    @Query("UPDATE upload_jobs SET status = :status::upload_job_status, etag = :etag, confirmed_at = :confirmedAt " +
           "WHERE id = :id")
    Mono<Void> updateStatusWithEnumCast(UUID id, String status, String etag, Instant confirmedAt);
}
