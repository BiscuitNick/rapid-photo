package com.rapidphoto.repository;

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

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for UserRepository using Testcontainers.
 */
@DataR2dbcTest
@Testcontainers
class UserRepositoryTest {

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
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll().block();
    }

    @Test
    void shouldSaveAndFindUser() {
        // Given
        User user = User.builder()
                .id(UUID.randomUUID())
                .cognitoUserId("cognito-123")
                .email("test@example.com")
                .name("Test User")
                .build();

        // When & Then
        StepVerifier.create(userRepository.save(user))
                .assertNext(saved -> {
                    assertThat(saved.getId()).isNotNull();
                    assertThat(saved.getCognitoUserId()).isEqualTo("cognito-123");
                    assertThat(saved.getEmail()).isEqualTo("test@example.com");
                    assertThat(saved.getIsActive()).isTrue();
                    assertThat(saved.getStorageQuotaBytes()).isEqualTo(10737418240L);
                    assertThat(saved.getStorageUsedBytes()).isEqualTo(0L);
                })
                .verifyComplete();
    }

    @Test
    void shouldFindUserByCognitoUserId() {
        // Given
        User user = createAndSaveUser("cognito-123", "test@example.com");

        // When & Then
        StepVerifier.create(userRepository.findByCognitoUserId("cognito-123"))
                .assertNext(found -> {
                    assertThat(found.getId()).isEqualTo(user.getId());
                    assertThat(found.getEmail()).isEqualTo("test@example.com");
                })
                .verifyComplete();
    }

    @Test
    void shouldFindUserByEmail() {
        // Given
        User user = createAndSaveUser("cognito-123", "test@example.com");

        // When & Then
        StepVerifier.create(userRepository.findByEmail("test@example.com"))
                .assertNext(found -> {
                    assertThat(found.getId()).isEqualTo(user.getId());
                    assertThat(found.getCognitoUserId()).isEqualTo("cognito-123");
                })
                .verifyComplete();
    }

    @Test
    void shouldCheckIfUserExistsByCognitoUserId() {
        // Given
        createAndSaveUser("cognito-123", "test@example.com");

        // When & Then - exists
        StepVerifier.create(userRepository.existsByCognitoUserId("cognito-123"))
                .assertNext(exists -> assertThat(exists).isTrue())
                .verifyComplete();

        // When & Then - does not exist
        StepVerifier.create(userRepository.existsByCognitoUserId("non-existent"))
                .assertNext(exists -> assertThat(exists).isFalse())
                .verifyComplete();
    }

    @Test
    void shouldCreateUserFromCognito() {
        // Given
        User user = User.fromCognito("cognito-456", "user@example.com", "New User");

        // When
        User saved = userRepository.save(user).block();

        // Then
        StepVerifier.create(userRepository.findById(saved.getId()))
                .assertNext(found -> {
                    assertThat(found.getCognitoUserId()).isEqualTo("cognito-456");
                    assertThat(found.getEmail()).isEqualTo("user@example.com");
                    assertThat(found.getName()).isEqualTo("New User");
                    assertThat(found.getLastLoginAt()).isNotNull();
                })
                .verifyComplete();
    }

    @Test
    void shouldUpdateStorageUsage() {
        // Given
        User user = createAndSaveUser("cognito-123", "test@example.com");

        // When
        user.updateStorageUsage(1024L * 1024L * 100L); // Add 100MB
        User updated = userRepository.save(user).block();

        // Then
        StepVerifier.create(userRepository.findById(user.getId()))
                .assertNext(found -> {
                    assertThat(found.getStorageUsedBytes()).isEqualTo(1024L * 1024L * 100L);
                })
                .verifyComplete();
    }

    @Test
    void shouldCheckAvailableStorage() {
        // Given
        User user = createAndSaveUser("cognito-123", "test@example.com");
        user.updateStorageUsage(1024L * 1024L * 1024L * 9L); // Use 9GB
        userRepository.save(user).block();

        // When & Then - has space for 1GB
        assertThat(user.hasAvailableStorage(1024L * 1024L * 1024L)).isTrue();

        // When & Then - does not have space for 2GB
        assertThat(user.hasAvailableStorage(1024L * 1024L * 1024L * 2L)).isFalse();
    }

    @Test
    void shouldRecordLogin() {
        // Given
        User user = createAndSaveUser("cognito-123", "test@example.com");

        // When
        user.recordLogin();
        User updated = userRepository.save(user).block();

        // Then
        StepVerifier.create(userRepository.findById(user.getId()))
                .assertNext(found -> {
                    assertThat(found.getLastLoginAt()).isNotNull();
                })
                .verifyComplete();
    }

    @Test
    void shouldUpdateStorageUsageNegativeDelta() {
        // Given
        User user = createAndSaveUser("cognito-123", "test@example.com");
        user.updateStorageUsage(1024L * 1024L * 100L); // Add 100MB
        userRepository.save(user).block();

        // When - Remove 50MB
        user.updateStorageUsage(-1024L * 1024L * 50L);
        User updated = userRepository.save(user).block();

        // Then
        StepVerifier.create(userRepository.findById(user.getId()))
                .assertNext(found -> {
                    assertThat(found.getStorageUsedBytes()).isEqualTo(1024L * 1024L * 50L);
                })
                .verifyComplete();
    }

    @Test
    void shouldNotAllowNegativeStorageUsed() {
        // Given
        User user = createAndSaveUser("cognito-123", "test@example.com");

        // When - Try to remove more than available
        user.updateStorageUsage(-1024L);
        User updated = userRepository.save(user).block();

        // Then - Should be clamped to 0
        StepVerifier.create(userRepository.findById(user.getId()))
                .assertNext(found -> {
                    assertThat(found.getStorageUsedBytes()).isEqualTo(0L);
                })
                .verifyComplete();
    }

    private User createAndSaveUser(String cognitoUserId, String email) {
        User user = User.builder()
                .id(UUID.randomUUID())
                .cognitoUserId(cognitoUserId)
                .email(email)
                .name("Test User")
                .build();
        return userRepository.save(user).block();
    }
}
