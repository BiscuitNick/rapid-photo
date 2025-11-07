package com.rapidphoto.config;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tag;
import io.micrometer.core.instrument.Tags;
import io.micrometer.observation.ObservationRegistry;
import io.micrometer.observation.aop.ObservedAspect;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.autoconfigure.observation.ObservationRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.net.InetAddress;
import java.net.UnknownHostException;

/**
 * Observability configuration for metrics, tracing, and monitoring.
 * Integrates with Micrometer for metrics collection and AWS X-Ray for distributed tracing.
 */
@Configuration
public class ObservabilityConfig {

    @Value("${spring.application.name}")
    private String applicationName;

    @Value("${SPRING_PROFILES_ACTIVE:default}")
    private String activeProfile;

    /**
     * Enable @Observed annotation support for automatic observation of methods.
     * This creates spans/metrics for annotated methods automatically.
     */
    @Bean
    public ObservedAspect observedAspect(ObservationRegistry observationRegistry) {
        return new ObservedAspect(observationRegistry);
    }

    /**
     * Customize ObservationRegistry with common tags for all observations.
     * These tags will be attached to all metrics and traces.
     */
    @Bean
    public ObservationRegistryCustomizer<ObservationRegistry> commonTagsCustomizer() {
        return registry -> registry.observationConfig()
                .observationHandler(context -> {
                    // Add common tags to all observations
                    context.addLowCardinalityKeyValue("application", applicationName);
                    context.addLowCardinalityKeyValue("environment", activeProfile);
                    context.addLowCardinalityKeyValue("host", getHostname());
                    return context;
                });
    }

    /**
     * Configure common tags for all metrics in the MeterRegistry.
     * These tags help with filtering and aggregation in CloudWatch.
     */
    @Bean
    public MeterRegistryCustomizer meterRegistryCustomizer() {
        return registry -> registry.config().commonTags(
                Tags.of(
                        Tag.of("application", applicationName),
                        Tag.of("environment", activeProfile),
                        Tag.of("host", getHostname())
                )
        );
    }

    /**
     * Get the hostname for tagging metrics and traces.
     */
    private String getHostname() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            return "unknown";
        }
    }

    /**
     * Custom interface for MeterRegistry customization.
     */
    @FunctionalInterface
    public interface MeterRegistryCustomizer {
        void customize(MeterRegistry registry);
    }
}
