package com.rapidphoto.features.gallery.api.dto;

import com.rapidphoto.domain.PhotoVersionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for photo version information with URL.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PhotoVersionDto {

    private PhotoVersionType versionType;

    private String url;

    private Integer width;

    private Integer height;

    private Long fileSize;

    private String mimeType;
}
