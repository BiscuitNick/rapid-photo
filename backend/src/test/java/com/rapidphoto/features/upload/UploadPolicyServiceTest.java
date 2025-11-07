package com.rapidphoto.features.upload;

import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.domain.UploadJobStatus;
import com.rapidphoto.features.upload.application.UploadPolicyService;
import com.rapidphoto.repository.UploadJobRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.time.Instant;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Unit tests for UploadPolicyService.
 */
@ExtendWith(MockitoExtension.class)
class UploadPolicyServiceTest {

    @Mock
    private UploadJobRepository uploadJobRepository;

    private UploadPolicyService uploadPolicyService;

    @BeforeEach
    void setUp() {
        uploadPolicyService = new UploadPolicyService(uploadJobRepository);
    }

    @Test
    void shouldAllowUploadWhenBelowLimit() {
        // Given
        UUID userId = UUID.randomUUID();
        when(uploadJobRepository.countActiveUploadsByUserId(userId))
                .thenReturn(Mono.just(50L));

        // When & Then
        StepVerifier.create(uploadPolicyService.verifyUploadLimit(userId))
                .verifyComplete();
    }

    @Test
    void shouldRejectUploadWhenAtLimit() {
        // Given
        UUID userId = UUID.randomUUID();
        when(uploadJobRepository.countActiveUploadsByUserId(userId))
                .thenReturn(Mono.just(100L));

        // When & Then
        StepVerifier.create(uploadPolicyService.verifyUploadLimit(userId))
                .expectError(UploadPolicyService.UploadLimitExceededException.class)
                .verify();
    }

    @Test
    void shouldRejectUploadWhenExceedingLimit() {
        // Given
        UUID userId = UUID.randomUUID();
        when(uploadJobRepository.countActiveUploadsByUserId(userId))
                .thenReturn(Mono.just(150L));

        // When & Then
        StepVerifier.create(uploadPolicyService.verifyUploadLimit(userId))
                .expectError(UploadPolicyService.UploadLimitExceededException.class)
                .verify();
    }

    @Test
    void shouldValidateCorrectFileSize() {
        // When & Then
        StepVerifier.create(uploadPolicyService.validateFile(1024L * 1024L, "image/jpeg"))
                .verifyComplete();
    }

    @Test
    void shouldRejectZeroFileSize() {
        // When & Then
        StepVerifier.create(uploadPolicyService.validateFile(0L, "image/jpeg"))
                .expectError(UploadPolicyService.InvalidFileException.class)
                .verify();
    }

    @Test
    void shouldRejectNegativeFileSize() {
        // When & Then
        StepVerifier.create(uploadPolicyService.validateFile(-100L, "image/jpeg"))
                .expectError(UploadPolicyService.InvalidFileException.class)
                .verify();
    }

    @Test
    void shouldRejectOversizedFile() {
        // Given - 200MB file
        Long oversizedFile = 200L * 1024L * 1024L;

        // When & Then
        StepVerifier.create(uploadPolicyService.validateFile(oversizedFile, "image/jpeg"))
                .expectError(UploadPolicyService.InvalidFileException.class)
                .verify();
    }

    @Test
    void shouldValidateCorrectMimeTypes() {
        // Valid MIME types
        String[] validMimeTypes = {
                "image/jpeg",
                "image/jpg",
                "image/png",
                "image/gif",
                "image/webp",
                "image/heic",
                "image/heif"
        };

        for (String mimeType : validMimeTypes) {
            StepVerifier.create(uploadPolicyService.validateFile(1024L, mimeType))
                    .verifyComplete();
        }
    }

    @Test
    void shouldRejectInvalidMimeTypes() {
        // Invalid MIME types
        String[] invalidMimeTypes = {
                "application/pdf",
                "video/mp4",
                "text/plain",
                "image/svg+xml",
                "image/bmp"
        };

        for (String mimeType : invalidMimeTypes) {
            StepVerifier.create(uploadPolicyService.validateFile(1024L, mimeType))
                    .expectError(UploadPolicyService.InvalidFileException.class)
                    .verify();
        }
    }

    @Test
    void shouldRejectNullMimeType() {
        // When & Then
        StepVerifier.create(uploadPolicyService.validateFile(1024L, null))
                .expectError(UploadPolicyService.InvalidFileException.class)
                .verify();
    }
}
