package com.rapidphoto.features.gallery.application;

import com.rapidphoto.domain.Photo;
import com.rapidphoto.domain.PhotoVersionType;
import com.rapidphoto.features.gallery.api.dto.PagedPhotosResponse;
import com.rapidphoto.features.gallery.api.dto.PhotoListItemDto;
import com.rapidphoto.repository.PhotoLabelRepository;
import com.rapidphoto.repository.PhotoRepository;
import com.rapidphoto.repository.PhotoVersionRepository;
import io.micrometer.observation.annotation.Observed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Query handler for searching photos by tags/labels.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SearchPhotosHandler {

    private final PhotoRepository photoRepository;
    private final PhotoVersionRepository photoVersionRepository;
    private final PhotoLabelRepository photoLabelRepository;
    private final PhotoReadModelMapper mapper;

    private static final BigDecimal MIN_CONFIDENCE = BigDecimal.valueOf(70);

    /**
     * Search photos by label tags.
     */
    @Observed(name = "gallery.query.search")
    public Mono<PagedPhotosResponse> searchPhotosByTags(UUID userId, String tags, int page, int size) {
        log.debug("Searching photos for userId: {}, tags: {}", userId, tags);

        if (tags == null || tags.trim().isEmpty()) {
            return Mono.just(createEmptyResponse(page, size));
        }

        String[] tagArray = tags.trim().split(",");
        List<String> tagList = Arrays.stream(tagArray)
                .map(String::trim)
                .filter(tag -> !tag.isEmpty())
                .collect(Collectors.toList());

        if (tagList.isEmpty()) {
            return Mono.just(createEmptyResponse(page, size));
        }

        // Find photos that have ALL specified tags
        return photoLabelRepository
                .findPhotoIdsByUserIdAndAllLabels(userId, tagList.toArray(new String[0]), tagList.size())
                .collectList()
                .flatMap(photoIds -> {
                    if (photoIds.isEmpty()) {
                        return Mono.just(createEmptyResponse(page, size));
                    }

                    return fetchPhotosWithMetadata(photoIds, page, size);
                })
                .doOnSuccess(response -> log.info("Found {} photos matching tags: {}",
                        response.getContent().size(), tags));
    }

    private Mono<PagedPhotosResponse> fetchPhotosWithMetadata(List<UUID> photoIds, int page, int size) {
        // Apply pagination
        int skip = page * size;
        int limit = Math.min(size, photoIds.size() - skip);

        if (skip >= photoIds.size() || limit <= 0) {
            return Mono.just(createEmptyResponse(page, size));
        }

        List<UUID> paginatedIds = photoIds.subList(skip, skip + limit);

        return Flux.fromIterable(paginatedIds)
                .flatMap(photoRepository::findById)
                .collectList()
                .flatMap(photos -> enrichPhotosWithMetadata(photos, paginatedIds)
                        .collectList()
                        .map(items -> {
                            int totalElements = photoIds.size();
                            int totalPages = (int) Math.ceil((double) totalElements / size);

                            return PagedPhotosResponse.builder()
                                    .content(items)
                                    .page(page)
                                    .size(size)
                                    .totalElements(totalElements)
                                    .totalPages(totalPages)
                                    .hasNext(page < totalPages - 1)
                                    .hasPrevious(page > 0)
                                    .build();
                        }));
    }

    private Flux<PhotoListItemDto> enrichPhotosWithMetadata(List<Photo> photos, List<UUID> photoIds) {
        // Get thumbnails for photos
        Mono<Map<UUID, String>> thumbnailsMono = photoVersionRepository
                .findByPhotoIdInAndVersionType(photoIds, PhotoVersionType.THUMBNAIL)
                .collectMap(version -> version.getPhotoId(), version -> version.getS3Key());

        // Get labels for photos
        Mono<Map<UUID, List<String>>> labelsMono = Flux.fromIterable(photoIds)
                .flatMap(photoId -> photoLabelRepository.findByPhotoId(photoId)
                        .map(label -> Map.entry(photoId, label.getLabelName()))
                        .collectList()
                        .map(labelList -> Map.entry(photoId, labelList)))
                .collectMap(Map.Entry::getKey, Map.Entry::getValue);

        return Mono.zip(thumbnailsMono, labelsMono)
                .flatMapMany(tuple -> {
                    Map<UUID, String> thumbnails = tuple.getT1();
                    Map<UUID, List<String>> labels = tuple.getT2();

                    return Flux.fromIterable(photos)
                            .flatMap(photo -> {
                                String thumbnailS3Key = thumbnails.get(photo.getId());
                                List<String> photoLabels = labels.getOrDefault(photo.getId(), List.of());

                                return mapper.toPhotoListItem(photo, thumbnailS3Key, photoLabels);
                            });
                });
    }

    private PagedPhotosResponse createEmptyResponse(int page, int size) {
        return PagedPhotosResponse.builder()
                .content(List.of())
                .page(page)
                .size(size)
                .totalElements(0)
                .totalPages(0)
                .hasNext(false)
                .hasPrevious(false)
                .build();
    }
}
