package com.rapidphoto.domain;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UserTest {

    @Test
    void deriveUserIdShouldReturnParsedUuidWhenValueIsValid() {
        String cognitoUserId = UUID.randomUUID().toString();

        UUID derived = User.deriveUserId(cognitoUserId);

        assertThat(derived).isEqualTo(UUID.fromString(cognitoUserId));
    }

    @Test
    void deriveUserIdShouldGenerateDeterministicUuidForNonUuidValues() {
        String cognitoUserId = "test-user-123";

        UUID first = User.deriveUserId(cognitoUserId);
        UUID second = User.deriveUserId(cognitoUserId);

        assertThat(first).isEqualTo(second);
        assertThat(first.toString()).isNotEqualTo(cognitoUserId);
    }

    @Test
    void deriveUserIdShouldRejectBlankValues() {
        assertThatThrownBy(() -> User.deriveUserId(" "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Cognito user ID cannot be null or blank");
    }
}
