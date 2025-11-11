package com.rapidphoto.features.upload;

import com.rapidphoto.features.upload.api.dto.GeneratePresignedUrlResponse;
import com.rapidphoto.features.upload.application.GeneratePresignedUrlHandler;
import com.rapidphoto.features.upload.application.S3PresignedUrlService;
import com.rapidphoto.features.upload.application.UploadPolicyService;
import com.rapidphoto.features.upload.domain.command.GeneratePresignedUrlCommand;
import com.rapidphoto.repository.UploadJobRepository;
import com.rapidphoto.domain.UploadJob;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Unit tests for GeneratePresignedUrlHandler.
 */
@ExtendWith(MockitoExtension.class)
class GeneratePresignedUrlHandlerTest {

    @Mock
    private UploadPolicyService uploadPolicyService;

    @Mock
    private S3PresignedUrlService s3PresignedUrlService;

    @Mock
    private UploadJobRepository uploadJobRepository;

    @InjectMocks
    private GeneratePresignedUrlHandler handler;

    @Test
    void shouldGeneratePresignedUrl() {
        // Given
        UUID userId = UUID.randomUUID();
        GeneratePresignedUrlCommand command = new GeneratePresignedUrlCommand(
                userId,
                "test-image.jpg",
                1024L * 1024L,
                "image/jpeg"
        );

        S3PresignedUrlService.PresignedUrlResult presignedResult =
                new S3PresignedUrlService.PresignedUrlResult(
                        "https://s3.amazonaws.com/test-bucket/presigned-url",
                        "originals/" + userId + "/test-uuid",
                        15
                );

        when(uploadPolicyService.verifyUploadLimit(userId)).thenReturn(Mono.empty());
        when(uploadPolicyService.validateFile(command.fileSize(), command.mimeType())).thenReturn(Mono.empty());
        when(s3PresignedUrlService.generatePresignedPutUrl(userId, command.fileName(), command.mimeType()))
                .thenReturn(Mono.just(presignedResult));

        UploadJob savedJob = UploadJob.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .s3Key(presignedResult.s3Key())
                .presignedUrl(presignedResult.presignedUrl())
                .fileName(command.fileName())
                .fileSize(command.fileSize())
                .mimeType(command.mimeType())
                .build();

        when(uploadJobRepository.saveWithEnumCast(any(UploadJob.class))).thenReturn(Mono.just(savedJob));

        // When & Then
        StepVerifier.create(handler.handle(command))
                .assertNext(response -> {
                    assertThat(response).isNotNull();
                    assertThat(response.getUploadId()).isEqualTo(savedJob.getId());
                    assertThat(response.getPresignedUrl()).isEqualTo(presignedResult.presignedUrl());
                    assertThat(response.getS3Key()).isEqualTo(presignedResult.s3Key());
                    assertThat(response.getFileName()).isEqualTo("test-image.jpg");
                    assertThat(response.getFileSize()).isEqualTo(1024L * 1024L);
                    assertThat(response.getMimeType()).isEqualTo("image/jpeg");
                })
                .verifyComplete();

        verify(uploadPolicyService).verifyUploadLimit(userId);
        verify(uploadPolicyService).validateFile(command.fileSize(), command.mimeType());
        verify(s3PresignedUrlService).generatePresignedPutUrl(userId, command.fileName(), command.mimeType());
        verify(uploadJobRepository).saveWithEnumCast(any(UploadJob.class));
    }

    @Test
    void shouldFailWhenUploadLimitExceeded() {
        // Given
        UUID userId = UUID.randomUUID();
        GeneratePresignedUrlCommand command = new GeneratePresignedUrlCommand(
                userId,
                "test-image.jpg",
                1024L * 1024L,
                "image/jpeg"
        );

        when(uploadPolicyService.verifyUploadLimit(userId))
                .thenReturn(Mono.error(new UploadPolicyService.UploadLimitExceededException("Limit exceeded")));

        // When & Then
        StepVerifier.create(handler.handle(command))
                .expectError(UploadPolicyService.UploadLimitExceededException.class)
                .verify();

        verify(uploadPolicyService).verifyUploadLimit(userId);
        verify(uploadPolicyService, never()).validateFile(any(), any());
        verify(s3PresignedUrlService, never()).generatePresignedPutUrl(any(), any(), any());
        verify(uploadJobRepository, never()).saveWithEnumCast(any());
    }

    @Test
    void shouldFailWhenFileValidationFails() {
        // Given
        UUID userId = UUID.randomUUID();
        GeneratePresignedUrlCommand command = new GeneratePresignedUrlCommand(
                userId,
                "test-image.pdf",
                1024L * 1024L,
                "application/pdf"
        );

        when(uploadPolicyService.verifyUploadLimit(userId)).thenReturn(Mono.empty());
        when(uploadPolicyService.validateFile(command.fileSize(), command.mimeType()))
                .thenReturn(Mono.error(new UploadPolicyService.InvalidFileException("Invalid MIME type")));

        // When & Then
        StepVerifier.create(handler.handle(command))
                .expectError(UploadPolicyService.InvalidFileException.class)
                .verify();

        verify(uploadPolicyService).verifyUploadLimit(userId);
        verify(uploadPolicyService).validateFile(command.fileSize(), command.mimeType());
        verify(s3PresignedUrlService, never()).generatePresignedPutUrl(any(), any(), any());
        verify(uploadJobRepository, never()).saveWithEnumCast(any());
    }
}
