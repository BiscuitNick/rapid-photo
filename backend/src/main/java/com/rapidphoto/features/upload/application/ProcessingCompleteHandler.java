package com.rapidphoto.features.upload.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoLabel;
import com.rapidphoto.domain.PhotoVersion;
import com.rapidphoto.domain.PhotoVersionType;
import com.rapidphoto.features.upload.api.dto.ProcessingCompleteRequest;
import com.rapidphoto.repository.PhotoLabelRepository;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.PhotoVersionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Handler for processing Lambda completion callbacks.
 * Updates photo status, versions, and labels when image processing completes.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ProcessingCompleteHandler {

    private final PhotoRepository photoRepository;
    private final PhotoVersionRepository photoVersionRepository;
    private final PhotoLabelRepository photoLabelRepository;

    @Transactional
    public Mono<Void> handle(UUID photoId, ProcessingCompleteRequest request) {
        log.info("Handling processing complete for photo: {}, status: {}", photoId, request.getStatus());

        return photoRepository.findById(photoId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Photo not found: " + photoId)))
                .flatMap(photo -> {
                    // Update photo status and metadata
                    photo.setStatusEnum(request.getPhotoStatus());
                    photo.setProcessedAt(Instant.now());

                    if (request.getMetadata() != null) {
                        photo.setWidth(request.getMetadata().getWidth());
                        photo.setHeight(request.getMetadata().getHeight());
                    }

                    return photoRepository.save(photo);
                })
                .flatMap(photo -> {
                    // Save versions if provided
                    Mono<Void> saveVersions = Mono.empty();
                    if (request.getVersions() != null && !request.getVersions().isEmpty()) {
                        saveVersions = Flux.fromIterable(request.getVersions())
                                .flatMap(versionDto -> {
                                    PhotoVersion version = new PhotoVersion();
                                    version.setPhotoId(photoId);
                                    version.setVersionType(PhotoVersionType.valueOf(versionDto.getVersionType()));
                                    version.setS3Key(versionDto.getS3Key());
                                    version.setFileSize(versionDto.getFileSize());
                                    version.setWidth(versionDto.getWidth());
                                    version.setHeight(versionDto.getHeight());
                                    version.setMimeType(versionDto.getMimeType());
                                    version.setCreatedAt(Instant.now());

                                    return photoVersionRepository.save(version);
                                })
                                .then();
                    }

                    // Save labels if provided
                    Mono<Void> saveLabels = Mono.empty();
                    if (request.getLabels() != null && !request.getLabels().isEmpty()) {
                        saveLabels = Flux.fromIterable(request.getLabels())
                                .flatMap(labelDto -> {
                                    PhotoLabel label = new PhotoLabel();
                                    label.setPhotoId(photoId);
                                    label.setLabelName(labelDto.getLabelName());
                                    label.setConfidence(BigDecimal.valueOf(labelDto.getConfidence()));
                                    label.setCreatedAt(Instant.now());

                                    return photoLabelRepository.save(label);
                                })
                                .then();
                    }

                    return Mono.when(saveVersions, saveLabels);
                })
                .doOnSuccess(v -> log.info("Successfully updated photo {} with processing results", photoId))
                .then();
    }
}
