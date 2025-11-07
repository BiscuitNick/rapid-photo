package com.rapidphoto.repository;

import com.rapidphoto.domain.PhotoLabel;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Reactive repository for PhotoLabel entity.
 */
@Repository
public interface PhotoLabelRepository extends ReactiveCrudRepository<PhotoLabel, UUID> {

    /**
     * Find all labels for a photo.
     */
    Flux<PhotoLabel> findByPhotoId(UUID photoId);

    /**
     * Find labels for a photo with minimum confidence.
     */
    Flux<PhotoLabel> findByPhotoIdAndConfidenceGreaterThanEqualOrderByConfidenceDesc(
            UUID photoId, BigDecimal minConfidence);

    /**
     * Find photos with a specific label.
     */
    Flux<PhotoLabel> findByLabelName(String labelName);

    /**
     * Find photos with label and minimum confidence.
     */
    Flux<PhotoLabel> findByLabelNameAndConfidenceGreaterThanEqualOrderByConfidenceDesc(
            String labelName, BigDecimal minConfidence);

    /**
     * Find all distinct labels for photos belonging to a user.
     */
    @Query("SELECT DISTINCT pl.* FROM photo_labels pl " +
           "JOIN photos p ON pl.photo_id = p.id " +
           "WHERE p.user_id = :userId " +
           "ORDER BY pl.label_name")
    Flux<PhotoLabel> findDistinctLabelsByUserId(UUID userId);

    /**
     * Search photos by tag (label) for a specific user.
     */
    @Query("SELECT pl.* FROM photo_labels pl " +
           "JOIN photos p ON pl.photo_id = p.id " +
           "WHERE p.user_id = :userId AND pl.label_name ILIKE :labelPattern " +
           "AND pl.confidence >= :minConfidence " +
           "ORDER BY pl.confidence DESC")
    Flux<PhotoLabel> searchByUserIdAndLabelPattern(UUID userId, String labelPattern, BigDecimal minConfidence);

    /**
     * Find photos with multiple labels (tag intersection).
     * Returns photo IDs that have all specified labels.
     */
    @Query("SELECT pl.photo_id FROM photo_labels pl " +
           "JOIN photos p ON pl.photo_id = p.id " +
           "WHERE p.user_id = :userId AND pl.label_name = ANY(:labelNames) " +
           "GROUP BY pl.photo_id " +
           "HAVING COUNT(DISTINCT pl.label_name) = :labelCount")
    Flux<UUID> findPhotoIdsByUserIdAndAllLabels(UUID userId, String[] labelNames, int labelCount);

    /**
     * Count labels for a photo.
     */
    Mono<Long> countByPhotoId(UUID photoId);

    /**
     * Delete all labels for a photo (cascade handled by database).
     */
    Mono<Void> deleteByPhotoId(UUID photoId);
}
