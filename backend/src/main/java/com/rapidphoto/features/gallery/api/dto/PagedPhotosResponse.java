package com.rapidphoto.features.gallery.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Paginated response for photo listings.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PagedPhotosResponse {

    private List<PhotoListItemDto> content;

    private int page;

    private int size;

    private long totalElements;

    private int totalPages;

    private boolean hasNext;

    private boolean hasPrevious;
}
