package com.rapidphoto.repository;

import com.rapidphoto.domain.User;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

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
}
