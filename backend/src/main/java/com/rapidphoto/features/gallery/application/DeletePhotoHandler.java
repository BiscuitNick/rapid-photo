package com.rapidphoto.features.gallery.application;

import com.rapidphoto.repository.PhotoLabelRepository;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.PhotoVersionRepository;
import io.micrometer.observation.annotation.Observed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Command handler for deleting photos.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeletePhotoHandler {

    private final PhotoRepository photoRepository;
    private final PhotoVersionRepository photoVersionRepository;
    private final PhotoLabelRepository photoLabelRepository;

    /**
     * Delete a photo and all its related data.
     */
    @Observed(name = "gallery.delete.photo")
    public Mono<Void> deletePhoto(UUID photoId, UUID userId) {
        log.info("Deleting photo: {}, userId: {}", photoId, userId);

        return photoRepository.findByIdAndUserId(photoId, userId)
                .switchIfEmpty(Mono.error(new PhotoNotFoundException("Photo not found: " + photoId)))
                .flatMap(photo -> {
                    // Delete related data first (cascade should handle this, but explicit for clarity)
                    return photoVersionRepository.deleteByPhotoId(photoId)
                            .then(photoLabelRepository.deleteByPhotoId(photoId))
                            .then(photoRepository.delete(photo));
                })
                .doOnSuccess(v -> log.info("Successfully deleted photo: {}", photoId))
                .doOnError(error -> log.error("Failed to delete photo: {}", photoId, error));
    }

    /**
     * Exception thrown when photo is not found or user is not authorized.
     */
    public static class PhotoNotFoundException extends RuntimeException {
        public PhotoNotFoundException(String message) {
            super(message);
        }
    }
}
