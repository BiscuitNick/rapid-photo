package com.rapidphoto.features.gallery.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.features.gallery.api.dto.PhotoResponse;
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
 * Query handler for getting detailed photo information.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GetPhotoDetailHandler {

    private final PhotoRepository photoRepository;
    private final PhotoVersionRepository photoVersionRepository;
    private final PhotoLabelRepository photoLabelRepository;
    private final PhotoReadModelMapper mapper;

    /**
     * Get detailed photo information.
     */
    @Observed(name = "gallery.query.photo-detail")
    public Mono<PhotoResponse> getPhotoDetail(UUID photoId, UUID userId) {
        log.debug("Fetching photo detail for photoId: {}, userId: {}", photoId, userId);

        return photoRepository.findByIdAndUserId(photoId, userId)
                .switchIfEmpty(Mono.error(new PhotoNotFoundException("Photo not found: " + photoId)))
                .flatMap(photo -> enrichWithVersionsAndLabels(photo))
                .doOnSuccess(response -> log.info("Returned photo detail for photoId: {}", photoId))
                .doOnError(error -> log.error("Failed to fetch photo detail for photoId: {}", photoId, error));
    }

    private Mono<PhotoResponse> enrichWithVersionsAndLabels(Photo photo) {
        return Mono.zip(
                photoVersionRepository.findByPhotoId(photo.getId()).collectList(),
                photoLabelRepository.findByPhotoId(photo.getId()).collectList()
        ).flatMap(tuple -> mapper.toPhotoResponse(photo, tuple.getT1(), tuple.getT2()));
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
