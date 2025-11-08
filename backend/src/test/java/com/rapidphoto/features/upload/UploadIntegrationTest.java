package com.rapidphoto.features.upload;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoStatus;
import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.domain.UploadJobStatus;
import com.rapidphoto.domain.User;
import com.rapidphoto.features.upload.api.dto.*;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.UploadJobRepository;
import com.rapidphoto.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.reactive.server.WebTestClient;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for Upload API endpoints.
 * Uses Testcontainers for PostgreSQL.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
@Testcontainers
@ActiveProfiles("test")
class UploadIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17.6")
            .withDatabaseName("rapidphoto_test")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.r2dbc.url", () ->
                String.format("r2dbc:postgresql://%s:%d/%s",
                        postgres.getHost(),
                        postgres.getFirstMappedPort(),
                        postgres.getDatabaseName()));
        registry.add("spring.r2dbc.username", postgres::getUsername);
        registry.add("spring.r2dbc.password", postgres::getPassword);

        registry.add("spring.flyway.url", postgres::getJdbcUrl);
        registry.add("spring.flyway.user", postgres::getUsername);
        registry.add("spring.flyway.password", postgres::getPassword);
    }

    @Autowired
    private WebTestClient webTestClient;

    @Autowired
    private UploadJobRepository uploadJobRepository;

    @Autowired
    private PhotoRepository photoRepository;

    @Autowired
    private UserRepository userRepository;

    private UUID testUserId;

    @BeforeEach
    void setUp() {
        // Clean up database
        uploadJobRepository.deleteAll().block();
        photoRepository.deleteAll().block();
        userRepository.deleteAll().block();

        // Create test user
        testUserId = UUID.randomUUID();
        User user = User.builder()
                .id(testUserId)
                .cognitoUserId(testUserId.toString())
                .email("test@example.com")
                .name("Test User")
                .createdAt(Instant.now())
                .build();
        userRepository.insert(user).block();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldGeneratePresignedUrl() {
        // Given
        GeneratePresignedUrlRequest request = new GeneratePresignedUrlRequest();
        request.setFileName("test-image.jpg");
        request.setFileSize(1024L * 1024L); // 1MB
        request.setMimeType("image/jpeg");

        // When & Then
        webTestClient.post()
                .uri("/api/v1/uploads/initiate")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(GeneratePresignedUrlResponse.class)
                .value(response -> {
                    assertThat(response.getUploadId()).isNotNull();
                    assertThat(response.getPresignedUrl()).isNotBlank();
                    assertThat(response.getS3Key()).startsWith("originals/");
                    assertThat(response.getFileName()).isEqualTo("test-image.jpg");
                    assertThat(response.getFileSize()).isEqualTo(1024L * 1024L);
                    assertThat(response.getMimeType()).isEqualTo("image/jpeg");
                    assertThat(response.getExpiresAt()).isNotNull();
                });
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldRejectInvalidFileSize() {
        // Given - file too large
        GeneratePresignedUrlRequest request = new GeneratePresignedUrlRequest();
        request.setFileName("huge-file.jpg");
        request.setFileSize(200_000_000L); // 200MB - exceeds 100MB limit
        request.setMimeType("image/jpeg");

        // When & Then
        webTestClient.post()
                .uri("/api/v1/uploads/initiate")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isBadRequest();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldRejectInvalidMimeType() {
        // Given
        GeneratePresignedUrlRequest request = new GeneratePresignedUrlRequest();
        request.setFileName("document.pdf");
        request.setFileSize(1024L);
        request.setMimeType("application/pdf");

        // When & Then
        webTestClient.post()
                .uri("/api/v1/uploads/initiate")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isBadRequest();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldConfirmUpload() {
        // Given - create an upload job first
        UploadJob uploadJob = createTestUploadJob(testUserId);

        ConfirmUploadRequest request = new ConfirmUploadRequest();
        request.setEtag("test-etag-123");

        // When & Then
        webTestClient.post()
                .uri("/api/v1/uploads/{uploadId}/confirm", uploadJob.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isOk()
                .expectBody(ConfirmUploadResponse.class)
                .value(response -> {
                    assertThat(response.getPhotoId()).isNotNull();
                    assertThat(response.getUploadId()).isEqualTo(uploadJob.getId());
                    assertThat(response.getStatus()).isEqualTo(PhotoStatus.PENDING_PROCESSING.name());
                });

        // Verify upload job was updated
        UploadJob updatedJob = uploadJobRepository.findById(uploadJob.getId()).block();
        assertThat(updatedJob).isNotNull();
        assertThat(updatedJob.getStatus()).isEqualTo(UploadJobStatus.CONFIRMED.name());
        assertThat(updatedJob.getEtag()).isEqualTo("test-etag-123");

        // Verify photo was created
        Photo photo = photoRepository.findByUploadJobId(uploadJob.getId()).block();
        assertThat(photo).isNotNull();
        assertThat(photo.getStatus()).isEqualTo(PhotoStatus.PENDING_PROCESSING.name());
        assertThat(photo.getUserId()).isEqualTo(testUserId);
        assertThat(photo.getOriginalS3Key()).isEqualTo(uploadJob.getS3Key());
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldReturnNotFoundForNonexistentUpload() {
        // Given
        UUID nonexistentUploadId = UUID.randomUUID();
        ConfirmUploadRequest request = new ConfirmUploadRequest();
        request.setEtag("test-etag");

        // When & Then
        webTestClient.post()
                .uri("/api/v1/uploads/{uploadId}/confirm", nonexistentUploadId)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isNotFound();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldGetBatchUploadStatus() {
        // Given - create multiple upload jobs with different statuses
        UploadJob job1 = createTestUploadJob(testUserId);
        UploadJob job2 = createTestUploadJob(testUserId);

        // Confirm one upload
        job2.setStatus(UploadJobStatus.CONFIRMED.name());
        job2.setEtag("etag-2");
        uploadJobRepository.save(job2).block();

        Photo photo = Photo.fromUploadJob(job2);
        photoRepository.saveWithEnumCast(photo).block();

        // When & Then
        webTestClient.get()
                .uri("/api/v1/uploads/batch/status")
                .exchange()
                .expectStatus().isOk()
                .expectBody(BatchUploadStatusResponse.class)
                .value(response -> {
                    assertThat(response.getUploads()).hasSize(2);

                    // Find the INITIATED upload
                    BatchUploadStatusResponse.UploadStatus initiatedStatus = response.getUploads().stream()
                            .filter(s -> s.getUploadId().equals(job1.getId()))
                            .findFirst()
                            .orElseThrow();

                    assertThat(initiatedStatus.getUploadJobStatus()).isEqualTo(UploadJobStatus.INITIATED.name());
                    assertThat(initiatedStatus.getPhotoStatus()).isNull();
                    assertThat(initiatedStatus.getPhotoId()).isNull();

                    // Find the CONFIRMED upload
                    BatchUploadStatusResponse.UploadStatus confirmedStatus = response.getUploads().stream()
                            .filter(s -> s.getUploadId().equals(job2.getId()))
                            .findFirst()
                            .orElseThrow();

                    assertThat(confirmedStatus.getUploadJobStatus()).isEqualTo(UploadJobStatus.CONFIRMED.name());
                    assertThat(confirmedStatus.getPhotoStatus()).isEqualTo(PhotoStatus.PENDING_PROCESSING.name());
                    assertThat(confirmedStatus.getPhotoId()).isEqualTo(photo.getId());
                });
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldReturnEmptyBatchStatusForNewUser() {
        // When & Then
        webTestClient.get()
                .uri("/api/v1/uploads/batch/status")
                .exchange()
                .expectStatus().isOk()
                .expectBody(BatchUploadStatusResponse.class)
                .value(response -> {
                    assertThat(response.getUploads()).isEmpty();
                });
    }

    private UploadJob createTestUploadJob(UUID userId) {
        UploadJob uploadJob = UploadJob.builder()
                .userId(userId)
                .s3Key("originals/" + userId + "/" + UUID.randomUUID())
                .presignedUrl("https://s3.amazonaws.com/test-bucket/presigned-url")
                .fileName("test-image.jpg")
                .fileSize(1024L * 1024L)
                .mimeType("image/jpeg")
                .status(UploadJobStatus.INITIATED.name())
                .expiresAt(java.time.Instant.now().plusSeconds(900))
                .build();

        return uploadJobRepository.save(uploadJob).block();
    }
}
