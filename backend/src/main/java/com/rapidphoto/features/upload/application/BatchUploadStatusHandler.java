package com.rapidphoto.features.upload.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.features.upload.api.dto.BatchUploadStatusResponse;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.UploadJobRepository;
import io.micrometer.observation.annotation.Observed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Query handler for batch upload status.
 * Combines UploadJob and Photo states into a projection.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BatchUploadStatusHandler {

    private final UploadJobRepository uploadJobRepository;
    private final PhotoRepository photoRepository;

    /**
     * Get batch upload status for a user.
     *
     * @param userId User ID
     * @return Batch upload status response
     */
    @Observed(name = "upload.batch.status")
    public Mono<BatchUploadStatusResponse> getBatchStatus(UUID userId) {
        log.debug("Fetching batch upload status for userId: {}", userId);

        return uploadJobRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .collectList()
                .flatMap(uploadJobs -> enrichWithPhotoStatus(uploadJobs, userId))
                .map(this::toBatchResponse)
                .doOnSuccess(response -> log.debug("Returning {} upload statuses for userId: {}",
                        response.getUploads().size(), userId));
    }

    private Mono<List<UploadStatusProjection>> enrichWithPhotoStatus(List<UploadJob> uploadJobs, UUID userId) {
        if (uploadJobs.isEmpty()) {
            return Mono.just(List.of());
        }

        // Get all photos for this user
        return photoRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .collectList()
                .map(photos -> {
                    // Create a map of uploadJobId -> Photo for quick lookup
                    Map<UUID, Photo> photosByUploadJobId = photos.stream()
                            .collect(Collectors.toMap(Photo::getUploadJobId, photo -> photo, (p1, p2) -> p1));

                    // Combine upload jobs with their corresponding photos
                    return uploadJobs.stream()
                            .map(uploadJob -> {
                                Photo photo = photosByUploadJobId.get(uploadJob.getId());
                                return new UploadStatusProjection(uploadJob, photo);
                            })
                            .collect(Collectors.toList());
                });
    }

    private BatchUploadStatusResponse toBatchResponse(List<UploadStatusProjection> projections) {
        List<BatchUploadStatusResponse.UploadStatus> statuses = projections.stream()
                .map(this::toUploadStatus)
                .collect(Collectors.toList());

        return BatchUploadStatusResponse.builder()
                .uploads(statuses)
                .build();
    }

    private BatchUploadStatusResponse.UploadStatus toUploadStatus(UploadStatusProjection projection) {
        UploadJob uploadJob = projection.uploadJob();
        Photo photo = projection.photo();

        return BatchUploadStatusResponse.UploadStatus.builder()
                .uploadId(uploadJob.getId())
                .fileName(uploadJob.getFileName())
                .uploadJobStatus(uploadJob.getStatus())
                .photoStatus(photo != null ? photo.getStatus() : null)
                .photoId(photo != null ? photo.getId() : null)
                .createdAt(uploadJob.getCreatedAt())
                .confirmedAt(uploadJob.getConfirmedAt())
                .processedAt(photo != null ? photo.getProcessedAt() : null)
                .errorMessage(uploadJob.getErrorMessage() != null ? uploadJob.getErrorMessage() :
                        (photo != null ? photo.getErrorMessage() : null))
                .build();
    }

    /**
     * Internal projection combining UploadJob and Photo.
     */
    private record UploadStatusProjection(UploadJob uploadJob, Photo photo) {}
}
