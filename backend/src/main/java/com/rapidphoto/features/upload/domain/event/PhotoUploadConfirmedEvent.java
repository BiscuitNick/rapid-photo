package com.rapidphoto.features.upload.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Domain event emitted when a photo upload is confirmed.
 * This triggers the Lambda processing pipeline.
 */
public record PhotoUploadConfirmedEvent(
    UUID photoId,
    UUID uploadJobId,
    UUID userId,
    String s3Key,
    String fileName,
    Long fileSize,
    String mimeType,
    Instant confirmedAt
) {}
