package com.rapidphoto.service;

import com.rapidphoto.domain.User;
import com.rapidphoto.repository.UserRepository;
import io.micrometer.observation.annotation.Observed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Service for managing User entities.
 * Demonstrates observability with @Observed annotations for automatic tracing and metrics.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    /**
     * Find or create a user from Cognito authentication.
     * Automatically creates user record if not exists.
     *
     * @Observed annotation creates:
     * - Distributed trace span with name "user.find-or-create"
     * - Timer metric measuring execution duration
     * - All configured common tags (application, environment, host)
     */
    @Observed(
            name = "user.find-or-create",
            contextualName = "find-or-create-user",
            lowCardinalityKeyValues = {"operation", "find-or-create"}
    )
    public Mono<User> findOrCreateUser(String cognitoUserId, String email, String name) {
        log.debug("Finding or creating user for Cognito ID: {}", cognitoUserId);

        return userRepository.findByCognitoUserId(cognitoUserId)
                .switchIfEmpty(
                        Mono.defer(() -> {
                            log.info("Creating new user for Cognito ID: {}", cognitoUserId);
                            User newUser = User.fromCognito(cognitoUserId, email, name);
                            return userRepository.save(newUser);
                        })
                )
                .doOnSuccess(user -> log.debug("User found/created with ID: {}", user.getId()))
                .doOnError(error -> log.error("Error finding/creating user: {}", error.getMessage()));
    }

    /**
     * Get user by ID.
     */
    @Observed(
            name = "user.get",
            contextualName = "get-user-by-id",
            lowCardinalityKeyValues = {"operation", "get"}
    )
    public Mono<User> getUserById(UUID userId) {
        log.debug("Getting user by ID: {}", userId);

        return userRepository.findById(userId)
                .doOnSuccess(user -> {
                    if (user != null) {
                        log.debug("User found with ID: {}", userId);
                    } else {
                        log.debug("User not found with ID: {}", userId);
                    }
                })
                .doOnError(error -> log.error("Error getting user: {}", error.getMessage()));
    }

    /**
     * Get user by Cognito user ID.
     */
    @Observed(
            name = "user.get-by-cognito-id",
            contextualName = "get-user-by-cognito-id",
            lowCardinalityKeyValues = {"operation", "get"}
    )
    public Mono<User> getUserByCognitoId(String cognitoUserId) {
        log.debug("Getting user by Cognito ID: {}", cognitoUserId);

        return userRepository.findByCognitoUserId(cognitoUserId)
                .doOnSuccess(user -> {
                    if (user != null) {
                        log.debug("User found for Cognito ID: {}", cognitoUserId);
                    } else {
                        log.debug("User not found for Cognito ID: {}", cognitoUserId);
                    }
                })
                .doOnError(error -> log.error("Error getting user by Cognito ID: {}", error.getMessage()));
    }

    /**
     * Update user storage usage.
     */
    @Observed(
            name = "user.update-storage",
            contextualName = "update-user-storage",
            lowCardinalityKeyValues = {"operation", "update"}
    )
    public Mono<User> updateStorageUsage(UUID userId, long deltaBytes) {
        log.debug("Updating storage for user {}: {} bytes", userId, deltaBytes);

        return userRepository.findById(userId)
                .flatMap(user -> {
                    user.updateStorageUsage(deltaBytes);
                    return userRepository.save(user);
                })
                .doOnSuccess(user ->
                        log.debug("Updated storage for user {}: {} bytes used", userId, user.getStorageUsedBytes()))
                .doOnError(error ->
                        log.error("Error updating storage for user {}: {}", userId, error.getMessage()));
    }

    /**
     * Record user login activity.
     */
    @Observed(
            name = "user.record-login",
            contextualName = "record-user-login",
            lowCardinalityKeyValues = {"operation", "update"}
    )
    public Mono<User> recordLogin(String cognitoUserId) {
        log.debug("Recording login for Cognito ID: {}", cognitoUserId);

        return userRepository.findByCognitoUserId(cognitoUserId)
                .flatMap(user -> {
                    user.recordLogin();
                    return userRepository.save(user);
                })
                .doOnSuccess(user ->
                        log.info("Recorded login for user {}", user.getId()))
                .doOnError(error ->
                        log.error("Error recording login: {}", error.getMessage()));
    }

    /**
     * Check if user has available storage quota.
     */
    @Observed(
            name = "user.check-storage",
            contextualName = "check-user-storage",
            lowCardinalityKeyValues = {"operation", "check"}
    )
    public Mono<Boolean> hasAvailableStorage(UUID userId, long requiredBytes) {
        log.debug("Checking storage availability for user {}: {} bytes required", userId, requiredBytes);

        return userRepository.findById(userId)
                .map(user -> user.hasAvailableStorage(requiredBytes))
                .defaultIfEmpty(false)
                .doOnSuccess(hasStorage ->
                        log.debug("User {} has storage: {}", userId, hasStorage))
                .doOnError(error ->
                        log.error("Error checking storage for user {}: {}", userId, error.getMessage()));
    }
}
