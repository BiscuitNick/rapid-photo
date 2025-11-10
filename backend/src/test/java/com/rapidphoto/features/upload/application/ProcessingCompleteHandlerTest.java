package com.rapidphoto.features.upload.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoLabel;
import com.rapidphoto.domain.PhotoStatus;
import com.rapidphoto.domain.PhotoVersion;
import com.rapidphoto.domain.PhotoVersionType;
import com.rapidphoto.features.upload.api.dto.ProcessingCompleteRequest;
import com.rapidphoto.repository.PhotoLabelRepository;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.PhotoVersionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProcessingCompleteHandlerTest {

    @Mock
    private PhotoRepository photoRepository;

    @Mock
    private PhotoVersionRepository photoVersionRepository;

    @Mock
    private PhotoLabelRepository photoLabelRepository;

    @InjectMocks
    private ProcessingCompleteHandler handler;

    private UUID photoId;
    private Photo existingPhoto;

    @BeforeEach
    void setUp() {
        photoId = UUID.randomUUID();
        existingPhoto = new Photo();
        existingPhoto.setId(photoId);
        existingPhoto.setStatusEnum(PhotoStatus.PENDING_PROCESSING);
        existingPhoto.setFileSize(2_000_000L);
    }

    @Test
    void shouldSkipWhenPhotoMissing() {
        ProcessingCompleteRequest request = new ProcessingCompleteRequest();
        request.setStatus(PhotoStatus.READY.name());

        when(photoRepository.findById(photoId)).thenReturn(Mono.empty());

        StepVerifier.create(handler.handle(photoId, request))
                .verifyComplete();

        verify(photoRepository, never()).updateProcessingResults(any(), any(), any(), any(), any(), any());
        verify(photoVersionRepository, never()).saveWithEnumCast(any());
        verify(photoLabelRepository, never()).save(any(PhotoLabel.class));
    }

    @Test
    void shouldPersistVersionsAndLabelsWithMetadata() {
        ProcessingCompleteRequest.Metadata metadata = new ProcessingCompleteRequest.Metadata();
        metadata.setWidth(4000);
        metadata.setHeight(3000);

        ProcessingCompleteRequest.Version version = new ProcessingCompleteRequest.Version();
        version.setVersionType(PhotoVersionType.WEBP_640.name());
        version.setS3Key("versions/" + photoId + "/webp_640.webp");
        version.setWidth(640);
        version.setHeight(360);
        version.setFileSize(123_456L);
        version.setMimeType("image/webp");

        ProcessingCompleteRequest.Label labelHigh = new ProcessingCompleteRequest.Label();
        labelHigh.setLabelName("Landscape");
        labelHigh.setConfidence(99.9);

        ProcessingCompleteRequest.Label labelLow = new ProcessingCompleteRequest.Label();
        labelLow.setLabelName("Low");
        labelLow.setConfidence(90.0);

        ProcessingCompleteRequest request = new ProcessingCompleteRequest();
        request.setStatus(PhotoStatus.READY.name());
        request.setMetadata(metadata);
        request.setVersions(List.of(version));
        request.setLabels(List.of(labelHigh, labelLow));

        when(photoRepository.findById(photoId)).thenReturn(Mono.just(existingPhoto));
        when(photoRepository.updateProcessingResults(any(), any(), any(), any(), any(), any())).thenReturn(Mono.empty());
        when(photoVersionRepository.saveWithEnumCast(any(PhotoVersion.class)))
                .thenAnswer(invocation -> {
                    PhotoVersion arg = invocation.getArgument(0);
                    PhotoVersion saved = PhotoVersion.builder()
                            .id(UUID.randomUUID())
                            .photoId(arg.getPhotoId())
                            .versionType(arg.getVersionType())
                            .s3Key(arg.getS3Key())
                            .fileSize(arg.getFileSize())
                            .width(arg.getWidth())
                            .height(arg.getHeight())
                            .mimeType(arg.getMimeType())
                            .createdAt(Instant.now())
                            .build();
                    return Mono.just(saved);
                });
        when(photoLabelRepository.save(any(PhotoLabel.class))).thenAnswer(invocation -> {
            PhotoLabel arg = invocation.getArgument(0);
            arg.setId(UUID.randomUUID());
            arg.setConfidence(BigDecimal.valueOf(arg.getConfidence().doubleValue()));
            return Mono.just(arg);
        });

        StepVerifier.create(handler.handle(photoId, request))
                .verifyComplete();

        verify(photoRepository).updateProcessingResults(
                eq(photoId),
                eq(PhotoStatus.READY.name()),
                eq(metadata.getWidth()),
                eq(metadata.getHeight()),
                any(Instant.class),
                any(Instant.class)
        );
        ArgumentCaptor<PhotoVersion> versionCaptor = ArgumentCaptor.forClass(PhotoVersion.class);
        verify(photoVersionRepository).saveWithEnumCast(versionCaptor.capture());
        PhotoVersion captured = versionCaptor.getValue();
        assertThat(captured.getFileSize()).isEqualTo(123_456L);
        assertThat(captured.getHeight()).isEqualTo(360);
        assertThat(captured.getWidth()).isEqualTo(640);
        assertThat(captured.getMimeType()).isEqualTo("image/webp");

        ArgumentCaptor<PhotoLabel> labelCaptor = ArgumentCaptor.forClass(PhotoLabel.class);
        verify(photoLabelRepository).save(labelCaptor.capture());
        assertThat(labelCaptor.getValue().getLabelName()).isEqualTo("Landscape");
    }
}
