package com.rapidphoto.features.upload.api;

import com.rapidphoto.features.upload.api.dto.*;
import com.rapidphoto.features.upload.application.BatchUploadStatusHandler;
import com.rapidphoto.features.upload.application.ConfirmUploadHandler;
import com.rapidphoto.features.upload.application.GeneratePresignedUrlHandler;
import com.rapidphoto.features.upload.domain.command.ConfirmUploadCommand;
import com.rapidphoto.features.upload.domain.command.GeneratePresignedUrlCommand;
import com.rapidphoto.security.SecurityContextUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * REST controller for upload operations.
 * Implements GeneratePresignedUrl, ConfirmUpload, and batch status endpoints.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/uploads")
@RequiredArgsConstructor
public class UploadController {

    private final GeneratePresignedUrlHandler generatePresignedUrlHandler;
    private final ConfirmUploadHandler confirmUploadHandler;
    private final BatchUploadStatusHandler batchUploadStatusHandler;

    /**
     * POST /api/v1/uploads/initiate
     * Generate a presigned URL for uploading a file.
     */
    @PostMapping(value = "/initiate", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<GeneratePresignedUrlResponse> initiateUpload(
            @Valid @RequestBody GeneratePresignedUrlRequest request) {

        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.info("Initiate upload request from userId: {}, fileName: {}",
                            userId, request.getFileName());

                    GeneratePresignedUrlCommand command = new GeneratePresignedUrlCommand(
                            userId,
                            request.getFileName(),
                            request.getFileSize(),
                            request.getMimeType()
                    );

                    return generatePresignedUrlHandler.handle(command);
                });
    }

    /**
     * POST /api/v1/uploads/{uploadId}/confirm
     * Confirm that an upload has been completed.
     */
    @PostMapping(value = "/{uploadId}/confirm", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public Mono<ConfirmUploadResponse> confirmUpload(
            @PathVariable UUID uploadId,
            @Valid @RequestBody ConfirmUploadRequest request) {

        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.info("Confirm upload request for uploadId: {}, userId: {}",
                            uploadId, userId);

                    ConfirmUploadCommand command = new ConfirmUploadCommand(
                            uploadId,
                            userId,
                            request.getEtag()
                    );

                    return confirmUploadHandler.handle(command);
                });
    }

    /**
     * GET /api/v1/uploads/batch/status
     * Get batch upload status combining UploadJob and Photo states.
     */
    @GetMapping(value = "/batch/status", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public Mono<BatchUploadStatusResponse> getBatchStatus() {
        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.debug("Batch status request from userId: {}", userId);
                    return batchUploadStatusHandler.getBatchStatus(userId);
                });
    }
}
