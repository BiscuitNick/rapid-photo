package com.rapidphoto.repository;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoStatus;
import com.rapidphoto.domain.PhotoVersion;
import com.rapidphoto.domain.PhotoVersionType;
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

@DataR2dbcTest
@Testcontainers
class PhotoVersionRepositoryTest {

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
    private PhotoVersionRepository photoVersionRepository;

    @Autowired
    private PhotoRepository photoRepository;

    @Autowired
    private UploadJobRepository uploadJobRepository;

    @Autowired
    private UserRepository userRepository;

    private Photo savedPhoto;

    @BeforeEach
    void setUp() {
        photoVersionRepository.deleteAll().block();
        photoRepository.deleteAll().block();
        uploadJobRepository.deleteAll().block();
        userRepository.deleteAll().block();

        User user = User.builder()
                .id(UUID.randomUUID())
                .cognitoUserId("cognito-user")
                .email("test@example.com")
                .name("Test User")
                .lastLoginAt(Instant.now())
                .build();
        userRepository.insert(user).block();

        UploadJob uploadJob = UploadJob.builder()
                .id(UUID.randomUUID())
                .userId(user.getId())
                .s3Key("originals/" + user.getId() + "/photo.jpg")
                .presignedUrl("https://example.com/upload")
                .fileName("photo.jpg")
                .fileSize(2_000_000L)
                .mimeType("image/jpeg")
                .status(UploadJobStatus.CONFIRMED.name())
                .expiresAt(Instant.now().plus(1, ChronoUnit.HOURS))
                .build();
        uploadJobRepository.saveWithEnumCast(uploadJob).block();

        Photo photo = Photo.builder()
                .id(UUID.randomUUID())
                .userId(user.getId())
                .uploadJobId(uploadJob.getId())
                .originalS3Key(uploadJob.getS3Key())
                .fileName("photo.jpg")
                .fileSize(2_000_000L)
                .mimeType("image/jpeg")
                .status(PhotoStatus.PENDING_PROCESSING)
                .build();
        savedPhoto = photoRepository.saveWithEnumCast(photo).block();
    }

    @Test
    void shouldPersistVersionsWithMetadata() {
        PhotoVersion version = PhotoVersion.create(
                savedPhoto.getId(),
                PhotoVersionType.WEBP_640,
                "versions/" + savedPhoto.getId() + "/webp_640.webp",
                123_456L,
                640,
                360,
                "image/webp"
        );

        StepVerifier.create(photoVersionRepository.saveWithEnumCast(version)
                        .flatMap(saved -> photoVersionRepository.findByPhotoIdAndVersionType(
                                savedPhoto.getId(), PhotoVersionType.WEBP_640)))
                .assertNext(saved -> {
                    assertThat(saved.getPhotoId()).isEqualTo(savedPhoto.getId());
                    assertThat(saved.getVersionType()).isEqualTo(PhotoVersionType.WEBP_640);
                    assertThat(saved.getFileSize()).isEqualTo(123_456L);
                    assertThat(saved.getWidth()).isEqualTo(640);
                    assertThat(saved.getHeight()).isEqualTo(360);
                    assertThat(saved.getMimeType()).isEqualTo("image/webp");
                    assertThat(saved.getCreatedAt()).isNotNull();
                })
                .verifyComplete();
    }
}
