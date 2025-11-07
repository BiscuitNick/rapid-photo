package com.rapidphoto.features.gallery.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoVersion;
import com.rapidphoto.domain.PhotoVersionType;
import com.rapidphoto.features.gallery.api.dto.DownloadUrlResponse;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.PhotoVersionRepository;
import io.micrometer.observation.annotation.Observed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Query handler for generating download URLs for photos.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DownloadPhotoHandler {

    private final PhotoRepository photoRepository;
    private final PhotoVersionRepository photoVersionRepository;
    private final S3DownloadUrlService s3DownloadUrlService;
    private final PhotoReadModelMapper mapper;

    /**
     * Generate download URL for original photo.
     */
    @Observed(name = "gallery.download.original")
    public Mono<DownloadUrlResponse> getOriginalDownloadUrl(UUID photoId, UUID userId) {
        log.debug("Generating original download URL for photoId: {}, userId: {}", photoId, userId);

        return photoRepository.findByIdAndUserId(photoId, userId)
                .switchIfEmpty(Mono.error(new PhotoNotFoundException("Photo not found: " + photoId)))
                .flatMap(photo -> s3DownloadUrlService.generatePresignedGetUrl(photo.getOriginalS3Key())
                        .map(result -> mapper.toDownloadUrlResponse(
                                result,
                                photo.getFileName(),
                                photo.getFileSize())))
                .doOnSuccess(response -> log.info("Generated original download URL for photoId: {}", photoId));
    }

    /**
     * Generate download URL for a specific photo version.
     */
    @Observed(name = "gallery.download.version")
    public Mono<DownloadUrlResponse> getVersionDownloadUrl(UUID photoId,
                                                             UUID userId,
                                                             PhotoVersionType versionType) {
        log.debug("Generating {} download URL for photoId: {}, userId: {}",
                versionType, photoId, userId);

        return photoRepository.findByIdAndUserId(photoId, userId)
                .switchIfEmpty(Mono.error(new PhotoNotFoundException("Photo not found: " + photoId)))
                .flatMap(photo -> photoVersionRepository.findByPhotoIdAndVersionType(photoId, versionType)
                        .switchIfEmpty(Mono.error(new VersionNotFoundException(
                                "Version " + versionType + " not found for photo: " + photoId)))
                        .flatMap(version -> s3DownloadUrlService.generatePresignedGetUrl(version.getS3Key())
                                .map(result -> mapper.toDownloadUrlResponse(
                                        result,
                                        generateVersionFileName(photo.getFileName(), version),
                                        version.getFileSize()))))
                .doOnSuccess(response -> log.info("Generated {} download URL for photoId: {}",
                        versionType, photoId));
    }

    private String generateVersionFileName(String originalFileName, PhotoVersion version) {
        String nameWithoutExtension = originalFileName.contains(".")
                ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
                : originalFileName;

        String extension = version.getMimeType().contains("webp") ? "webp" :
                           version.getMimeType().contains("jpeg") ? "jpg" : "png";

        return String.format("%s_%s.%s",
                nameWithoutExtension,
                version.getVersionType().name().toLowerCase(),
                extension);
    }

    /**
     * Exception thrown when photo is not found.
     */
    public static class PhotoNotFoundException extends RuntimeException {
        public PhotoNotFoundException(String message) {
            super(message);
        }
    }

    /**
     * Exception thrown when version is not found.
     */
    public static class VersionNotFoundException extends RuntimeException {
        public VersionNotFoundException(String message) {
            super(message);
        }
    }
}
