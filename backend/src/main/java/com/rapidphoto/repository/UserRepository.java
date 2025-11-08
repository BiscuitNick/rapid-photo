package com.rapidphoto.repository;

import com.rapidphoto.domain.User;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.UUID;

/**
 * Reactive repository for User aggregate.
 */
@Repository
public interface UserRepository extends ReactiveCrudRepository<User, UUID> {

    /**
     * Find user by Cognito user ID.
     */
    Mono<User> findByCognitoUserId(String cognitoUserId);

    /**
     * Find user by email.
     */
    Mono<User> findByEmail(String email);

    /**
     * Check if user exists by Cognito user ID.
     */
    Mono<Boolean> existsByCognitoUserId(String cognitoUserId);

    /**
     * Insert a new user with explicit UUID (needed for Cognito sub alignment).
     */
    @Query("INSERT INTO users (id, cognito_user_id, email, name, last_login_at, is_active, storage_quota_bytes, storage_used_bytes) " +
           "VALUES (:id, :cognitoUserId, :email, :name, :lastLoginAt, :isActive, :storageQuotaBytes, :storageUsedBytes)")
    Mono<Void> insertUser(UUID id, String cognitoUserId, String email, String name,
                          Instant lastLoginAt, Boolean isActive, Long storageQuotaBytes, Long storageUsedBytes);

    /**
     * Convenience method to insert and return the aggregate.
     */
    default Mono<User> insert(User user) {
        UUID id = user.getId() != null ? user.getId() : UUID.randomUUID();
        user.setId(id);

        return insertUser(
                id,
                user.getCognitoUserId(),
                user.getEmail(),
                user.getName(),
                user.getLastLoginAt(),
                user.getIsActive(),
                user.getStorageQuotaBytes(),
                user.getStorageUsedBytes()
        ).thenReturn(user);
    }
}
