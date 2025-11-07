package com.rapidphoto.repository;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoStatus;
import com.rapidphoto.domain.UploadJob;
import com.rapidphoto.domain.UploadJobStatus;
import com.rapidphoto.domain.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.r2dbc.DataR2dbcTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import reactor.test.StepVerifier;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for PhotoRepository using Testcontainers.
 */
@DataR2dbcTest
@Testcontainers
class PhotoRepositoryTest {

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
    private PhotoRepository photoRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UploadJobRepository uploadJobRepository;

    private User testUser;
    private UploadJob testUploadJob;

    @BeforeEach
    void setUp() {
        // Clean up and create test data
        photoRepository.deleteAll().block();
        uploadJobRepository.deleteAll().block();
        userRepository.deleteAll().block();

        // Create test user
        testUser = User.builder()
                .id(UUID.randomUUID())
                .cognitoUserId("test-cognito-123")
                .email("test@example.com")
                .name("Test User")
                .build();
        testUser = userRepository.save(testUser).block();

        // Create test upload job
        testUploadJob = UploadJob.builder()
                .id(UUID.randomUUID())
                .userId(testUser.getId())
                .s3Key("originals/" + testUser.getId() + "/" + UUID.randomUUID())
                .presignedUrl("https://s3.example.com/presigned")
                .fileName("test-photo.jpg")
                .fileSize(1024L * 1024L)
                .mimeType("image/jpeg")
                .status(UploadJobStatus.CONFIRMED)
                .expiresAt(Instant.now().plus(1, ChronoUnit.HOURS))
                .build();
        testUploadJob = uploadJobRepository.save(testUploadJob).block();
    }

    @Test
    void shouldSaveAndFindPhoto() {
        // Given
        Photo photo = Photo.builder()
                .id(UUID.randomUUID())
                .userId(testUser.getId())
                .uploadJobId(testUploadJob.getId())
                .originalS3Key(testUploadJob.getS3Key())
                .fileName("test-photo.jpg")
                .fileSize(1024L * 1024L)
                .mimeType("image/jpeg")
                .status(PhotoStatus.PENDING_PROCESSING)
                .build();

        // When & Then
        StepVerifier.create(photoRepository.save(photo))
                .assertNext(saved -> {
                    assertThat(saved.getId()).isNotNull();
                    assertThat(saved.getUserId()).isEqualTo(testUser.getId());
                    assertThat(saved.getStatus()).isEqualTo(PhotoStatus.PENDING_PROCESSING);
                })
                .verifyComplete();
    }

    @Test
    void shouldFindPhotosByUserIdOrderedByCreatedAt() {
        // Given
        Photo photo1 = createAndSavePhoto("photo1.jpg", PhotoStatus.READY);
        Photo photo2 = createAndSavePhoto("photo2.jpg", PhotoStatus.READY);
        Photo photo3 = createAndSavePhoto("photo3.jpg", PhotoStatus.READY);

        // When & Then
        StepVerifier.create(photoRepository.findByUserIdOrderByCreatedAtDesc(
                        testUser.getId(), PageRequest.of(0, 10)))
                .assertNext(photo -> assertThat(photo.getFileName()).isEqualTo("photo3.jpg"))
                .assertNext(photo -> assertThat(photo.getFileName()).isEqualTo("photo2.jpg"))
                .assertNext(photo -> assertThat(photo.getFileName()).isEqualTo("photo1.jpg"))
                .verifyComplete();
    }

    @Test
    void shouldFindPhotoByIdAndUserId() {
        // Given
        Photo photo = createAndSavePhoto("test.jpg", PhotoStatus.READY);

        // When & Then
        StepVerifier.create(photoRepository.findByIdAndUserId(photo.getId(), testUser.getId()))
                .assertNext(found -> {
                    assertThat(found.getId()).isEqualTo(photo.getId());
                    assertThat(found.getUserId()).isEqualTo(testUser.getId());
                })
                .verifyComplete();
    }

    @Test
    void shouldNotFindPhotoWithWrongUserId() {
        // Given
        Photo photo = createAndSavePhoto("test.jpg", PhotoStatus.READY);
        UUID wrongUserId = UUID.randomUUID();

        // When & Then
        StepVerifier.create(photoRepository.findByIdAndUserId(photo.getId(), wrongUserId))
                .verifyComplete();
    }

    @Test
    void shouldCountPhotosByUserId() {
        // Given
        createAndSavePhoto("photo1.jpg", PhotoStatus.READY);
        createAndSavePhoto("photo2.jpg", PhotoStatus.READY);
        createAndSavePhoto("photo3.jpg", PhotoStatus.PENDING_PROCESSING);

        // When & Then
        StepVerifier.create(photoRepository.countByUserId(testUser.getId()))
                .assertNext(count -> assertThat(count).isEqualTo(3))
                .verifyComplete();
    }

    @Test
    void shouldCountPhotosByUserIdAndStatus() {
        // Given
        createAndSavePhoto("photo1.jpg", PhotoStatus.READY);
        createAndSavePhoto("photo2.jpg", PhotoStatus.READY);
        createAndSavePhoto("photo3.jpg", PhotoStatus.PENDING_PROCESSING);

        // When & Then
        StepVerifier.create(photoRepository.countByUserIdAndStatus(testUser.getId(), PhotoStatus.READY))
                .assertNext(count -> assertThat(count).isEqualTo(2))
                .verifyComplete();
    }

    @Test
    void shouldFindPhotoByUploadJobId() {
        // Given
        Photo photo = createAndSavePhoto("test.jpg", PhotoStatus.READY);

        // When & Then
        StepVerifier.create(photoRepository.findByUploadJobId(testUploadJob.getId()))
                .assertNext(found -> {
                    assertThat(found.getUploadJobId()).isEqualTo(testUploadJob.getId());
                    assertThat(found.getFileName()).isEqualTo("test.jpg");
                })
                .verifyComplete();
    }

    @Test
    void shouldFindPhotosByStatus() {
        // Given
        createAndSavePhoto("photo1.jpg", PhotoStatus.PENDING_PROCESSING);
        createAndSavePhoto("photo2.jpg", PhotoStatus.READY);
        createAndSavePhoto("photo3.jpg", PhotoStatus.PENDING_PROCESSING);

        // When & Then
        StepVerifier.create(photoRepository.findByStatusOrderByCreatedAtAsc(PhotoStatus.PENDING_PROCESSING))
                .expectNextCount(2)
                .verifyComplete();
    }

    @Test
    void shouldFindPhotosWithGpsCoordinates() {
        // Given
        Photo photoWithGps = createAndSavePhoto("with-gps.jpg", PhotoStatus.READY);
        photoWithGps.updateGpsCoordinates(
                new BigDecimal("37.7749"),
                new BigDecimal("-122.4194")
        );
        photoRepository.save(photoWithGps).block();

        Photo photoWithoutGps = createAndSavePhoto("no-gps.jpg", PhotoStatus.READY);

        // When & Then
        StepVerifier.create(photoRepository.findByUserIdWithGpsCoordinates(
                        testUser.getId(), PageRequest.of(0, 10)))
                .assertNext(found -> {
                    assertThat(found.getFileName()).isEqualTo("with-gps.jpg");
                    assertThat(found.hasGpsCoordinates()).isTrue();
                })
                .verifyComplete();
    }

    @Test
    void shouldFindPhotosByTakenAtDateRange() {
        // Given
        Instant now = Instant.now();
        Photo photo1 = createAndSavePhoto("photo1.jpg", PhotoStatus.READY);
        photo1.updateExifMetadata(now.minus(10, ChronoUnit.DAYS), "Canon", "EOS R5");
        photoRepository.save(photo1).block();

        Photo photo2 = createAndSavePhoto("photo2.jpg", PhotoStatus.READY);
        photo2.updateExifMetadata(now.minus(5, ChronoUnit.DAYS), "Sony", "A7III");
        photoRepository.save(photo2).block();

        Photo photo3 = createAndSavePhoto("photo3.jpg", PhotoStatus.READY);
        photo3.updateExifMetadata(now.minus(1, ChronoUnit.DAYS), "Nikon", "Z6");
        photoRepository.save(photo3).block();

        // When & Then - Find photos from last 7 days
        Instant startDate = now.minus(7, ChronoUnit.DAYS);
        Instant endDate = now;

        StepVerifier.create(photoRepository.findByUserIdAndTakenAtBetween(
                        testUser.getId(), startDate, endDate, PageRequest.of(0, 10)))
                .expectNextCount(2)
                .verifyComplete();
    }

    @Test
    void shouldUpdatePhotoStatus() {
        // Given
        Photo photo = createAndSavePhoto("test.jpg", PhotoStatus.PENDING_PROCESSING);

        // When
        photo.markReady(1920, 1080);
        Photo updated = photoRepository.save(photo).block();

        // Then
        StepVerifier.create(photoRepository.findById(photo.getId()))
                .assertNext(found -> {
                    assertThat(found.getStatus()).isEqualTo(PhotoStatus.READY);
                    assertThat(found.getWidth()).isEqualTo(1920);
                    assertThat(found.getHeight()).isEqualTo(1080);
                    assertThat(found.getProcessedAt()).isNotNull();
                })
                .verifyComplete();
    }

    @Test
    void shouldDeletePhotosByUserId() {
        // Given
        createAndSavePhoto("photo1.jpg", PhotoStatus.READY);
        createAndSavePhoto("photo2.jpg", PhotoStatus.READY);

        // When
        photoRepository.deleteByUserId(testUser.getId()).block();

        // Then
        StepVerifier.create(photoRepository.countByUserId(testUser.getId()))
                .assertNext(count -> assertThat(count).isEqualTo(0))
                .verifyComplete();
    }

    private Photo createAndSavePhoto(String fileName, PhotoStatus status) {
        Photo photo = Photo.builder()
                .id(UUID.randomUUID())
                .userId(testUser.getId())
                .uploadJobId(testUploadJob.getId())
                .originalS3Key("originals/" + testUser.getId() + "/" + UUID.randomUUID())
                .fileName(fileName)
                .fileSize(1024L * 1024L)
                .mimeType("image/jpeg")
                .status(status)
                .build();
        return photoRepository.save(photo).block();
    }
}
