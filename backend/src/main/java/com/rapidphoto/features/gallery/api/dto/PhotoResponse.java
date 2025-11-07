package com.rapidphoto.features.gallery.api.dto;

import com.rapidphoto.domain.PhotoStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Detailed photo response with all metadata and versions.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PhotoResponse {

    private UUID id;

    private String fileName;

    private PhotoStatus status;

    private Long fileSize;

    private String mimeType;

    private Integer width;

    private Integer height;

    private String originalUrl;

    private String thumbnailUrl;

    private List<PhotoVersionDto> versions;

    private List<PhotoLabelDto> labels;

    private Instant createdAt;

    private Instant processedAt;

    private Instant takenAt;

    private String cameraMake;

    private String cameraModel;

    private BigDecimal gpsLatitude;

    private BigDecimal gpsLongitude;
}
