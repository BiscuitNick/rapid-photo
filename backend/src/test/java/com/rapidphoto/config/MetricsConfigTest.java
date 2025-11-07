package com.rapidphoto.config;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for MetricsConfig.
 * Verifies that custom metrics are properly registered.
 */
@SpringBootTest
@TestPropertySource(properties = {
        "management.metrics.export.cloudwatch.enabled=false"
})
class MetricsConfigTest {

    @Autowired
    private MeterRegistry meterRegistry;

    @Autowired
    private Timer uploadPresignedUrlTimer;

    @Autowired
    private Timer uploadConfirmTimer;

    @Autowired
    private Timer galleryQueryTimer;

    @Autowired
    private Counter photoUploadSuccessCounter;

    @Autowired
    private Counter photoUploadFailureCounter;

    @Test
    void shouldLoadMeterRegistry() {
        assertThat(meterRegistry).isNotNull();
    }

    @Test
    void shouldRegisterUploadPresignedUrlTimer() {
        assertThat(uploadPresignedUrlTimer).isNotNull();
        assertThat(uploadPresignedUrlTimer.getId().getName()).isEqualTo("upload.presigned.url");
        assertThat(uploadPresignedUrlTimer.getId().getTag("operation")).isEqualTo("generate");
    }

    @Test
    void shouldRegisterUploadConfirmTimer() {
        assertThat(uploadConfirmTimer).isNotNull();
        assertThat(uploadConfirmTimer.getId().getName()).isEqualTo("upload.confirm");
        assertThat(uploadConfirmTimer.getId().getTag("operation")).isEqualTo("confirm");
    }

    @Test
    void shouldRegisterGalleryQueryTimer() {
        assertThat(galleryQueryTimer).isNotNull();
        assertThat(galleryQueryTimer.getId().getName()).isEqualTo("gallery.query.duration");
        assertThat(galleryQueryTimer.getId().getTag("operation")).isEqualTo("query");
    }

    @Test
    void shouldRegisterPhotoUploadSuccessCounter() {
        assertThat(photoUploadSuccessCounter).isNotNull();
        assertThat(photoUploadSuccessCounter.getId().getName()).isEqualTo("photo.upload.success");
        assertThat(photoUploadSuccessCounter.getId().getTag("status")).isEqualTo("success");
    }

    @Test
    void shouldRegisterPhotoUploadFailureCounter() {
        assertThat(photoUploadFailureCounter).isNotNull();
        assertThat(photoUploadFailureCounter.getId().getName()).isEqualTo("photo.upload.failure");
        assertThat(photoUploadFailureCounter.getId().getTag("status")).isEqualTo("failure");
    }

    @Test
    void shouldIncrementCounter() {
        // Given
        double initialCount = photoUploadSuccessCounter.count();

        // When
        photoUploadSuccessCounter.increment();

        // Then
        assertThat(photoUploadSuccessCounter.count()).isEqualTo(initialCount + 1);
    }

    @Test
    void shouldRecordTimerDuration() {
        // Given
        long initialCount = uploadPresignedUrlTimer.count();

        // When
        uploadPresignedUrlTimer.record(() -> {
            // Simulate some work
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        // Then
        assertThat(uploadPresignedUrlTimer.count()).isEqualTo(initialCount + 1);
        assertThat(uploadPresignedUrlTimer.totalTime(java.util.concurrent.TimeUnit.MILLISECONDS)).isGreaterThan(0);
    }

    @Test
    void shouldFindMetricInRegistry() {
        // Verify that metrics are actually registered in the MeterRegistry
        Timer timer = meterRegistry.find("upload.presigned.url").timer();
        assertThat(timer).isNotNull();
        assertThat(timer).isEqualTo(uploadPresignedUrlTimer);

        Counter counter = meterRegistry.find("photo.upload.success").counter();
        assertThat(counter).isNotNull();
        assertThat(counter).isEqualTo(photoUploadSuccessCounter);
    }
}
