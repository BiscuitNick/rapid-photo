package com.rapidphoto.security;

import org.junit.jupiter.api.Test;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextImpl;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for SecurityContextUtils.
 */
class SecurityContextUtilsTest {

    @Test
    void shouldExtractCognitoUserIdFromSecurityContext() {
        // Given
        String cognitoUserId = UUID.randomUUID().toString();
        Mono<String> result = withMockSecurityContext(cognitoUserId, "test@example.com", "Test User")
                .flatMap(ctx -> SecurityContextUtils.getCurrentCognitoUserId());

        // When & Then
        StepVerifier.create(result)
                .assertNext(userId -> assertThat(userId).isEqualTo(cognitoUserId))
                .verifyComplete();
    }

    @Test
    void shouldExtractUserEmailFromJwt() {
        // Given
        String email = "test@example.com";
        Mono<String> result = withMockSecurityContext(UUID.randomUUID().toString(), email, "Test User")
                .flatMap(ctx -> SecurityContextUtils.getCurrentUserEmail());

        // When & Then
        StepVerifier.create(result)
                .assertNext(userEmail -> assertThat(userEmail).isEqualTo(email))
                .verifyComplete();
    }

    @Test
    void shouldExtractUserNameFromJwt() {
        // Given
        String name = "Test User";
        Mono<String> result = withMockSecurityContext(UUID.randomUUID().toString(), "test@example.com", name)
                .flatMap(ctx -> SecurityContextUtils.getCurrentUserName());

        // When & Then
        StepVerifier.create(result)
                .assertNext(userName -> assertThat(userName).isEqualTo(name))
                .verifyComplete();
    }

    @Test
    void shouldExtractCognitoUsernameFromJwt() {
        // Given
        String username = "testuser";
        Map<String, Object> claims = new HashMap<>();
        claims.put("sub", UUID.randomUUID().toString());
        claims.put("email", "test@example.com");
        claims.put("name", "Test User");
        claims.put("cognito:username", username);

        Mono<String> result = withMockSecurityContext(claims)
                .flatMap(ctx -> SecurityContextUtils.getCurrentCognitoUsername());

        // When & Then
        StepVerifier.create(result)
                .assertNext(cognitoUsername -> assertThat(cognitoUsername).isEqualTo(username))
                .verifyComplete();
    }

    @Test
    void shouldCheckIfUserHasRole() {
        // Given
        Map<String, Object> claims = new HashMap<>();
        claims.put("sub", UUID.randomUUID().toString());
        claims.put("email", "admin@example.com");
        claims.put("cognito:groups", List.of("ADMIN", "USER"));

        Mono<Boolean> result = withMockSecurityContext(claims, List.of("ROLE_ADMIN", "ROLE_USER"))
                .flatMap(ctx -> SecurityContextUtils.hasRole("ADMIN"));

        // When & Then
        StepVerifier.create(result)
                .assertNext(hasRole -> assertThat(hasRole).isTrue())
                .verifyComplete();
    }

    @Test
    void shouldReturnFalseIfUserDoesNotHaveRole() {
        // Given
        Map<String, Object> claims = new HashMap<>();
        claims.put("sub", UUID.randomUUID().toString());
        claims.put("email", "user@example.com");

        Mono<Boolean> result = withMockSecurityContext(claims, List.of("ROLE_USER"))
                .flatMap(ctx -> SecurityContextUtils.hasRole("ADMIN"));

        // When & Then
        StepVerifier.create(result)
                .assertNext(hasRole -> assertThat(hasRole).isFalse())
                .verifyComplete();
    }

    @Test
    void shouldCheckIfUserHasAuthority() {
        // Given
        Map<String, Object> claims = new HashMap<>();
        claims.put("sub", UUID.randomUUID().toString());
        claims.put("email", "user@example.com");

        Mono<Boolean> result = withMockSecurityContext(claims, List.of("ROLE_USER"))
                .flatMap(ctx -> SecurityContextUtils.hasAuthority("ROLE_USER"));

        // When & Then
        StepVerifier.create(result)
                .assertNext(hasAuthority -> assertThat(hasAuthority).isTrue())
                .verifyComplete();
    }

    @Test
    void shouldReturnEmptyWhenNoSecurityContext() {
        // When & Then
        StepVerifier.create(SecurityContextUtils.getCurrentCognitoUserId())
                .verifyComplete();
    }

    /**
     * Helper method to create a mock security context with JWT authentication.
     */
    private Mono<SecurityContext> withMockSecurityContext(String cognitoUserId, String email, String name) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("sub", cognitoUserId);
        claims.put("email", email);
        claims.put("name", name);
        claims.put("cognito:username", email.split("@")[0]);

        return withMockSecurityContext(claims, List.of("ROLE_USER"));
    }

    /**
     * Helper method to create a mock security context with custom claims.
     */
    private Mono<SecurityContext> withMockSecurityContext(Map<String, Object> claims) {
        return withMockSecurityContext(claims, List.of("ROLE_USER"));
    }

    /**
     * Helper method to create a mock security context with custom claims and authorities.
     */
    private Mono<SecurityContext> withMockSecurityContext(Map<String, Object> claims, List<String> authorities) {
        Jwt jwt = Jwt.withTokenValue("mock-token")
                .header("alg", "RS256")
                .claims(c -> c.putAll(claims))
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();

        List<SimpleGrantedAuthority> grantedAuthorities = authorities.stream()
                .map(SimpleGrantedAuthority::new)
                .toList();

        Authentication authentication = new JwtAuthenticationToken(
                jwt,
                grantedAuthorities,
                claims.get("sub").toString()
        );

        SecurityContext securityContext = new SecurityContextImpl(authentication);

        return Mono.just(securityContext)
                .contextWrite(ReactiveSecurityContextHolder.withSecurityContext(Mono.just(securityContext)));
    }
}
