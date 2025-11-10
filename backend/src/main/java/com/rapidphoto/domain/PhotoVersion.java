package com.rapidphoto.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.Instant;
import java.util.UUID;

/**
 * PhotoVersion entity.
 * Represents a processed version of a photo (thumbnail, WebP renditions).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("photo_versions")
public class PhotoVersion {

    @Id
    private UUID id;

    @Column("photo_id")
    private UUID photoId;

    @Column("version_type")
    private PhotoVersionType versionType;

    @Column("s3_key")
    private String s3Key;

    @Column("file_size")
    private Long fileSize;

    private Integer width;

    private Integer height;

    @Column("mime_type")
    private String mimeType;

    @CreatedDate
    @Column("created_at")
    private Instant createdAt;

    /**
     * Factory method to create a new photo version.
     */
    public static PhotoVersion create(UUID photoId, PhotoVersionType versionType,
                                       String s3Key, Long fileSize,
                                       Integer width, Integer height, String mimeType) {
        return PhotoVersion.builder()
                .photoId(photoId)
                .versionType(versionType)
                .s3Key(s3Key)
                .fileSize(fileSize)
                .width(width)
                .height(height)
                .mimeType(mimeType)
                .build();
    }

    /**
     * Check if this is a thumbnail version.
     */
    public boolean isThumbnail() {
        return versionType == PhotoVersionType.THUMBNAIL;
    }

    /**
     * Check if this is a WebP version.
     */
    public boolean isWebP() {
        return versionType == PhotoVersionType.WEBP_640
                || versionType == PhotoVersionType.WEBP_1280
                || versionType == PhotoVersionType.WEBP_1920
                || versionType == PhotoVersionType.WEBP_2560;
    }

    /**
     * Get the width category for WebP versions.
     */
    public Integer getWidthCategory() {
        return switch (versionType) {
            case WEBP_640 -> 640;
            case WEBP_1280 -> 1280;
            case WEBP_1920 -> 1920;
            case WEBP_2560 -> 2560;
            case THUMBNAIL -> 300;
        };
    }
}
