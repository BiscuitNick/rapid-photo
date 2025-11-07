-- V2: Create upload_jobs table
-- Tracks presigned URL generation and upload lifecycle

CREATE TYPE upload_job_status AS ENUM (
    'INITIATED',
    'UPLOADING',
    'UPLOADED',
    'CONFIRMED',
    'FAILED',
    'EXPIRED'
);

CREATE TABLE IF NOT EXISTS upload_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    s3_key VARCHAR(1024) NOT NULL,
    presigned_url TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    status upload_job_status NOT NULL DEFAULT 'INITIATED',
    etag VARCHAR(255),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    CONSTRAINT chk_file_size_positive CHECK (file_size > 0),
    CONSTRAINT chk_expires_after_created CHECK (expires_at > created_at)
);

-- Indexes
CREATE INDEX idx_upload_jobs_user_id ON upload_jobs(user_id);
CREATE INDEX idx_upload_jobs_status ON upload_jobs(status);
CREATE INDEX idx_upload_jobs_created_at ON upload_jobs(created_at DESC);
CREATE INDEX idx_upload_jobs_expires_at ON upload_jobs(expires_at);
CREATE INDEX idx_upload_jobs_s3_key ON upload_jobs(s3_key);

-- Comments
COMMENT ON TABLE upload_jobs IS 'Tracks presigned URL uploads and their lifecycle';
COMMENT ON COLUMN upload_jobs.s3_key IS 'S3 object key in format: originals/{userId}/{uuid}';
COMMENT ON COLUMN upload_jobs.presigned_url IS 'Temporary presigned PUT URL (expires after 1 hour)';
COMMENT ON COLUMN upload_jobs.etag IS 'S3 ETag returned after successful upload';
