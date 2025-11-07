package com.rapidphoto.domain;

/**
 * Status of photo processing lifecycle.
 */
public enum PhotoStatus {
    PENDING_PROCESSING,  // Photo uploaded, waiting for Lambda processing
    PROCESSING,          // Lambda is processing the photo
    READY,              // Photo fully processed and available
    FAILED              // Processing failed
}
