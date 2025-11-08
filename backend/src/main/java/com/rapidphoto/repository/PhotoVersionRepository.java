package com.rapidphoto.repository;

import com.rapidphoto.domain.PhotoVersion;
import com.rapidphoto.domain.PhotoVersionType;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Collection;
import java.util.UUID;

/**
 * Reactive repository for PhotoVersion entity.
 */
@Repository
public interface PhotoVersionRepository extends ReactiveCrudRepository<PhotoVersion, UUID> {

    /**
     * Find all versions for a photo.
     */
    Flux<PhotoVersion> findByPhotoId(UUID photoId);

    /**
     * Find specific version type for a photo.
     */
    Mono<PhotoVersion> findByPhotoIdAndVersionType(UUID photoId, PhotoVersionType versionType);

    /**
     * Find all thumbnails for multiple photos.
     */
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
    Mono<Boolean> existsByPhotoIdAndVersionType(UUID photoId, PhotoVersionType versionType);
}
