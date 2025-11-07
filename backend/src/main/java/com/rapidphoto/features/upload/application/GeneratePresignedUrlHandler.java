package com.rapidphoto.features.upload.application;

import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.features.upload.api.dto.GeneratePresignedUrlResponse;
import com.rapidphoto.features.upload.domain.command.GeneratePresignedUrlCommand;
import com.rapidphoto.repository.UploadJobRepository;
import io.micrometer.observation.annotation.Observed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.Instant;

/**
 * Command handler for GeneratePresignedUrl.
 * Validates constraints, generates presigned URL, and persists UploadJob.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GeneratePresignedUrlHandler {

    private final UploadPolicyService uploadPolicyService;
    private final S3PresignedUrlService s3PresignedUrlService;
    private final UploadJobRepository uploadJobRepository;

    /**
     * Handle the GeneratePresignedUrl command.
     *
     * @param command The command
     * @return Response with presigned URL and upload details
     */
    @Observed(name = "upload.generate.presigned-url")
    public Mono<GeneratePresignedUrlResponse> handle(GeneratePresignedUrlCommand command) {
        log.info("Generating presigned URL for userId: {}, fileName: {}, fileSize: {}",
                command.userId(), command.fileName(), command.fileSize());

        return uploadPolicyService.verifyUploadLimit(command.userId())
                .then(uploadPolicyService.validateFile(command.fileSize(), command.mimeType()))
                .then(s3PresignedUrlService.generatePresignedPutUrl(
                        command.userId(),
                        command.fileName(),
                        command.mimeType()))
                .flatMap(presignedResult -> createUploadJob(command, presignedResult))
                .flatMap(uploadJobRepository::save)
                .map(this::toResponse)
                .doOnSuccess(response -> log.info("Successfully generated presigned URL, uploadId: {}",
                        response.getUploadId()))
                .doOnError(error -> log.error("Failed to generate presigned URL for userId: {}",
                        command.userId(), error));
    }

    private Mono<UploadJob> createUploadJob(GeneratePresignedUrlCommand command,
                                             S3PresignedUrlService.PresignedUrlResult presignedResult) {
        Instant expiresAt = Instant.now().plusSeconds(presignedResult.expirationMinutes() * 60L);

        UploadJob uploadJob = UploadJob.create(
                command.userId(),
                presignedResult.s3Key(),
                presignedResult.presignedUrl(),
                command.fileName(),
                command.fileSize(),
                command.mimeType(),
                expiresAt
        );

        return Mono.just(uploadJob);
    }

    private GeneratePresignedUrlResponse toResponse(UploadJob uploadJob) {
        return GeneratePresignedUrlResponse.builder()
                .uploadId(uploadJob.getId())
                .presignedUrl(uploadJob.getPresignedUrl())
                .s3Key(uploadJob.getS3Key())
                .expiresAt(uploadJob.getExpiresAt())
                .fileName(uploadJob.getFileName())
                .fileSize(uploadJob.getFileSize())
                .mimeType(uploadJob.getMimeType())
                .build();
    }
}
