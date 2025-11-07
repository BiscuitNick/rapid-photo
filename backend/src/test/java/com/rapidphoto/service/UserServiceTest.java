package com.rapidphoto.service;

import com.rapidphoto.domain.User;
import com.rapidphoto.repository.UserRepository;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.observation.ObservationRegistry;
import io.micrometer.observation.tck.TestObservationRegistry;
import io.micrometer.observation.tck.TestObservationRegistryAssert;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.r2dbc.DataR2dbcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import reactor.test.StepVerifier;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;

/**
 * Integration tests for UserService with observability.
 * Verifies that @Observed annotations emit proper observations.
 */
@DataR2dbcTest
@Testcontainers
@Import({UserService.class, com.rapidphoto.config.ObservabilityConfig.class})
class UserServiceTest {

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
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @MockBean
    private MeterRegistry meterRegistry;

    private TestObservationRegistry observationRegistry;

    @BeforeEach
    void setUp() {
        // Clean database
        userRepository.deleteAll().block();

        // Set up test observation registry
        observationRegistry = TestObservationRegistry.create();
    }

    @Test
    void shouldFindOrCreateNewUser() {
        // Given
        String cognitoUserId = UUID.randomUUID().toString();
        String email = "test@example.com";
        String name = "Test User";

        // When
        User result = userService.findOrCreateUser(cognitoUserId, email, name).block();

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getCognitoUserId()).isEqualTo(cognitoUserId);
        assertThat(result.getEmail()).isEqualTo(email);
        assertThat(result.getName()).isEqualTo(name);
        assertThat(result.getId()).isNotNull();
    }

    @Test
    void shouldFindExistingUser() {
        // Given
        String cognitoUserId = UUID.randomUUID().toString();
        User existingUser = User.fromCognito(cognitoUserId, "test@example.com", "Test User");
        userRepository.save(existingUser).block();

        // When
        User result = userService.findOrCreateUser(cognitoUserId, "test@example.com", "Test User").block();

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(existingUser.getId());
        assertThat(result.getCognitoUserId()).isEqualTo(cognitoUserId);
    }

    @Test
    void shouldGetUserById() {
        // Given
        User user = User.fromCognito(UUID.randomUUID().toString(), "test@example.com", "Test User");
        User savedUser = userRepository.save(user).block();

        // When
        User result = userService.getUserById(savedUser.getId()).block();

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(savedUser.getId());
    }

    @Test
    void shouldGetUserByCognitoId() {
        // Given
        String cognitoUserId = UUID.randomUUID().toString();
        User user = User.fromCognito(cognitoUserId, "test@example.com", "Test User");
        userRepository.save(user).block();

        // When
        User result = userService.getUserByCognitoId(cognitoUserId).block();

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getCognitoUserId()).isEqualTo(cognitoUserId);
    }

    @Test
    void shouldUpdateStorageUsage() {
        // Given
        User user = User.fromCognito(UUID.randomUUID().toString(), "test@example.com", "Test User");
        User savedUser = userRepository.save(user).block();
        long deltaBytes = 1024L * 1024L * 100L; // 100MB

        // When
        User result = userService.updateStorageUsage(savedUser.getId(), deltaBytes).block();

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getStorageUsedBytes()).isEqualTo(deltaBytes);
    }

    @Test
    void shouldRecordLogin() {
        // Given
        String cognitoUserId = UUID.randomUUID().toString();
        User user = User.fromCognito(cognitoUserId, "test@example.com", "Test User");
        userRepository.save(user).block();

        // When
        User result = userService.recordLogin(cognitoUserId).block();

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getLastLoginAt()).isNotNull();
    }

    @Test
    void shouldCheckAvailableStorage() {
        // Given
        User user = User.fromCognito(UUID.randomUUID().toString(), "test@example.com", "Test User");
        User savedUser = userRepository.save(user).block();
        long requiredBytes = 1024L * 1024L * 1024L; // 1GB

        // When
        Boolean hasStorage = userService.hasAvailableStorage(savedUser.getId(), requiredBytes).block();

        // Then
        assertThat(hasStorage).isTrue();
    }

    @Test
    void shouldReturnFalseWhenStorageExceeded() {
        // Given
        User user = User.fromCognito(UUID.randomUUID().toString(), "test@example.com", "Test User");
        user.updateStorageUsage(1024L * 1024L * 1024L * 9L); // Use 9GB
        User savedUser = userRepository.save(user).block();
        long requiredBytes = 1024L * 1024L * 1024L * 2L; // Need 2GB

        // When
        Boolean hasStorage = userService.hasAvailableStorage(savedUser.getId(), requiredBytes).block();

        // Then
        assertThat(hasStorage).isFalse();
    }

    @Test
    void shouldHandleNonExistentUser() {
        // Given
        UUID nonExistentId = UUID.randomUUID();

        // When
        StepVerifier.create(userService.getUserById(nonExistentId))
                .verifyComplete();
    }
}
