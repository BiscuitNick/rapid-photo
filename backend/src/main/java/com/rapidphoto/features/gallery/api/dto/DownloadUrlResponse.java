package com.rapidphoto.features.gallery.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * Response containing presigned download URL.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DownloadUrlResponse {

    private String downloadUrl;

    private Instant expiresAt;

    private String fileName;

    private Long fileSize;
}
