package com.rapidphoto.repository;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Reactive repository for Photo aggregate.
 */
@Repository
public interface PhotoRepository extends ReactiveCrudRepository<Photo, UUID> {

    /**
     * Find photos by user ID with pagination, ordered by creation time.
     */
    Flux<Photo> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    /**
     * Find all photos by user ID, ordered by creation time (no pagination).
     */
    Flux<Photo> findByUserIdOrderByCreatedAtDesc(UUID userId);

    /**
     * Find photos by user ID and status with pagination.
     */
    Flux<Photo> findByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, PhotoStatus status, Pageable pageable);

    /**
     * Find photo by ID and user ID (for authorization checks).
     */
    Mono<Photo> findByIdAndUserId(UUID id, UUID userId);

    /**
     * Count photos by user ID.
     */
    Mono<Long> countByUserId(UUID userId);

    /**
     * Count photos by user ID and status.
     */
    Mono<Long> countByUserIdAndStatus(UUID userId, PhotoStatus status);

    /**
     * Find photos by upload job ID.
     */
    Mono<Photo> findByUploadJobId(UUID uploadJobId);

    /**
     * Find photos pending processing (for monitoring).
     */
    Flux<Photo> findByStatusOrderByCreatedAtAsc(PhotoStatus status);

    /**
     * Find photos by user that have GPS coordinates.
     */
    @Query("SELECT * FROM photos WHERE user_id = :userId AND gps_latitude IS NOT NULL AND gps_longitude IS NOT NULL ORDER BY created_at DESC")
    Flux<Photo> findByUserIdWithGpsCoordinates(UUID userId, Pageable pageable);

    /**
     * Find photos taken within a date range.
     */
    @Query("SELECT * FROM photos WHERE user_id = :userId AND taken_at BETWEEN :startDate AND :endDate ORDER BY taken_at DESC")
    Flux<Photo> findByUserIdAndTakenAtBetween(UUID userId, Instant startDate, Instant endDate, Pageable pageable);

    /**
     * Delete photos by user ID (cascade handled by database).
     */
    Mono<Void> deleteByUserId(UUID userId);

    /**
     * Custom save method with explicit ENUM casting for status field.
     * This is needed because R2DBC doesn't automatically cast String to PostgreSQL ENUM types.
     */
    @Query("INSERT INTO photos (id, user_id, upload_job_id, original_s3_key, status, file_name, file_size, mime_type, " +
           "width, height, taken_at, camera_make, camera_model, gps_latitude, gps_longitude, created_at) " +
           "VALUES (:id, :userId, :uploadJobId, :originalS3Key, :status::photo_status, :fileName, :fileSize, :mimeType, " +
           ":width, :height, :takenAt, :cameraMake, :cameraModel, :gpsLatitude, :gpsLongitude, :createdAt)")
    Mono<Void> saveWithEnumCast(UUID id, UUID userId, UUID uploadJobId, String originalS3Key, String status,
                                String fileName, Long fileSize, String mimeType,
                                Integer width, Integer height, Instant takenAt,
                                String cameraMake, String cameraModel,
                                BigDecimal gpsLatitude, BigDecimal gpsLongitude, Instant createdAt);

    /**
     * Custom update method with explicit ENUM casting for status field.
     */
    @Query("UPDATE photos SET status = :status::photo_status WHERE id = :id")
    Mono<Void> updateStatusWithEnumCast(UUID id, String status);
}
