package com.rapidphoto.features.gallery.api;

import com.rapidphoto.domain.PhotoVersionType;
import com.rapidphoto.features.gallery.api.dto.DownloadUrlResponse;
import com.rapidphoto.features.gallery.api.dto.PagedPhotosResponse;
import com.rapidphoto.features.gallery.api.dto.PhotoResponse;
import com.rapidphoto.features.gallery.application.*;
import com.rapidphoto.security.SecurityContextUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * REST controller for gallery/photo query operations.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/photos")
@RequiredArgsConstructor
public class GalleryController {

    private final GetPhotosHandler getPhotosHandler;
    private final GetPhotoDetailHandler getPhotoDetailHandler;
    private final SearchPhotosHandler searchPhotosHandler;
    private final DeletePhotoHandler deletePhotoHandler;
    private final DownloadPhotoHandler downloadPhotoHandler;

    /**
     * GET /api/v1/photos
     * Get paginated list of photos for current user.
     */
    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<ResponseEntity<PagedPhotosResponse>> getPhotos(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            ServerWebExchange exchange) {

        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.debug("Get photos request from userId: {}, page: {}, size: {}", userId, page, size);
                    return getPhotosHandler.getPhotos(userId, page, size);
                })
                .map(response -> {
                    String etag = generateEtag(response);

                    // Check if client has cached version
                    if (checkEtagMatch(exchange, etag)) {
                        return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                                .eTag(etag)
                                .build();
                    }

                    return ResponseEntity.ok()
                            .eTag(etag)
                            .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES))
                            .body(response);
                });
    }

    /**
     * GET /api/v1/photos/{photoId}
     * Get detailed photo information.
     */
    @GetMapping(value = "/{photoId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<ResponseEntity<PhotoResponse>> getPhotoDetail(
            @PathVariable UUID photoId,
            ServerWebExchange exchange) {

        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.debug("Get photo detail request for photoId: {}, userId: {}", photoId, userId);
                    return getPhotoDetailHandler.getPhotoDetail(photoId, userId);
                })
                .map(response -> {
                    String etag = generateEtag(response);

                    // Check if client has cached version
                    if (checkEtagMatch(exchange, etag)) {
                        return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                                .eTag(etag)
                                .build();
                    }

                    return ResponseEntity.ok()
                            .eTag(etag)
                            .cacheControl(CacheControl.maxAge(10, TimeUnit.MINUTES))
                            .body(response);
                });
    }

    /**
     * GET /api/v1/photos/search
     * Search photos by tags/labels.
     */
    @GetMapping(value = "/search", produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<ResponseEntity<PagedPhotosResponse>> searchPhotos(
            @RequestParam String tags,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.debug("Search photos request from userId: {}, tags: {}", userId, tags);
                    return searchPhotosHandler.searchPhotosByTags(userId, tags, page, size);
                })
                .map(response -> ResponseEntity.ok()
                        .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES))
                        .body(response));
    }

    /**
     * DELETE /api/v1/photos/{photoId}
     * Delete a photo.
     */
    @DeleteMapping("/{photoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deletePhoto(@PathVariable UUID photoId) {
        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.info("Delete photo request for photoId: {}, userId: {}", photoId, userId);
                    return deletePhotoHandler.deletePhoto(photoId, userId);
                });
    }

    /**
     * GET /api/v1/photos/{photoId}/download/original
     * Get download URL for original photo.
     */
    @GetMapping(value = "/{photoId}/download/original", produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<DownloadUrlResponse> getOriginalDownloadUrl(@PathVariable UUID photoId) {
        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.debug("Get original download URL for photoId: {}, userId: {}", photoId, userId);
                    return downloadPhotoHandler.getOriginalDownloadUrl(photoId, userId);
                });
    }

    /**
     * GET /api/v1/photos/{photoId}/download/{versionType}
     * Get download URL for specific photo version.
     */
    @GetMapping(value = "/{photoId}/download/{versionType}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<DownloadUrlResponse> getVersionDownloadUrl(
            @PathVariable UUID photoId,
            @PathVariable PhotoVersionType versionType) {

        return SecurityContextUtils.getCurrentUserId()
                .flatMap(userId -> {
                    log.debug("Get {} download URL for photoId: {}, userId: {}",
                            versionType, photoId, userId);
                    return downloadPhotoHandler.getVersionDownloadUrl(photoId, userId, versionType);
                });
    }

    /**
     * Generate ETag for response.
     */
    private String generateEtag(Object response) {
        try {
            String content = response.toString();
            MessageDigest digest = MessageDigest.getInstance("MD5");
            byte[] hash = digest.digest(content.getBytes());
            return "\"" + Base64.getEncoder().encodeToString(hash) + "\"";
        } catch (NoSuchAlgorithmException e) {
            log.warn("Failed to generate ETag", e);
            return "\"" + UUID.randomUUID().toString() + "\"";
        }
    }

    /**
     * Check if client's ETag matches current resource.
     */
    private boolean checkEtagMatch(ServerWebExchange exchange, String etag) {
        String ifNoneMatch = exchange.getRequest().getHeaders().getFirst("If-None-Match");
        return ifNoneMatch != null && ifNoneMatch.equals(etag);
    }
}
