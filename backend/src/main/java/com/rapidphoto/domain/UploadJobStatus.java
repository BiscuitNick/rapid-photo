package com.rapidphoto.domain;

/**
 * Status of an upload job lifecycle.
 */
public enum UploadJobStatus {
    INITIATED,      // Presigned URL generated
    UPLOADING,      // Client is uploading
    UPLOADED,       // Upload completed to S3
    CONFIRMED,      // Upload confirmed and photo created
    FAILED,         // Upload failed
    EXPIRED         // Presigned URL expired
}
