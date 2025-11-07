package com.rapidphoto.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * PhotoLabel entity.
 * Represents an AI-detected label from AWS Rekognition.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("photo_labels")
public class PhotoLabel {

    @Id
    private UUID id;

    private UUID photoId;

    private String labelName;

    private BigDecimal confidence;

    @CreatedDate
    private Instant createdAt;

    /**
     * Factory method to create a new photo label.
     */
    public static PhotoLabel create(UUID photoId, String labelName, BigDecimal confidence) {
        return PhotoLabel.builder()
                .photoId(photoId)
                .labelName(labelName)
                .confidence(confidence)
                .build();
    }

    /**
     * Check if label has high confidence (>= 90%).
     */
    public boolean isHighConfidence() {
        return confidence.compareTo(BigDecimal.valueOf(90)) >= 0;
    }

    /**
     * Check if label has medium confidence (>= 70% and < 90%).
     */
    public boolean isMediumConfidence() {
        return confidence.compareTo(BigDecimal.valueOf(70)) >= 0
                && confidence.compareTo(BigDecimal.valueOf(90)) < 0;
    }

    /**
     * Check if label has low confidence (< 70%).
     */
    public boolean isLowConfidence() {
        return confidence.compareTo(BigDecimal.valueOf(70)) < 0;
    }

    /**
     * Get confidence level as a string.
     */
    public String getConfidenceLevel() {
        if (isHighConfidence()) {
            return "HIGH";
        } else if (isMediumConfidence()) {
            return "MEDIUM";
        } else {
            return "LOW";
        }
    }
}
