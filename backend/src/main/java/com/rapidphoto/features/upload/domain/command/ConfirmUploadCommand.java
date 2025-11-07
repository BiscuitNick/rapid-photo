package com.rapidphoto.features.upload.domain.command;

import java.util.UUID;

/**
 * Command to confirm a completed upload.
 */
public record ConfirmUploadCommand(
    UUID uploadId,
    UUID userId,
    String etag
) {}
