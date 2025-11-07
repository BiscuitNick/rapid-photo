-- V3: Create photos table
-- Main photo entity after upload is confirmed

CREATE TYPE photo_status AS ENUM (
    'PENDING_PROCESSING',
    'PROCESSING',
    'READY',
    'FAILED'
);

CREATE TABLE IF NOT EXISTS photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    upload_job_id UUID NOT NULL REFERENCES upload_jobs(id),
    original_s3_key VARCHAR(1024) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    width INTEGER,
    height INTEGER,
    status photo_status NOT NULL DEFAULT 'PENDING_PROCESSING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    taken_at TIMESTAMP WITH TIME ZONE,
    camera_make VARCHAR(100),
    camera_model VARCHAR(100),
    gps_latitude DECIMAL(10, 8),
    gps_longitude DECIMAL(11, 8),
    error_message TEXT,
    CONSTRAINT chk_photo_file_size_positive CHECK (file_size > 0),
    CONSTRAINT chk_photo_dimensions CHECK ((width IS NULL AND height IS NULL) OR (width > 0 AND height > 0)),
    CONSTRAINT chk_photo_gps CHECK ((gps_latitude IS NULL AND gps_longitude IS NULL) OR (gps_latitude IS NOT NULL AND gps_longitude IS NOT NULL))
);

-- Indexes
CREATE INDEX idx_photos_user_id ON photos(user_id);
CREATE INDEX idx_photos_upload_job_id ON photos(upload_job_id);
CREATE INDEX idx_photos_status ON photos(status);
CREATE INDEX idx_photos_created_at ON photos(created_at DESC);
CREATE INDEX idx_photos_taken_at ON photos(taken_at DESC NULLS LAST);
CREATE INDEX idx_photos_original_s3_key ON photos(original_s3_key);

-- Composite indexes for common queries
CREATE INDEX idx_photos_user_status_created ON photos(user_id, status, created_at DESC);

-- Comments
COMMENT ON TABLE photos IS 'Main photo entities with metadata and processing status';
COMMENT ON COLUMN photos.original_s3_key IS 'S3 key for original uploaded file';
COMMENT ON COLUMN photos.width IS 'Original image width in pixels';
COMMENT ON COLUMN photos.height IS 'Original image height in pixels';
COMMENT ON COLUMN photos.taken_at IS 'EXIF DateTimeOriginal when photo was taken';
