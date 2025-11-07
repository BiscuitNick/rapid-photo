package com.rapidphoto.features.upload.domain.command;

import java.util.UUID;

/**
 * Command to generate a presigned URL for upload.
 */
public record GeneratePresignedUrlCommand(
    UUID userId,
    String fileName,
    Long fileSize,
    String mimeType
) {}
