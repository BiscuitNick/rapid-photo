package com.rapidphoto.features.gallery.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoLabel;
import com.rapidphoto.domain.PhotoVersion;
import com.rapidphoto.features.gallery.api.dto.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Maps domain entities to read-model DTOs.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PhotoReadModelMapper {

    private final S3DownloadUrlService s3DownloadUrlService;

    /**
     * Map Photo with versions and labels to detailed PhotoResponse.
     */
    public Mono<PhotoResponse> toPhotoResponse(Photo photo,
                                                 List<PhotoVersion> versions,
                                                 List<PhotoLabel> labels) {
        return s3DownloadUrlService.generatePresignedGetUrl(photo.getOriginalS3Key())
                .flatMap(originalUrlResult -> {
                    // Find thumbnail version
                    String thumbnailUrl = null;
                    for (PhotoVersion version : versions) {
                        if (version.isThumbnail()) {
                            thumbnailUrl = s3DownloadUrlService.generatePresignedGetUrl(version.getS3Key())
                                    .map(S3DownloadUrlService.DownloadUrlResult::downloadUrl)
                                    .block();
                            break;
                        }
                    }

                    // Map versions to DTOs
                    List<PhotoVersionDto> versionDtos = versions.stream()
                            .map(this::toPhotoVersionDto)
                            .collect(Collectors.toList());

                    // Map labels to DTOs
                    List<PhotoLabelDto> labelDtos = labels.stream()
                            .map(this::toPhotoLabelDto)
                            .collect(Collectors.toList());

                    return Mono.just(PhotoResponse.builder()
                            .id(photo.getId())
                            .fileName(photo.getFileName())
                            .status(photo.getStatusEnum())
                            .fileSize(photo.getFileSize())
                            .mimeType(photo.getMimeType())
                            .width(photo.getWidth())
                            .height(photo.getHeight())
                            .originalUrl(originalUrlResult.downloadUrl())
                            .thumbnailUrl(thumbnailUrl)
                            .versions(versionDtos)
                            .labels(labelDtos)
                            .createdAt(photo.getCreatedAt())
                            .processedAt(photo.getProcessedAt())
                            .takenAt(photo.getTakenAt())
                            .cameraMake(photo.getCameraMake())
                            .cameraModel(photo.getCameraModel())
                            .gpsLatitude(photo.getGpsLatitude())
                            .gpsLongitude(photo.getGpsLongitude())
                            .build());
                });
    }

    /**
     * Map Photo with limited data to PhotoListItemDto.
     */
    public Mono<PhotoListItemDto> toPhotoListItem(Photo photo,
                                                    String thumbnailS3Key,
                                                    List<String> labelNames) {
        if (thumbnailS3Key == null) {
            return Mono.just(createPhotoListItemWithoutThumbnail(photo, labelNames));
        }

        return s3DownloadUrlService.generatePresignedGetUrl(thumbnailS3Key)
                .map(result -> PhotoListItemDto.builder()
                        .id(photo.getId())
                        .fileName(photo.getFileName())
                        .status(photo.getStatusEnum())
                        .thumbnailUrl(result.downloadUrl())
                        .width(photo.getWidth())
                        .height(photo.getHeight())
                        .labels(labelNames)
                        .createdAt(photo.getCreatedAt())
                        .takenAt(photo.getTakenAt())
                        .build())
                .onErrorResume(error -> {
                    log.warn("Failed to generate thumbnail URL for photo {}, using null", photo.getId(), error);
                    return Mono.just(createPhotoListItemWithoutThumbnail(photo, labelNames));
                });
    }

    private PhotoListItemDto createPhotoListItemWithoutThumbnail(Photo photo, List<String> labelNames) {
        return PhotoListItemDto.builder()
                .id(photo.getId())
                .fileName(photo.getFileName())
                .status(photo.getStatusEnum())
                .thumbnailUrl(null)
                .width(photo.getWidth())
                .height(photo.getHeight())
                .labels(labelNames)
                .createdAt(photo.getCreatedAt())
                .takenAt(photo.getTakenAt())
                .build();
    }

    /**
     * Map PhotoVersion to PhotoVersionDto with presigned URL.
     */
    private PhotoVersionDto toPhotoVersionDto(PhotoVersion version) {
        String url = s3DownloadUrlService.generatePresignedGetUrl(version.getS3Key())
                .map(S3DownloadUrlService.DownloadUrlResult::downloadUrl)
                .block();

        return PhotoVersionDto.builder()
                .versionType(version.getVersionType())
                .url(url)
                .width(version.getWidth())
                .height(version.getHeight())
                .fileSize(version.getFileSize())
                .mimeType(version.getMimeType())
                .build();
    }

    /**
     * Map PhotoLabel to PhotoLabelDto.
     */
    private PhotoLabelDto toPhotoLabelDto(PhotoLabel label) {
        return PhotoLabelDto.builder()
                .labelName(label.getLabelName())
                .confidence(label.getConfidence())
                .confidenceLevel(label.getConfidenceLevel())
                .build();
    }

    /**
     * Create DownloadUrlResponse from DownloadUrlResult.
     */
    public DownloadUrlResponse toDownloadUrlResponse(S3DownloadUrlService.DownloadUrlResult result,
                                                       String fileName,
                                                       Long fileSize) {
        return DownloadUrlResponse.builder()
                .downloadUrl(result.downloadUrl())
                .expiresAt(Instant.now().plusSeconds(result.expirationMinutes() * 60L))
                .fileName(fileName)
                .fileSize(fileSize)
                .build();
    }
}
