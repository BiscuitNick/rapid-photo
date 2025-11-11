package com.rapidphoto.features.gallery;

import com.rapidphoto.domain.*;
import com.rapidphoto.domain.User;
import com.rapidphoto.features.gallery.api.dto.PagedPhotosResponse;
import com.rapidphoto.features.gallery.api.dto.PhotoResponse;
import com.rapidphoto.repository.*;
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

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for Gallery API endpoints.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
@Testcontainers
@ActiveProfiles("test")
class GalleryIntegrationTest {

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
    private PhotoRepository photoRepository;

    @Autowired
    private PhotoVersionRepository photoVersionRepository;

    @Autowired
    private PhotoLabelRepository photoLabelRepository;

    @Autowired
    private UserRepository userRepository;

    private UUID testUserId;
    private Photo testPhoto;

    @BeforeEach
    void setUp() {
        // Clean up database
        photoLabelRepository.deleteAll().block();
        photoVersionRepository.deleteAll().block();
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

        // Create test photo
        testPhoto = createTestPhoto(testUserId);
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldGetPhotos() {
        // When & Then
        webTestClient.get()
                .uri("/api/v1/photos?page=0&size=20")
                .exchange()
                .expectStatus().isOk()
                .expectHeader().exists("ETag")
                .expectBody(PagedPhotosResponse.class)
                .value(response -> {
                    assertThat(response.getContent()).hasSize(1);
                    assertThat(response.getPage()).isZero();
                    assertThat(response.getSize()).isEqualTo(20);
                    assertThat(response.getTotalElements()).isEqualTo(1);
                    assertThat(response.getTotalPages()).isEqualTo(1);
                    assertThat(response.isHasNext()).isFalse();
                    assertThat(response.isHasPrevious()).isFalse();

                    var photoItem = response.getContent().get(0);
                    assertThat(photoItem.getId()).isEqualTo(testPhoto.getId());
                    assertThat(photoItem.getFileName()).isEqualTo(testPhoto.getFileName());
                    assertThat(photoItem.getStatus()).isEqualTo(testPhoto.getStatusEnum());
                });
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldGetPhotoDetail() {
        // Create versions and labels for test photo
        PhotoVersion thumbnail = createTestVersion(testPhoto.getId(), PhotoVersionType.THUMBNAIL);
        PhotoLabel label = createTestLabel(testPhoto.getId(), "mountain", BigDecimal.valueOf(95.5));

        // When & Then
        webTestClient.get()
                .uri("/api/v1/photos/{photoId}", testPhoto.getId())
                .exchange()
                .expectStatus().isOk()
                .expectHeader().exists("ETag")
                .expectBody(PhotoResponse.class)
                .value(response -> {
                    assertThat(response.getId()).isEqualTo(testPhoto.getId());
                    assertThat(response.getFileName()).isEqualTo(testPhoto.getFileName());
                    assertThat(response.getStatus()).isEqualTo(testPhoto.getStatusEnum());
                    assertThat(response.getWidth()).isEqualTo(testPhoto.getWidth());
                    assertThat(response.getHeight()).isEqualTo(testPhoto.getHeight());
                    assertThat(response.getVersions()).hasSize(1);
                    assertThat(response.getLabels()).hasSize(1);
                    assertThat(response.getLabels().get(0).getLabelName()).isEqualTo("mountain");
                });
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldReturnNotFoundForNonexistentPhoto() {
        // Given
        UUID nonexistentPhotoId = UUID.randomUUID();

        // When & Then
        webTestClient.get()
                .uri("/api/v1/photos/{photoId}", nonexistentPhotoId)
                .exchange()
                .expectStatus().isNotFound();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldSearchPhotosByTags() {
        // Given - create photos with different labels
        PhotoLabel label1 = createTestLabel(testPhoto.getId(), "mountain", BigDecimal.valueOf(95));
        PhotoLabel label2 = createTestLabel(testPhoto.getId(), "landscape", BigDecimal.valueOf(90));

        Photo photo2 = createTestPhoto(testUserId);
        PhotoLabel label3 = createTestLabel(photo2.getId(), "city", BigDecimal.valueOf(85));

        // When & Then - search for "mountain"
        webTestClient.get()
                .uri("/api/v1/photos/search?tags=mountain&page=0&size=20")
                .exchange()
                .expectStatus().isOk()
                .expectBody(PagedPhotosResponse.class)
                .value(response -> {
                    assertThat(response.getContent()).hasSize(1);
                    assertThat(response.getContent().get(0).getId()).isEqualTo(testPhoto.getId());
                });

        // Search for "city"
        webTestClient.get()
                .uri("/api/v1/photos/search?tags=city&page=0&size=20")
                .exchange()
                .expectStatus().isOk()
                .expectBody(PagedPhotosResponse.class)
                .value(response -> {
                    assertThat(response.getContent()).hasSize(1);
                    assertThat(response.getContent().get(0).getId()).isEqualTo(photo2.getId());
                });
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldReturnEmptyForNonMatchingTags() {
        // Given
        createTestLabel(testPhoto.getId(), "mountain", BigDecimal.valueOf(95));

        // When & Then - search for non-existent tag
        webTestClient.get()
                .uri("/api/v1/photos/search?tags=beach&page=0&size=20")
                .exchange()
                .expectStatus().isOk()
                .expectBody(PagedPhotosResponse.class)
                .value(response -> {
                    assertThat(response.getContent()).isEmpty();
                    assertThat(response.getTotalElements()).isZero();
                });
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldDeletePhoto() {
        // Given
        createTestVersion(testPhoto.getId(), PhotoVersionType.THUMBNAIL);
        createTestLabel(testPhoto.getId(), "mountain", BigDecimal.valueOf(95));

        // When & Then
        webTestClient.delete()
                .uri("/api/v1/photos/{photoId}", testPhoto.getId())
                .exchange()
                .expectStatus().isNoContent();

        // Verify photo is deleted
        Photo deletedPhoto = photoRepository.findById(testPhoto.getId()).block();
        assertThat(deletedPhoto).isNull();

        // Verify versions and labels are also deleted
        Long versionCount = photoVersionRepository.countByPhotoId(testPhoto.getId()).block();
        Long labelCount = photoLabelRepository.countByPhotoId(testPhoto.getId()).block();
        assertThat(versionCount).isZero();
        assertThat(labelCount).isZero();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldReturnNotFoundWhenDeletingNonexistentPhoto() {
        // Given
        UUID nonexistentPhotoId = UUID.randomUUID();

        // When & Then
        webTestClient.delete()
                .uri("/api/v1/photos/{photoId}", nonexistentPhotoId)
                .exchange()
                .expectStatus().isNotFound();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldHandleETagCaching() {
        // First request - get ETag
        String etag = webTestClient.get()
                .uri("/api/v1/photos?page=0&size=20")
                .exchange()
                .expectStatus().isOk()
                .expectHeader().exists("ETag")
                .returnResult(PagedPhotosResponse.class)
                .getResponseHeaders()
                .getETag();

        assertThat(etag).isNotNull();

        // Second request with If-None-Match header
        webTestClient.get()
                .uri("/api/v1/photos?page=0&size=20")
                .header("If-None-Match", etag)
                .exchange()
                .expectStatus().isNotModified();
    }

    @Test
    @WithMockUser(username = "test-user")
    void shouldHandlePagination() {
        // Create multiple photos
        for (int i = 0; i < 25; i++) {
            createTestPhoto(testUserId);
        }

        // First page
        webTestClient.get()
                .uri("/api/v1/photos?page=0&size=20")
                .exchange()
                .expectStatus().isOk()
                .expectBody(PagedPhotosResponse.class)
                .value(response -> {
                    assertThat(response.getContent()).hasSize(20);
                    assertThat(response.getPage()).isZero();
                    assertThat(response.getTotalElements()).isEqualTo(26); // 25 + initial test photo
                    assertThat(response.getTotalPages()).isEqualTo(2);
                    assertThat(response.isHasNext()).isTrue();
                    assertThat(response.isHasPrevious()).isFalse();
                });

        // Second page
        webTestClient.get()
                .uri("/api/v1/photos?page=1&size=20")
                .exchange()
                .expectStatus().isOk()
                .expectBody(PagedPhotosResponse.class)
                .value(response -> {
                    assertThat(response.getContent()).hasSize(6);
                    assertThat(response.getPage()).isEqualTo(1);
                    assertThat(response.isHasNext()).isFalse();
                    assertThat(response.isHasPrevious()).isTrue();
                });
    }

    private Photo createTestPhoto(UUID userId) {
        Photo photo = Photo.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .uploadJobId(UUID.randomUUID())
                .originalS3Key("originals/" + userId + "/" + UUID.randomUUID())
                .fileName("test-image-" + UUID.randomUUID() + ".jpg")
                .fileSize(1024L * 1024L)
                .mimeType("image/jpeg")
                .width(1920)
                .height(1080)
                .status(PhotoStatus.READY)
                .createdAt(Instant.now())
                .processedAt(Instant.now())
                .build();

        return photoRepository.saveWithEnumCast(photo).block();
    }

    private PhotoVersion createTestVersion(UUID photoId, PhotoVersionType versionType) {
        PhotoVersion version = PhotoVersion.builder()
                .photoId(photoId)
                .versionType(versionType)
                .s3Key("versions/" + photoId + "/" + versionType.name().toLowerCase())
                .fileSize(512L * 1024L)
                .width(versionType == PhotoVersionType.THUMBNAIL ? 300 : 1280)
                .height(versionType == PhotoVersionType.THUMBNAIL ? 300 : 720)
                .mimeType("image/webp")
                .build();

        return photoVersionRepository.save(version).block();
    }

    private PhotoLabel createTestLabel(UUID photoId, String labelName, BigDecimal confidence) {
        PhotoLabel label = PhotoLabel.builder()
                .photoId(photoId)
                .labelName(labelName)
                .confidence(confidence)
                .build();

        return photoLabelRepository.save(label).block();
    }
}
