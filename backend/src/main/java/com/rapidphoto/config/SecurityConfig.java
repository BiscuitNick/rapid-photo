package com.rapidphoto.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.oauth2.jwt.ReactiveJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusReactiveJwtDecoder;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.beans.factory.annotation.Value;

/**
 * Security configuration for Spring WebFlux with AWS Cognito JWT authentication.
 * Configures OAuth2 resource server for validating Amplify/Cognito JWTs.
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri}")
    private String jwkSetUri;

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchanges -> exchanges
                        // Public endpoints - actuator health/info
                        .pathMatchers("/actuator/health", "/actuator/info").permitAll()

                        // Actuator requires authentication
                        .pathMatchers("/actuator/**").authenticated()

                        // API endpoints require authentication
                        .pathMatchers("/api/**").authenticated()

                        // All other requests require authentication
                        .anyExchange().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .jwtDecoder(reactiveJwtDecoder())
                                .jwtAuthenticationConverter(new CognitoJwtAuthenticationConverter())
                        )
                )
                .build();
    }

    /**
     * Reactive JWT decoder for validating Cognito JWT tokens.
     * Uses JWK Set URI from Cognito to fetch and cache public keys.
     */
    @Bean
    public ReactiveJwtDecoder reactiveJwtDecoder() {
        return NimbusReactiveJwtDecoder.withJwkSetUri(jwkSetUri).build();
    }
}
