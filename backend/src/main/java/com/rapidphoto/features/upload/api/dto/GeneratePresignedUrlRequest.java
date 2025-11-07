package com.rapidphoto.features.upload.api.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

/**
 * Request to generate a presigned URL for file upload.
 */
@Data
public class GeneratePresignedUrlRequest {

    @NotBlank(message = "File name is required")
    @Size(max = 255, message = "File name must not exceed 255 characters")
    private String fileName;

    @NotNull(message = "File size is required")
    @Min(value = 1, message = "File size must be at least 1 byte")
    @Max(value = 100_000_000, message = "File size must not exceed 100MB")
    private Long fileSize;

    @NotBlank(message = "MIME type is required")
    @Pattern(regexp = "^image/(jpeg|jpg|png|gif|webp|heic|heif)$",
             message = "Only image files are allowed (JPEG, PNG, GIF, WebP, HEIC, HEIF)")
    private String mimeType;
}
