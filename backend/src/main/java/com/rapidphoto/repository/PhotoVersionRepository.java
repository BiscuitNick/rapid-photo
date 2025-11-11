package com.rapidphoto.repository;

import com.rapidphoto.domain.PhotoVersion;
import com.rapidphoto.domain.PhotoVersionType;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.Collection;
import java.util.UUID;

/**
 * Reactive repository for PhotoVersion entity.
 */
@Repository
public interface PhotoVersionRepository extends ReactiveCrudRepository<PhotoVersion, UUID> {

    @Query("""
            INSERT INTO photo_versions (photo_id, version_type, s3_key, file_size, width, height, mime_type, created_at)
            VALUES (:photoId, :versionType::photo_version_type, :s3Key, :fileSize, :width, :height, :mimeType, :createdAt)
            RETURNING *
            """)
    Mono<PhotoVersion> insert(UUID photoId, PhotoVersionType versionType, String s3Key,
                              Long fileSize, Integer width, Integer height,
                              String mimeType, Instant createdAt);

    default Mono<PhotoVersion> saveWithEnumCast(PhotoVersion version) {
        Instant createdAt = version.getCreatedAt() != null ? version.getCreatedAt() : Instant.now();

        return insert(
                version.getPhotoId(),
                version.getVersionType(),
                version.getS3Key(),
                version.getFileSize(),
                version.getWidth(),
                version.getHeight(),
                version.getMimeType(),
                createdAt
        );
    }

    /**
     * Find all versions for a photo.
     */
    Flux<PhotoVersion> findByPhotoId(UUID photoId);

    /**
     * Find specific version type for a photo.
     */
    @Query("SELECT * FROM photo_versions WHERE photo_id = :photoId AND version_type = :#{#versionType.name()}::photo_version_type")
    Mono<PhotoVersion> findByPhotoIdAndVersionType(UUID photoId, PhotoVersionType versionType);

    /**
     * Find all thumbnails for multiple photos.
     */
    @Query("SELECT * FROM photo_versions WHERE photo_id IN (:photoIds) AND version_type = :#{#versionType.name()}::photo_version_type")
    Flux<PhotoVersion> findByPhotoIdInAndVersionType(Collection<UUID> photoIds, PhotoVersionType versionType);

    /**
     * Count versions for a photo.
     */
    Mono<Long> countByPhotoId(UUID photoId);

    /**
     * Delete all versions for a photo (cascade handled by database).
     */
    Mono<Void> deleteByPhotoId(UUID photoId);

    /**
     * Check if a specific version exists for a photo.
     */
    @Query("SELECT EXISTS (SELECT 1 FROM photo_versions WHERE photo_id = :photoId AND version_type = :#{#versionType.name()}::photo_version_type)")
    Mono<Boolean> existsByPhotoIdAndVersionType(UUID photoId, PhotoVersionType versionType);
}
