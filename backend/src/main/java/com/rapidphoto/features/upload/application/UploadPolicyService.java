package com.rapidphoto.features.upload.application;

import com.rapidphoto.repository.UploadJobRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Service to enforce upload policies and constraints.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UploadPolicyService {

    private static final long MAX_FILE_SIZE = 100_000_000L; // 100MB
    private static final long MAX_CONCURRENT_UPLOADS = 100;

    private final UploadJobRepository uploadJobRepository;

    /**
     * Verify user can initiate a new upload based on concurrent upload limits.
     *
     * @param userId User ID
     * @return Mono that completes if verification passes, errors otherwise
     */
    public Mono<Void> verifyUploadLimit(UUID userId) {
        return uploadJobRepository.countActiveUploadsByUserId(userId)
                .flatMap(count -> {
                    if (count >= MAX_CONCURRENT_UPLOADS) {
                        log.warn("User {} exceeded concurrent upload limit: {}/{}",
                                userId, count, MAX_CONCURRENT_UPLOADS);
                        return Mono.error(new UploadLimitExceededException(
                                String.format("Maximum concurrent uploads (%d) exceeded. Current active uploads: %d",
                                        MAX_CONCURRENT_UPLOADS, count)));
                    }
                    log.debug("User {} has {} active uploads (limit: {})",
                            userId, count, MAX_CONCURRENT_UPLOADS);
                    return Mono.empty();
                });
    }

    /**
     * Validate file size and MIME type.
     *
     * @param fileSize File size in bytes
     * @param mimeType File MIME type
     * @return Mono that completes if validation passes, errors otherwise
     */
    public Mono<Void> validateFile(Long fileSize, String mimeType) {
        return Mono.fromRunnable(() -> {
            if (fileSize == null || fileSize <= 0) {
                throw new InvalidFileException("File size must be greater than 0");
            }
            if (fileSize > MAX_FILE_SIZE) {
                throw new InvalidFileException(
                        String.format("File size (%d bytes) exceeds maximum allowed size (%d bytes)",
                                fileSize, MAX_FILE_SIZE));
            }
            if (mimeType == null || !isValidImageMimeType(mimeType)) {
                throw new InvalidFileException("Invalid MIME type: " + mimeType);
            }
        });
    }

    private boolean isValidImageMimeType(String mimeType) {
        return mimeType.matches("^image/(jpeg|jpg|png|gif|webp|heic|heif)$");
    }

    /**
     * Exception thrown when upload limit is exceeded.
     */
    public static class UploadLimitExceededException extends RuntimeException {
        public UploadLimitExceededException(String message) {
            super(message);
        }
    }

    /**
     * Exception thrown when file validation fails.
     */
    public static class InvalidFileException extends RuntimeException {
        public InvalidFileException(String message) {
            super(message);
        }
    }
}
