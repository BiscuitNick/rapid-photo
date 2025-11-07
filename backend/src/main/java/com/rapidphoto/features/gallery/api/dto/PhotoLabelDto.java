package com.rapidphoto.features.gallery.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO for photo label (AI-detected tag).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PhotoLabelDto {

    private String labelName;

    private BigDecimal confidence;

    private String confidenceLevel;
}
