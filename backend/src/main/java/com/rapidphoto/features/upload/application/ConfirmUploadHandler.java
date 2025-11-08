package com.rapidphoto.features.upload.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.domain.UploadJobStatus;
import com.rapidphoto.features.upload.api.dto.ConfirmUploadResponse;
import com.rapidphoto.features.upload.domain.command.ConfirmUploadCommand;
import com.rapidphoto.features.upload.domain.event.PhotoUploadConfirmedEvent;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.UploadJobRepository;
import io.micrometer.observation.annotation.Observed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.Instant;

/**
 * Command handler for ConfirmUpload.
 * Validates ETag, creates Photo aggregate, and publishes event to SQS.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ConfirmUploadHandler {

    private final UploadJobRepository uploadJobRepository;
    private final PhotoRepository photoRepository;
    private final PhotoEventPublisher photoEventPublisher;

    /**
     * Handle the ConfirmUpload command.
     *
     * @param command The command
     * @return Response with photo and upload details
     */
    @Observed(name = "upload.confirm")
    public Mono<ConfirmUploadResponse> handle(ConfirmUploadCommand command) {
        log.info("Confirming upload for uploadId: {}, userId: {}, etag: {}",
                command.uploadId(), command.userId(), command.etag());

        return uploadJobRepository.findById(command.uploadId())
                .switchIfEmpty(Mono.error(new UploadJobNotFoundException(
                        "Upload job not found: " + command.uploadId())))
                .flatMap(uploadJob -> validateAndConfirmUpload(uploadJob, command))
                .flatMap(uploadJob -> uploadJobRepository.updateStatusWithEnumCast(
                        uploadJob.getId(),
                        uploadJob.getStatus(),
                        uploadJob.getEtag(),
                        uploadJob.getConfirmedAt()
                ).thenReturn(uploadJob))
                .flatMap(this::createPhoto)
                .flatMap(photo -> photoRepository.saveWithEnumCast(photo)
                        .flatMap(savedPhoto -> publishEvent(savedPhoto, uploadJobRepository.findById(command.uploadId()))
                                .thenReturn(savedPhoto)))
                .map(this::toResponse)
                .doOnSuccess(response -> log.info("Successfully confirmed upload, photoId: {}, uploadId: {}",
                        response.getPhotoId(), response.getUploadId()))
                .doOnError(error -> log.error("Failed to confirm upload for uploadId: {}",
                        command.uploadId(), error));
    }

    private Mono<UploadJob> validateAndConfirmUpload(UploadJob uploadJob, ConfirmUploadCommand command) {
        // Verify ownership
        if (!uploadJob.getUserId().equals(command.userId())) {
            return Mono.error(new UnauthorizedUploadAccessException(
                    "Upload job does not belong to user"));
        }

        // Check if already confirmed
        if ("CONFIRMED".equals(uploadJob.getStatus())) {
            log.warn("Upload job {} already confirmed", command.uploadId());
            return Mono.just(uploadJob);
        }

        // Check expiration
        if (uploadJob.isExpired()) {
            return Mono.error(new UploadExpiredException(
                    "Upload job has expired"));
        }

        // Update upload job with UPLOADED status first (will be CONFIRMED after photo creation)
        uploadJob.setStatus("UPLOADED");
        uploadJob.setEtag(command.etag());

        return Mono.just(uploadJob);
    }

    private Mono<Photo> createPhoto(UploadJob uploadJob) {
        Photo photo = Photo.fromUploadJob(uploadJob);
        log.debug("Creating photo from upload job: {}", uploadJob.getId());
        return Mono.just(photo);
    }

    private Mono<Void> publishEvent(Photo photo, Mono<UploadJob> uploadJobMono) {
        return uploadJobMono.flatMap(uploadJob -> {
            // Mark upload job as confirmed now
            uploadJob.confirm(uploadJob.getEtag());
            return uploadJobRepository.updateStatusWithEnumCast(
                    uploadJob.getId(),
                    uploadJob.getStatus(),
                    uploadJob.getEtag(),
                    uploadJob.getConfirmedAt()
            ).then(Mono.defer(() -> {
                        PhotoUploadConfirmedEvent event = new PhotoUploadConfirmedEvent(
                                photo.getId(),
                                uploadJob.getId(),
                                photo.getUserId(),
                                photo.getOriginalS3Key(),
                                photo.getFileName(),
                                photo.getFileSize(),
                                photo.getMimeType(),
                                Instant.now()
                        );
                        return photoEventPublisher.publishPhotoUploadConfirmed(event);
                    }));
        });
    }

    private ConfirmUploadResponse toResponse(Photo photo) {
        return ConfirmUploadResponse.builder()
                .photoId(photo.getId())
                .uploadId(photo.getUploadJobId())
                .status(photo.getStatus())
                .message("Upload confirmed successfully. Photo is pending processing.")
                .build();
    }

    /**
     * Exception thrown when upload job is not found.
     */
    public static class UploadJobNotFoundException extends RuntimeException {
        public UploadJobNotFoundException(String message) {
            super(message);
        }
    }

    /**
     * Exception thrown when user is not authorized to access upload.
     */
    public static class UnauthorizedUploadAccessException extends RuntimeException {
        public UnauthorizedUploadAccessException(String message) {
            super(message);
        }
    }

    /**
     * Exception thrown when upload has expired.
     */
    public static class UploadExpiredException extends RuntimeException {
        public UploadExpiredException(String message) {
            super(message);
        }
    }
}
