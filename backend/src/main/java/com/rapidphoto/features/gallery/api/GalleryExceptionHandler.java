package com.rapidphoto.features.gallery.api;

import com.rapidphoto.features.gallery.application.DeletePhotoHandler;
import com.rapidphoto.features.gallery.application.DownloadPhotoHandler;
import com.rapidphoto.features.gallery.application.GetPhotoDetailHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import reactor.core.publisher.Mono;

import java.time.Instant;

/**
 * Exception handler for gallery API errors.
 */
@Slf4j
@RestControllerAdvice(assignableTypes = GalleryController.class)
public class GalleryExceptionHandler {

    /**
     * Handle photo not found errors.
     */
    @ExceptionHandler({
            GetPhotoDetailHandler.PhotoNotFoundException.class,
            DeletePhotoHandler.PhotoNotFoundException.class,
            DownloadPhotoHandler.PhotoNotFoundException.class
    })
    public Mono<ResponseEntity<ErrorResponse>> handlePhotoNotFound(RuntimeException ex) {
        log.warn("Photo not found: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.NOT_FOUND.value(),
                ex.getMessage(),
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse));
    }

    /**
     * Handle version not found errors.
     */
    @ExceptionHandler(DownloadPhotoHandler.VersionNotFoundException.class)
    public Mono<ResponseEntity<ErrorResponse>> handleVersionNotFound(
            DownloadPhotoHandler.VersionNotFoundException ex) {
        log.warn("Photo version not found: {}", ex.getMessage());

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.NOT_FOUND.value(),
                ex.getMessage(),
                Instant.now()
        );

        return Mono.just(ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse));
    }

    /**
     * Error response structure.
     */
    public record ErrorResponse(
            int status,
            String message,
            Instant timestamp
    ) {}
}
