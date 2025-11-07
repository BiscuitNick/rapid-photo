package com.rapidphoto.features.upload.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Response after confirming upload.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfirmUploadResponse {

    private UUID photoId;

    private UUID uploadId;

    private String status;

    private String message;
}
