package com.rapidphoto.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Utility class for extracting security context information in reactive flows.
 * Provides convenient methods to access current user details from JWT tokens.
 */
public class SecurityContextUtils {

    /**
     * Get the current authenticated user's Cognito user ID (sub claim).
     * This is the unique identifier for the user from Cognito.
     */
    public static Mono<String> getCurrentCognitoUserId() {
        return getAuthentication()
                .map(Authentication::getPrincipal)
                .cast(String.class);
    }

    /**
     * Get the current authenticated user's UUID from the database.
     * This assumes the principal is set to the user's UUID during authentication.
     * For Cognito, this will be the sub claim which can be used to lookup the User entity.
     */
    public static Mono<UUID> getCurrentUserId() {
        return getCurrentCognitoUserId()
                .map(UUID::fromString)
                .onErrorResume(IllegalArgumentException.class, e ->
                        Mono.error(new SecurityException("Invalid user ID format in authentication token")));
    }

    /**
     * Get the JWT token from the current authentication.
     */
    public static Mono<Jwt> getCurrentJwt() {
        return getAuthentication()
                .filter(auth -> auth instanceof JwtAuthenticationToken)
                .map(auth -> ((JwtAuthenticationToken) auth).getToken());
    }

    /**
     * Get the email claim from the current JWT token.
     */
    public static Mono<String> getCurrentUserEmail() {
        return getCurrentJwt()
                .map(jwt -> jwt.getClaimAsString("email"));
    }

    /**
     * Get the name claim from the current JWT token.
     */
    public static Mono<String> getCurrentUserName() {
        return getCurrentJwt()
                .map(jwt -> jwt.getClaimAsString("name"));
    }

    /**
     * Get the cognito:username claim from the current JWT token.
     */
    public static Mono<String> getCurrentCognitoUsername() {
        return getCurrentJwt()
                .map(jwt -> jwt.getClaimAsString("cognito:username"));
    }

    /**
     * Get the current Authentication object.
     */
    private static Mono<Authentication> getAuthentication() {
        return ReactiveSecurityContextHolder.getContext()
                .map(org.springframework.security.core.context.SecurityContext::getAuthentication)
                .filter(Authentication::isAuthenticated);
    }

    /**
     * Check if the current user has a specific authority/role.
     */
    public static Mono<Boolean> hasAuthority(String authority) {
        return getAuthentication()
                .map(auth -> auth.getAuthorities().stream()
                        .anyMatch(grantedAuthority -> grantedAuthority.getAuthority().equals(authority)))
                .defaultIfEmpty(false);
    }

    /**
     * Check if the current user has a specific role.
     * Automatically adds ROLE_ prefix if not present.
     */
    public static Mono<Boolean> hasRole(String role) {
        String authority = role.startsWith("ROLE_") ? role : "ROLE_" + role;
        return hasAuthority(authority);
    }
}
