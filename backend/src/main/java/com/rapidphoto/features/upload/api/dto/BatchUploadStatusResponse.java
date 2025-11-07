package com.rapidphoto.features.upload.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Batch upload status response combining UploadJob and Photo states.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchUploadStatusResponse {

    private List<UploadStatus> uploads;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UploadStatus {
        private UUID uploadId;
        private String fileName;
        private String uploadJobStatus;
        private String photoStatus;
        private UUID photoId;
        private Instant createdAt;
        private Instant confirmedAt;
        private Instant processedAt;
        private String errorMessage;
    }
}
