package com.rapidphoto.security;

import com.rapidphoto.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

/**
 * WebFilter that automatically provisions users in the database on first authentication.
 * Intercepts authenticated requests and ensures a User record exists for the Cognito user.
 *
 * This filter runs after JWT authentication but before controller processing,
 * ensuring all authenticated users have a corresponding database record.
 */
@Slf4j
@Component
@Order(0)
@RequiredArgsConstructor
public class UserProvisioningWebFilter implements WebFilter {

    private final UserService userService;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        String method = exchange.getRequest().getMethod().name();

        // Skip filter for health/info endpoints - they don't need user provisioning
        if (path.equals("/actuator/health") || path.equals("/actuator/info")) {
            return chain.filter(exchange);
        }

        log.warn("Hello I am working - UserProvisioningWebFilter engaged for {} {}", method, path);

        return exchange.getPrincipal()
                .filter(principal -> principal instanceof JwtAuthenticationToken)
                .cast(JwtAuthenticationToken.class)
                .flatMap(authToken -> {
                    Jwt jwt = authToken.getToken();

                    // Extract user information from JWT claims
                    String cognitoUserId = jwt.getClaimAsString("sub");
                    String email = resolveEmail(jwt);
                    String name = jwt.getClaimAsString("name");

                    // Log every authenticated request with user details
                    log.warn("🔐 Authenticated Request: {} {} | User: {} | Email: {} | Cognito ID: {}",
                            method, path, name != null ? name : "Unknown", email, cognitoUserId);

                    // Ensure user exists in database
                    return userService.findOrCreateUser(cognitoUserId, email, name)
                            .doOnSuccess(user ->
                                log.warn("✅ User login processed: email={} | cognitoId={} | userId={}",
                                        email, cognitoUserId, user.getId()))
                            .doOnError(error ->
                                log.error("❌ User login failed: email={} | cognitoId={} | reason={}",
                                        email, cognitoUserId, error.getMessage()))
                            .thenReturn(true);
                })
                .switchIfEmpty(Mono.fromRunnable(() ->
                        log.warn("⚠️ No authenticated principal available for {} {}", method, path)))
                .onErrorResume(error -> {
                    // Log error but don't block the request
                    log.error("❌ Error in user provisioning filter for {} {}: {}",
                            method, path, error.getMessage());
                    return Mono.empty();
                })
                .then(chain.filter(exchange));
    }

    private String resolveEmail(Jwt jwt) {
        String emailClaim = jwt.getClaimAsString("email");
        if (StringUtils.hasText(emailClaim)) {
            return emailClaim;
        }

        String usernameClaim = jwt.getClaimAsString("cognito:username");
        if (StringUtils.hasText(usernameClaim)) {
            // If username already looks like an email, reuse it; otherwise synthesize a stable placeholder.
            if (usernameClaim.contains("@")) {
                log.warn("⚠️ JWT missing email claim, falling back to cognito:username value: {}", usernameClaim);
                return usernameClaim;
            }

            String fallbackEmail = usernameClaim + "@placeholder.local";
            log.warn("⚠️ JWT missing email claim, synthesizing placeholder email: {}", fallbackEmail);
            return fallbackEmail;
        }

        // Absolute fallback: use sub claim as placeholder email
        String fallbackEmail = jwt.getClaimAsString("sub") + "@placeholder.local";
        log.warn("⚠️ JWT missing email and cognito:username claims, using Cognito ID fallback: {}", fallbackEmail);
        return fallbackEmail;
    }
}
