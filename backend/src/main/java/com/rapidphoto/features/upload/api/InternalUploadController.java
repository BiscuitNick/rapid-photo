package com.rapidphoto.features.upload.api;

import com.rapidphoto.features.upload.api.dto.ProcessingCompleteRequest;
import com.rapidphoto.features.upload.application.ProcessingCompleteHandler;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Internal REST controller for Lambda callbacks.
 * NOT exposed to external clients - secured by Lambda secret header.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/internal/photos")
@RequiredArgsConstructor
public class InternalUploadController {

    private final ProcessingCompleteHandler processingCompleteHandler;

    @Value("${lambda.secret:rapid-photo-lambda-secret-change-in-production}")
    private String lambdaSecret;

    /**
     * POST /api/v1/internal/photos/{photoId}/processing-complete
     * Callback from Lambda when image processing completes.
     */
    @PostMapping(value = "/{photoId}/processing-complete", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public Mono<Void> processingComplete(
            @PathVariable UUID photoId,
            @Valid @RequestBody ProcessingCompleteRequest request,
            @RequestHeader(value = "X-Lambda-Secret", required = false) String providedSecret) {

        // Validate Lambda secret
        if (providedSecret == null || !providedSecret.equals(lambdaSecret)) {
            log.warn("Unauthorized Lambda callback attempt for photo: {}", photoId);
            return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid Lambda secret"));
        }

        log.info("Processing complete callback received for photo: {}", photoId);

        return processingCompleteHandler.handle(photoId, request)
                .doOnSuccess(v -> log.info("Successfully processed completion for photo: {}", photoId))
                .doOnError(e -> log.error("Failed to process completion for photo: {}", photoId, e));
    }
}
