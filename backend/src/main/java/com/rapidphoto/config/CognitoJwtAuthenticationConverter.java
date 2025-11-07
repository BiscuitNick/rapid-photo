package com.rapidphoto.config;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import reactor.core.publisher.Mono;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Converts Cognito JWT tokens to Spring Security Authentication objects.
 * Extracts user information from Cognito JWT claims and maps them to authorities.
 */
public class CognitoJwtAuthenticationConverter implements Converter<Jwt, Mono<AbstractAuthenticationToken>> {

    private static final String COGNITO_GROUPS_CLAIM = "cognito:groups";
    private static final String COGNITO_USERNAME_CLAIM = "cognito:username";
    private static final String SUB_CLAIM = "sub";
    private static final String EMAIL_CLAIM = "email";
    private static final String NAME_CLAIM = "name";

    @Override
    public Mono<AbstractAuthenticationToken> convert(Jwt jwt) {
        Collection<GrantedAuthority> authorities = extractAuthorities(jwt);

        // Create authentication token with principal as cognito user ID (sub claim)
        String principal = extractPrincipal(jwt);

        return Mono.just(new JwtAuthenticationToken(jwt, authorities, principal));
    }

    /**
     * Extract authorities from Cognito groups.
     * Cognito groups are mapped to Spring Security authorities with ROLE_ prefix.
     */
    private Collection<GrantedAuthority> extractAuthorities(Jwt jwt) {
        List<String> groups = jwt.getClaimAsStringList(COGNITO_GROUPS_CLAIM);

        if (groups == null || groups.isEmpty()) {
            return Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"));
        }

        return groups.stream()
                .map(group -> new SimpleGrantedAuthority("ROLE_" + group.toUpperCase()))
                .collect(Collectors.toList());
    }

    /**
     * Extract principal identifier from JWT.
     * Uses Cognito 'sub' claim as the unique user identifier.
     */
    private String extractPrincipal(Jwt jwt) {
        return jwt.getClaimAsString(SUB_CLAIM);
    }

    /**
     * Extract Cognito username from JWT.
     */
    public static String extractCognitoUsername(Jwt jwt) {
        return jwt.getClaimAsString(COGNITO_USERNAME_CLAIM);
    }

    /**
     * Extract email from JWT.
     */
    public static String extractEmail(Jwt jwt) {
        return jwt.getClaimAsString(EMAIL_CLAIM);
    }

    /**
     * Extract name from JWT.
     */
    public static String extractName(Jwt jwt) {
        return jwt.getClaimAsString(NAME_CLAIM);
    }

    /**
     * Extract Cognito user ID (sub) from JWT.
     */
    public static String extractCognitoUserId(Jwt jwt) {
        return jwt.getClaimAsString(SUB_CLAIM);
    }
}
