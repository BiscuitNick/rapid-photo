package com.rapidphoto.features.upload.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Request to confirm upload completion with S3 ETag.
 */
@Data
public class ConfirmUploadRequest {

    @NotBlank(message = "ETag is required")
    private String etag;
}
