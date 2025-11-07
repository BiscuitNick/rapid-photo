package com.rapidphoto.features.upload.api;

import com.rapidphoto.features.upload.application.ConfirmUploadHandler;
import com.rapidphoto.features.upload.application.PhotoEventPublisher;
import com.rapidphoto.features.upload.application.UploadPolicyService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.bind.support.WebExchangeBindException;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler for upload API errors.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Handle validation errors.
     */
    @ExceptionHandler(WebExchangeBindException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleValidationErrors(WebExchangeBindException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.BAD_REQUEST.value(),
                "Validation failed",
                errors,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse));
    }

    /**
     * Handle upload limit exceeded errors.
     */
    @ExceptionHandler(UploadPolicyService.UploadLimitExceededException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleUploadLimitExceeded(
            UploadPolicyService.UploadLimitExceededException ex) {
        log.warn("Upload limit exceeded: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.TOO_MANY_REQUESTS.value(),
                ex.getMessage(),
                null,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(errorResponse));
    }

    /**
     * Handle invalid file errors.
     */
    @ExceptionHandler(UploadPolicyService.InvalidFileException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleInvalidFile(
            UploadPolicyService.InvalidFileException ex) {
        log.warn("Invalid file: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.BAD_REQUEST.value(),
                ex.getMessage(),
                null,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse));
    }

    /**
     * Handle upload job not found errors.
     */
    @ExceptionHandler(ConfirmUploadHandler.UploadJobNotFoundException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleUploadJobNotFound(
            ConfirmUploadHandler.UploadJobNotFoundException ex) {
        log.warn("Upload job not found: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.NOT_FOUND.value(),
                ex.getMessage(),
                null,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse));
    }

    /**
     * Handle unauthorized upload access errors.
     */
    @ExceptionHandler(ConfirmUploadHandler.UnauthorizedUploadAccessException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleUnauthorizedAccess(
            ConfirmUploadHandler.UnauthorizedUploadAccessException ex) {
        log.warn("Unauthorized upload access: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.FORBIDDEN.value(),
                ex.getMessage(),
                null,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse));
    }

    /**
     * Handle upload expired errors.
     */
    @ExceptionHandler(ConfirmUploadHandler.UploadExpiredException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleUploadExpired(
            ConfirmUploadHandler.UploadExpiredException ex) {
        log.warn("Upload expired: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.GONE.value(),
                ex.getMessage(),
                null,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.GONE).body(errorResponse));
    }

    /**
     * Handle event publish errors.
     */
    @ExceptionHandler(PhotoEventPublisher.EventPublishException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleEventPublishError(
            PhotoEventPublisher.EventPublishException ex) {
        log.error("Event publish failed: {}", ex.getMessage(), ex);

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.INTERNAL_SERVER_ERROR.value(),
                "Failed to process upload confirmation. Please try again later.",
                null,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse));
    }

    /**
     * Handle general errors.
     */
    @ExceptionHandler(Exception.class)
    public Mono<ResponseEntity<ErrorResponse>> handleGeneralError(Exception ex) {
        log.error("Unexpected error occurred", ex);

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.INTERNAL_SERVER_ERROR.value(),
                "An unexpected error occurred. Please try again later.",
                null,
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse));
    }

    /**
     * Error response structure.
     */
    public record ErrorResponse(
            int status,
            String message,
            Map<String, String> errors,
            Instant timestamp
    ) {}
}
