package com.rapidphoto.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Photo aggregate root.
 * Represents a photo after upload confirmation, including metadata and processing status.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("photos")
public class Photo {

    @Id
    private UUID id;

    private UUID userId;

    private UUID uploadJobId;

    private String originalS3Key;

    private String fileName;

    private Long fileSize;

    private String mimeType;

    private Integer width;

    private Integer height;

    @Builder.Default
    @Column(value = "status")
    private PhotoStatus status = PhotoStatus.PENDING_PROCESSING;  // Maps to photo_status ENUM

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    private Instant processedAt;

    private Instant takenAt;

    private String cameraMake;

    private String cameraModel;

    private BigDecimal gpsLatitude;

    private BigDecimal gpsLongitude;

    private String errorMessage;

    /**
     * Factory method to create a new photo from confirmed upload.
     */
    public static Photo fromUploadJob(UploadJob uploadJob) {
        return Photo.builder()
                .id(UUID.randomUUID())  // Generate ID for new photo
                .userId(uploadJob.getUserId())
                .uploadJobId(uploadJob.getId())
                .originalS3Key(uploadJob.getS3Key())
                .fileName(uploadJob.getFileName())
                .fileSize(uploadJob.getFileSize())
                .mimeType(uploadJob.getMimeType())
                .status(PhotoStatus.PENDING_PROCESSING)  // Explicitly set initial status
                .createdAt(Instant.now())  // Set creation timestamp
                .build();
    }

    /**
     * Start processing the photo.
     */
    public void startProcessing() {
        this.status = PhotoStatus.PROCESSING;
    }

    /**
     * Mark photo as ready after successful processing.
     */
    public void markReady(Integer width, Integer height) {
        this.status = PhotoStatus.READY;
        this.width = width;
        this.height = height;
        this.processedAt = Instant.now();
    }

    /**
     * Mark photo as failed with error message.
     */
    public void markFailed(String errorMessage) {
        this.status = PhotoStatus.FAILED;
        this.errorMessage = errorMessage;
    }

    /**
     * Get status as enum.
     */
    public PhotoStatus getStatusEnum() {
        return status;
    }

    /**
     * Set status from enum.
     */
    public void setStatusEnum(PhotoStatus status) {
        this.status = status;
    }

    /**
     * Update EXIF metadata.
     */
    public void updateExifMetadata(Instant takenAt, String cameraMake, String cameraModel) {
        this.takenAt = takenAt;
        this.cameraMake = cameraMake;
        this.cameraModel = cameraModel;
    }

    /**
     * Update GPS coordinates from EXIF.
     */
    public void updateGpsCoordinates(BigDecimal latitude, BigDecimal longitude) {
        this.gpsLatitude = latitude;
        this.gpsLongitude = longitude;
    }

    /**
     * Check if photo has GPS coordinates.
     */
    public boolean hasGpsCoordinates() {
        return gpsLatitude != null && gpsLongitude != null;
    }

    /**
     * Check if photo is ready for viewing.
     */
    public boolean isReady() {
        return PhotoStatus.READY.equals(status);
    }

    /**
     * Check if photo processing failed.
     */
    public boolean hasFailed() {
        return PhotoStatus.FAILED.equals(status);
    }
}
