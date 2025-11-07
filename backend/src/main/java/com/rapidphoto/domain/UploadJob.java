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
 * UploadJob aggregate root.
 * Tracks presigned URL generation and upload lifecycle.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("upload_jobs")
public class UploadJob {

    @Id
    private UUID id;

    private UUID userId;

    private String s3Key;  // originals/{userId}/{uuid}

    private String presignedUrl;

    private String fileName;

    private Long fileSize;

    private String mimeType;

    @Builder.Default
    private UploadJobStatus status = UploadJobStatus.INITIATED;

    private String etag;  // S3 ETag after upload

    private Instant expiresAt;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    private Instant confirmedAt;

    private String errorMessage;

    /**
     * Factory method to create a new upload job.
     */
    public static UploadJob create(UUID userId, String s3Key, String presignedUrl,
                                    String fileName, Long fileSize, String mimeType,
                                    Instant expiresAt) {
        return UploadJob.builder()
                .userId(userId)
                .s3Key(s3Key)
                .presignedUrl(presignedUrl)
                .fileName(fileName)
                .fileSize(fileSize)
                .mimeType(mimeType)
                .expiresAt(expiresAt)
                .build();
    }

    /**
     * Confirm upload with ETag.
     */
    public void confirm(String etag) {
        this.status = UploadJobStatus.CONFIRMED;
        this.etag = etag;
        this.confirmedAt = Instant.now();
    }

    /**
     * Mark upload as failed.
     */
    public void fail(String errorMessage) {
        this.status = UploadJobStatus.FAILED;
        this.errorMessage = errorMessage;
    }

    /**
     * Check if upload job is expired.
     */
    public boolean isExpired() {
        return Instant.now().isAfter(expiresAt);
    }

    /**
     * Check if upload job can be confirmed.
     */
    public boolean canBeConfirmed() {
        return status == UploadJobStatus.UPLOADED && !isExpired();
    }
}
