package com.rapidphoto.features.upload.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Response containing presigned URL and upload job details.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GeneratePresignedUrlResponse {

    private UUID uploadId;

    private String presignedUrl;

    private String s3Key;

    private Instant expiresAt;

    private String fileName;

    private Long fileSize;

    private String mimeType;
}
