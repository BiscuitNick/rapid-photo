package com.rapidphoto.features.upload.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rapidphoto.features.upload.domain.event.PhotoUploadConfirmedEvent;
import io.awspring.cloud.sqs.operations.SqsTemplate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

/**
 * Service for publishing photo events to SQS.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PhotoEventPublisher {

    private final SqsTemplate sqsTemplate;
    private final ObjectMapper objectMapper;

    @Value("${aws.sqs.photo-upload-queue}")
    private String photoUploadQueueName;

    /**
     * Publish PhotoUploadConfirmedEvent to SQS for Lambda processing.
     *
     * @param event The upload confirmed event
     * @return Mono that completes when event is published
     */
    public Mono<Void> publishPhotoUploadConfirmed(PhotoUploadConfirmedEvent event) {
        return Mono.fromRunnable(() -> {
            try {
                log.info("Publishing PhotoUploadConfirmedEvent for photoId: {}, s3Key: {}",
                        event.photoId(), event.s3Key());

                String messageBody = objectMapper.writeValueAsString(event);

                sqsTemplate.send(to -> to
                        .queue(photoUploadQueueName)
                        .payload(messageBody));

                log.debug("Successfully published event to queue: {}", photoUploadQueueName);
            } catch (Exception e) {
                log.error("Failed to publish PhotoUploadConfirmedEvent for photoId: {}",
                        event.photoId(), e);
                throw new EventPublishException("Failed to publish upload confirmed event", e);
            }
        });
    }

    /**
     * Exception thrown when event publishing fails.
     */
    public static class EventPublishException extends RuntimeException {
        public EventPublishException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
