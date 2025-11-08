package com.rapidphoto.repository;

import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.domain.UploadJobStatus;
import com.rapidphoto.domain.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.r2dbc.DataR2dbcTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import reactor.test.StepVerifier;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for UploadJobRepository using Testcontainers.
 */
@DataR2dbcTest
@Testcontainers
class UploadJobRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17.6")
            .withDatabaseName("testdb")
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
    private UploadJobRepository uploadJobRepository;

    @Autowired
    private UserRepository userRepository;

    private User testUser;

    @BeforeEach
    void setUp() {
        uploadJobRepository.deleteAll().block();
        userRepository.deleteAll().block();

        testUser = User.builder()
                .id(UUID.randomUUID())
                .cognitoUserId("test-cognito-123")
                .email("test@example.com")
                .name("Test User")
                .build();
        testUser = userRepository.insert(testUser).block();
    }

    @Test
    void shouldCreateUploadJob() {
        // Given
        Instant expiresAt = Instant.now().plus(15, ChronoUnit.MINUTES);
        UploadJob uploadJob = UploadJob.create(
                testUser.getId(),
                "originals/" + testUser.getId() + "/" + UUID.randomUUID(),
                "https://s3.example.com/presigned",
                "test.jpg",
                1024L * 1024L,
                "image/jpeg",
                expiresAt
        );

        // When & Then
        StepVerifier.create(uploadJobRepository.save(uploadJob))
                .assertNext(saved -> {
                    assertThat(saved.getId()).isNotNull();
                    assertThat(saved.getUserId()).isEqualTo(testUser.getId());
                    assertThat(saved.getStatus()).isEqualTo(UploadJobStatus.INITIATED.name());
                    assertThat(saved.getExpiresAt()).isEqualTo(expiresAt);
                })
                .verifyComplete();
    }

    @Test
    void shouldFindUploadJobsByUserIdOrderedByCreatedAt() {
        // Given
        createAndSaveUploadJob("file1.jpg", UploadJobStatus.INITIATED);
        createAndSaveUploadJob("file2.jpg", UploadJobStatus.CONFIRMED);
        createAndSaveUploadJob("file3.jpg", UploadJobStatus.INITIATED);

        // When & Then
        StepVerifier.create(uploadJobRepository.findByUserIdOrderByCreatedAtDesc(testUser.getId()))
                .assertNext(job -> assertThat(job.getFileName()).isEqualTo("file3.jpg"))
                .assertNext(job -> assertThat(job.getFileName()).isEqualTo("file2.jpg"))
                .assertNext(job -> assertThat(job.getFileName()).isEqualTo("file1.jpg"))
                .verifyComplete();
    }

    @Test
    void shouldFindUploadJobsByUserIdAndStatus() {
        // Given
        createAndSaveUploadJob("file1.jpg", UploadJobStatus.INITIATED);
        createAndSaveUploadJob("file2.jpg", UploadJobStatus.CONFIRMED);
        createAndSaveUploadJob("file3.jpg", UploadJobStatus.INITIATED);

        // When & Then
        StepVerifier.create(uploadJobRepository.findByUserIdAndStatus(
                        testUser.getId(), UploadJobStatus.INITIATED))
                .expectNextCount(2)
                .verifyComplete();
    }

    @Test
    void shouldCountActiveUploadsByUserId() {
        // Given
        createAndSaveUploadJob("file1.jpg", UploadJobStatus.INITIATED);
        createAndSaveUploadJob("file2.jpg", UploadJobStatus.UPLOADED);
        createAndSaveUploadJob("file3.jpg", UploadJobStatus.CONFIRMED);
        createAndSaveUploadJob("file4.jpg", UploadJobStatus.FAILED);
        createAndSaveUploadJob("file5.jpg", UploadJobStatus.INITIATED);

        // When & Then - Should count only INITIATED and UPLOADED (2 + 1 = 3)
        StepVerifier.create(uploadJobRepository.countActiveUploadsByUserId(testUser.getId()))
                .assertNext(count -> assertThat(count).isEqualTo(3))
                .verifyComplete();
    }

    @Test
    void shouldFindExpiredInitiatedJobs() {
        // Given
        Instant pastExpiry = Instant.now().minus(1, ChronoUnit.HOURS);
        Instant futureExpiry = Instant.now().plus(1, ChronoUnit.HOURS);

        // Expired job
        UploadJob expiredJob = createUploadJob("expired.jpg", UploadJobStatus.INITIATED, pastExpiry);
        uploadJobRepository.save(expiredJob).block();

        // Not expired job
        UploadJob activeJob = createUploadJob("active.jpg", UploadJobStatus.INITIATED, futureExpiry);
        uploadJobRepository.save(activeJob).block();

        // Expired but already confirmed (should not be included)
        UploadJob confirmedJob = createUploadJob("confirmed.jpg", UploadJobStatus.CONFIRMED, pastExpiry);
        uploadJobRepository.save(confirmedJob).block();

        // When & Then
        StepVerifier.create(uploadJobRepository.findExpiredInitiatedJobs(Instant.now()))
                .assertNext(job -> {
                    assertThat(job.getFileName()).isEqualTo("expired.jpg");
                    assertThat(job.isExpired()).isTrue();
                })
                .verifyComplete();
    }

    @Test
    void shouldFindUploadJobByS3Key() {
        // Given
        String s3Key = "originals/" + testUser.getId() + "/" + UUID.randomUUID();
        UploadJob uploadJob = createUploadJob("test.jpg", UploadJobStatus.INITIATED,
                Instant.now().plus(15, ChronoUnit.MINUTES));
        uploadJob.setS3Key(s3Key);
        uploadJobRepository.save(uploadJob).block();

        // When & Then
        StepVerifier.create(uploadJobRepository.findByS3Key(s3Key))
                .assertNext(found -> {
                    assertThat(found.getS3Key()).isEqualTo(s3Key);
                    assertThat(found.getFileName()).isEqualTo("test.jpg");
                })
                .verifyComplete();
    }

    @Test
    void shouldConfirmUploadJob() {
        // Given
        UploadJob uploadJob = createAndSaveUploadJob("test.jpg", UploadJobStatus.UPLOADED);

        // When
        uploadJob.confirm("test-etag-123");
        UploadJob updated = uploadJobRepository.save(uploadJob).block();

        // Then
        StepVerifier.create(uploadJobRepository.findById(uploadJob.getId()))
                .assertNext(found -> {
                    assertThat(found.getStatus()).isEqualTo(UploadJobStatus.CONFIRMED.name());
                    assertThat(found.getEtag()).isEqualTo("test-etag-123");
                    assertThat(found.getConfirmedAt()).isNotNull();
                })
                .verifyComplete();
    }

    @Test
    void shouldFailUploadJob() {
        // Given
        UploadJob uploadJob = createAndSaveUploadJob("test.jpg", UploadJobStatus.INITIATED);

        // When
        uploadJob.fail("Upload timeout");
        UploadJob updated = uploadJobRepository.save(uploadJob).block();

        // Then
        StepVerifier.create(uploadJobRepository.findById(uploadJob.getId()))
                .assertNext(found -> {
                    assertThat(found.getStatus()).isEqualTo(UploadJobStatus.FAILED.name());
                    assertThat(found.getErrorMessage()).isEqualTo("Upload timeout");
                })
                .verifyComplete();
    }

    @Test
    void shouldCheckIfUploadJobCanBeConfirmed() {
        // Given - Valid upload job
        UploadJob validJob = createUploadJob("valid.jpg", UploadJobStatus.UPLOADED,
                Instant.now().plus(15, ChronoUnit.MINUTES));
        uploadJobRepository.save(validJob).block();

        // Given - Expired upload job
        UploadJob expiredJob = createUploadJob("expired.jpg", UploadJobStatus.UPLOADED,
                Instant.now().minus(1, ChronoUnit.HOURS));
        uploadJobRepository.save(expiredJob).block();

        // Given - Wrong status
        UploadJob wrongStatusJob = createUploadJob("wrong.jpg", UploadJobStatus.INITIATED,
                Instant.now().plus(15, ChronoUnit.MINUTES));
        uploadJobRepository.save(wrongStatusJob).block();

        // Then
        assertThat(validJob.canBeConfirmed()).isTrue();
        assertThat(expiredJob.canBeConfirmed()).isFalse();
        assertThat(wrongStatusJob.canBeConfirmed()).isFalse();
    }

    @Test
    void shouldDeleteOldUploadJobs() {
        // Given
        Instant oldDate = Instant.now().minus(30, ChronoUnit.DAYS);
        UploadJob oldJob = createUploadJob("old.jpg", UploadJobStatus.CONFIRMED, oldDate);
        oldJob.setCreatedAt(oldDate);
        uploadJobRepository.save(oldJob).block();

        UploadJob recentJob = createAndSaveUploadJob("recent.jpg", UploadJobStatus.CONFIRMED);

        // When
        uploadJobRepository.deleteByCreatedAtBefore(Instant.now().minus(7, ChronoUnit.DAYS)).block();

        // Then
        StepVerifier.create(uploadJobRepository.count())
                .assertNext(count -> assertThat(count).isEqualTo(1))
                .verifyComplete();
    }

    private UploadJob createAndSaveUploadJob(String fileName, UploadJobStatus status) {
        UploadJob uploadJob = createUploadJob(fileName, status,
                Instant.now().plus(15, ChronoUnit.MINUTES));
        return uploadJobRepository.save(uploadJob).block();
    }

    private UploadJob createUploadJob(String fileName, UploadJobStatus status, Instant expiresAt) {
        UploadJob uploadJob = UploadJob.builder()
                .id(UUID.randomUUID())
                .userId(testUser.getId())
                .s3Key("originals/" + testUser.getId() + "/" + UUID.randomUUID())
                .presignedUrl("https://s3.example.com/presigned")
                .fileName(fileName)
                .fileSize(1024L * 1024L)
                .mimeType("image/jpeg")
                .status(status.name())
                .expiresAt(expiresAt)
                .build();
        return uploadJob;
    }
}
