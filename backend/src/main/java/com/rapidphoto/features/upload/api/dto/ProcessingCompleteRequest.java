package com.rapidphoto.features.upload.api.dto;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * Request DTO for Lambda processing complete callback.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProcessingCompleteRequest {

    @NotNull
    private String status; // "READY" or "FAILED"

    private String thumbnailKey;

    @Valid
    private Metadata metadata;

    @Valid
    private List<Version> versions;

    @Valid
    private List<Label> labels;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Metadata {
        private Integer width;
        private Integer height;
        private String format;
        private Long size;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Version {
        @NotNull
        private String versionType; // e.g., "WEBP_640"

        @NotNull
        private String s3Key;

        @NotNull
        private Integer width;

        @NotNull
        private Integer height;

        @NotNull
        private Long fileSize;

        private String mimeType;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Label {
        @NotNull
        private String labelName;

        @NotNull
        private Double confidence;
    }

    /**
     * Convert to PhotoStatus enum.
     */
    public PhotoStatus getPhotoStatus() {
        return PhotoStatus.valueOf(status);
    }
}
