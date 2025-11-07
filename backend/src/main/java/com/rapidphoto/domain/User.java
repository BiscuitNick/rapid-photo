package com.rapidphoto.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.relational.core.mapping.Table;

import java.time.Instant;
import java.util.UUID;

/**
 * User aggregate root.
 * Users are authenticated via AWS Cognito, this stores additional metadata.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("users")
public class User {

    @Id
    private UUID id;

    private String cognitoUserId;  // AWS Cognito sub claim

    private String email;

    private String name;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    private Instant lastLoginAt;

    @Builder.Default
    private Boolean isActive = true;

    @Builder.Default
    private Long storageQuotaBytes = 10737418240L; // 10GB default

    @Builder.Default
    private Long storageUsedBytes = 0L;

    /**
     * Factory method to create a new user from Cognito JWT claims.
     */
    public static User fromCognito(String cognitoUserId, String email, String name) {
        return User.builder()
                .cognitoUserId(cognitoUserId)
                .email(email)
                .name(name)
                .lastLoginAt(Instant.now())
                .build();
    }

    /**
     * Update storage usage after upload/delete.
     */
    public void updateStorageUsage(long deltaBytes) {
        this.storageUsedBytes = Math.max(0, this.storageUsedBytes + deltaBytes);
    }

    /**
     * Check if user has available storage quota.
     */
    public boolean hasAvailableStorage(long requiredBytes) {
        return (storageUsedBytes + requiredBytes) <= storageQuotaBytes;
    }

    /**
     * Record login activity.
     */
    public void recordLogin() {
        this.lastLoginAt = Instant.now();
    }
}
