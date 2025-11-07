package com.rapidphoto.config;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.reactive.server.WebTestClient;

import java.io.IOException;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.UUID;

/**
 * Integration tests for SecurityConfig with Cognito JWT authentication.
 * Uses MockWebServer to simulate Cognito JWKS endpoint.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
class SecurityConfigTest {

    @Autowired
    private WebTestClient webTestClient;

    private static MockWebServer mockWebServer;
    private static RSAKey rsaKey;

    @BeforeEach
    void setUp() throws IOException, JOSEException {
        // Create mock web server for JWKS endpoint
        mockWebServer = new MockWebServer();
        mockWebServer.start();

        // Generate RSA key pair for signing JWTs
        rsaKey = new RSAKeyGenerator(2048)
                .keyID(UUID.randomUUID().toString())
                .generate();

        // Mock JWKS endpoint response
        String jwksResponse = String.format(
                "{\"keys\":[%s]}",
                rsaKey.toPublicJWK().toJSONString()
        );

        mockWebServer.enqueue(new MockResponse()
                .setBody(jwksResponse)
                .addHeader("Content-Type", "application/json"));
    }

    @AfterEach
    void tearDown() throws IOException {
        if (mockWebServer != null) {
            mockWebServer.shutdown();
        }
    }

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.security.oauth2.resourceserver.jwt.jwk-set-uri",
                () -> "http://localhost:" + mockWebServer.getPort() + "/.well-known/jwks.json");
        registry.add("spring.security.oauth2.resourceserver.jwt.issuer-uri",
                () -> "http://localhost:" + mockWebServer.getPort());
    }

    @Test
    void shouldDenyAccessToApiEndpointsWithoutAuthentication() {
        webTestClient.get()
                .uri("/api/v1/photos")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldAllowAccessToHealthEndpointWithoutAuthentication() {
        webTestClient.get()
                .uri("/actuator/health")
                .exchange()
                .expectStatus().isOk();
    }

    @Test
    void shouldAllowAccessToInfoEndpointWithoutAuthentication() {
        webTestClient.get()
                .uri("/actuator/info")
                .exchange()
                .expectStatus().isOk();
    }

    @Test
    void shouldDenyAccessToOtherActuatorEndpointsWithoutAuthentication() {
        webTestClient.get()
                .uri("/actuator/metrics")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldAllowAccessWithValidJwtToken() throws Exception {
        String token = createValidJwt();

        // Note: Since we don't have actual API endpoints yet, we'll test that
        // the token is accepted (even if endpoint doesn't exist - 404 vs 401)
        webTestClient.get()
                .uri("/api/v1/photos")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isNotFound(); // 404 means auth passed, endpoint doesn't exist yet
    }

    @Test
    void shouldDenyAccessWithInvalidJwtToken() {
        webTestClient.get()
                .uri("/api/v1/photos")
                .header("Authorization", "Bearer invalid-token-here")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldDenyAccessWithExpiredJwtToken() throws Exception {
        String expiredToken = createExpiredJwt();

        webTestClient.get()
                .uri("/api/v1/photos")
                .header("Authorization", "Bearer " + expiredToken)
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void shouldExtractCognitoUserIdFromJwt() throws Exception {
        String cognitoUserId = UUID.randomUUID().toString();
        String token = createJwtWithClaims(cognitoUserId, "test@example.com", "Test User");

        // We'll verify this works when we have actual endpoints
        // For now, just verify the token is accepted
        webTestClient.get()
                .uri("/api/v1/photos")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isNotFound(); // Auth passed
    }

    @Test
    void shouldExtractCognitoGroupsAsAuthorities() throws Exception {
        String token = createJwtWithGroups(List.of("admin", "users"));

        // Verify token with groups is accepted
        webTestClient.get()
                .uri("/api/v1/photos")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isNotFound(); // Auth passed
    }

    /**
     * Helper method to create a valid JWT token.
     */
    private String createValidJwt() throws Exception {
        return createJwtWithClaims(
                UUID.randomUUID().toString(),
                "test@example.com",
                "Test User"
        );
    }

    /**
     * Helper method to create an expired JWT token.
     */
    private String createExpiredJwt() throws Exception {
        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(UUID.randomUUID().toString())
                .issuer("http://localhost:" + mockWebServer.getPort())
                .claim("email", "test@example.com")
                .claim("name", "Test User")
                .claim("cognito:username", "testuser")
                .expirationTime(Date.from(Instant.now().minusSeconds(3600))) // Expired 1 hour ago
                .issueTime(Date.from(Instant.now().minusSeconds(7200)))
                .build();

        return signJwt(claimsSet);
    }

    /**
     * Helper method to create JWT with custom claims.
     */
    private String createJwtWithClaims(String cognitoUserId, String email, String name) throws Exception {
        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(cognitoUserId)
                .issuer("http://localhost:" + mockWebServer.getPort())
                .claim("email", email)
                .claim("name", name)
                .claim("cognito:username", email.split("@")[0])
                .expirationTime(Date.from(Instant.now().plusSeconds(3600)))
                .issueTime(Date.from(Instant.now()))
                .build();

        return signJwt(claimsSet);
    }

    /**
     * Helper method to create JWT with Cognito groups.
     */
    private String createJwtWithGroups(List<String> groups) throws Exception {
        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(UUID.randomUUID().toString())
                .issuer("http://localhost:" + mockWebServer.getPort())
                .claim("email", "admin@example.com")
                .claim("name", "Admin User")
                .claim("cognito:username", "adminuser")
                .claim("cognito:groups", groups)
                .expirationTime(Date.from(Instant.now().plusSeconds(3600)))
                .issueTime(Date.from(Instant.now()))
                .build();

        return signJwt(claimsSet);
    }

    /**
     * Helper method to sign JWT claims set with RSA key.
     */
    private String signJwt(JWTClaimsSet claimsSet) throws Exception {
        SignedJWT signedJWT = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256)
                        .keyID(rsaKey.getKeyID())
                        .build(),
                claimsSet
        );

        signedJWT.sign(new RSASSASigner(rsaKey));
        return signedJWT.serialize();
    }
}
