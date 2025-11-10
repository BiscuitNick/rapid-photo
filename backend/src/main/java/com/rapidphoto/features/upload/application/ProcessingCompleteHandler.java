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
        logSchemaExample(photoId);
        logPayload(photoId, request);

        return photoRepository.findById(photoId)
                .flatMap(photo -> {
                    Instant now = Instant.now();
                    Integer newWidth = request.getMetadata() != null && request.getMetadata().getWidth() != null
                            ? request.getMetadata().getWidth()
                            : photo.getWidth();
                    Integer newHeight = request.getMetadata() != null && request.getMetadata().getHeight() != null
                            ? request.getMetadata().getHeight()
                            : photo.getHeight();

                    Mono<Void> updatePhoto = photoRepository.updateProcessingResults(
                            photoId,
                            request.getPhotoStatus().name(),
                            newWidth,
                            newHeight,
                            now,
                            now
                    );

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
                                    version.setCreatedAt(now);

                                    return photoVersionRepository.saveWithEnumCast(version);
                                })
                                .then();
                    }

                    Mono<Void> saveLabels = Mono.empty();
                    if (request.getLabels() != null && !request.getLabels().isEmpty()) {
                        saveLabels = Flux.fromIterable(request.getLabels())
                                .flatMap(labelDto -> {
                                    PhotoLabel label = new PhotoLabel();
                                    label.setPhotoId(photoId);
                                    label.setLabelName(labelDto.getLabelName());
                                    label.setConfidence(BigDecimal.valueOf(labelDto.getConfidence()));
                                    label.setCreatedAt(now);

                                    return photoLabelRepository.save(label);
                                })
                                .then();
                    }

                    return updatePhoto.then(Mono.when(saveVersions, saveLabels)
                            .doOnSuccess(v -> log.info("Successfully updated photo {} with processing results", photoId)));
                })
                .switchIfEmpty(Mono.fromRunnable(() ->
                        log.warn("Photo {} not found when handling processing complete callback. Skipping.", photoId)))
                .then();
    }

    private void logSchemaExample(UUID photoId) {
        String example = new StringBuilder()
                .append("\nPhotoVersion DB schema example (required columns)\n")
                .append("photo_id=").append(photoId).append("\n")
                .append("version_type=WEBP_640\n")
                .append("s3_key=versions/").append(photoId).append("/webp_640.webp\n")
                .append("file_size=123456\n")
                .append("width=640\n")
                .append("height=360\n")
                .append("mime_type=image/webp\n")
                .toString();
        log.info(example);
    }

    private void logPayload(UUID photoId, ProcessingCompleteRequest request) {
        StringBuilder sb = new StringBuilder()
                .append("\nProcessingComplete payload (photoId=").append(photoId).append(")\n")
                .append("status=").append(request.getStatus()).append("\n")
                .append("thumbnailKey=").append(request.getThumbnailKey()).append("\n");

        ProcessingCompleteRequest.Metadata metadata = request.getMetadata();
        sb.append("metadata.width=").append(metadata != null ? metadata.getWidth() : "null").append("\n");
        sb.append("metadata.height=").append(metadata != null ? metadata.getHeight() : "null").append("\n");
        sb.append("metadata.format=").append(metadata != null ? metadata.getFormat() : "null").append("\n");
        sb.append("metadata.size=").append(metadata != null ? metadata.getSize() : "null").append("\n");

        if (request.getVersions() == null || request.getVersions().isEmpty()) {
            sb.append("versions=[]\n");
        } else {
            for (int i = 0; i < request.getVersions().size(); i++) {
                ProcessingCompleteRequest.Version version = request.getVersions().get(i);
                sb.append("versions[").append(i).append("].versionType=").append(version.getVersionType()).append("\n");
                sb.append("versions[").append(i).append("].s3Key=").append(version.getS3Key()).append("\n");
                sb.append("versions[").append(i).append("].width=").append(version.getWidth()).append("\n");
                sb.append("versions[").append(i).append("].height=").append(version.getHeight()).append("\n");
                sb.append("versions[").append(i).append("].fileSize=").append(version.getFileSize()).append("\n");
                sb.append("versions[").append(i).append("].mimeType=").append(version.getMimeType()).append("\n");
            }
        }

        if (request.getLabels() == null || request.getLabels().isEmpty()) {
            sb.append("labels=[]\n");
        } else {
            for (int i = 0; i < request.getLabels().size(); i++) {
                ProcessingCompleteRequest.Label label = request.getLabels().get(i);
                sb.append("labels[").append(i).append("].labelName=").append(label.getLabelName()).append("\n");
                sb.append("labels[").append(i).append("].confidence=").append(label.getConfidence()).append("\n");
            }
        }

        log.info(sb.toString());
    }
}
