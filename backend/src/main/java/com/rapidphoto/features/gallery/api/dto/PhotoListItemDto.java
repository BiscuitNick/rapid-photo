package com.rapidphoto.features.gallery.api.dto;

import com.rapidphoto.domain.PhotoStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Lightweight DTO for photo list/grid view.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PhotoListItemDto {

    private UUID id;

    private String fileName;

    private PhotoStatus status;

    private String thumbnailUrl;

    private String originalUrl;

    private Integer width;

    private Integer height;

    private List<String> labels;

    private Instant createdAt;

    private Instant takenAt;
}
