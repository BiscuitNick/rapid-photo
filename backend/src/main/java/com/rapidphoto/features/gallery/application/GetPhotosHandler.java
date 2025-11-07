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
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Query handler for getting paginated list of photos.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GetPhotosHandler {

    private final PhotoRepository photoRepository;
    private final PhotoVersionRepository photoVersionRepository;
    private final PhotoLabelRepository photoLabelRepository;
    private final PhotoReadModelMapper mapper;

    /**
     * Get paginated list of photos for a user.
     */
    @Observed(name = "gallery.query.photos")
    public Mono<PagedPhotosResponse> getPhotos(UUID userId, int page, int size) {
        log.debug("Fetching photos for userId: {}, page: {}, size: {}", userId, page, size);

        Pageable pageable = PageRequest.of(page, size);

        return photoRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .collectList()
                .flatMap(photos -> {
                    if (photos.isEmpty()) {
                        return Mono.just(createEmptyResponse(page, size));
                    }

                    return enrichPhotosWithMetadata(photos)
                            .collectList()
                            .zipWith(photoRepository.countByUserId(userId))
                            .map(tuple -> {
                                List<PhotoListItemDto> items = tuple.getT1();
                                long totalElements = tuple.getT2();
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
                            });
                })
                .doOnSuccess(response -> log.info("Returned {} photos for userId: {}, page: {}",
                        response.getContent().size(), userId, page));
    }

    private Flux<PhotoListItemDto> enrichPhotosWithMetadata(List<Photo> photos) {
        List<UUID> photoIds = photos.stream().map(Photo::getId).collect(Collectors.toList());

        // Get thumbnails for all photos
        Mono<Map<UUID, String>> thumbnailsMono = photoVersionRepository
                .findByPhotoIdInAndVersionType(photoIds, PhotoVersionType.THUMBNAIL)
                .collectMap(version -> version.getPhotoId(), version -> version.getS3Key());

        // Get labels for all photos
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
