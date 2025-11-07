-- V4: Create photo_versions table
-- Stores processed versions (thumbnail, WebP renditions)

CREATE TYPE photo_version_type AS ENUM (
    'THUMBNAIL',
    'WEBP_640',
    'WEBP_1280',
    'WEBP_1920',
    'WEBP_2560'
);

CREATE TABLE IF NOT EXISTS photo_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    photo_id UUID NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    version_type photo_version_type NOT NULL,
    s3_key VARCHAR(1024) NOT NULL,
    file_size BIGINT NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_version_file_size_positive CHECK (file_size > 0),
    CONSTRAINT chk_version_dimensions_positive CHECK (width > 0 AND height > 0),
    CONSTRAINT uq_photo_version_type UNIQUE (photo_id, version_type)
);

-- Indexes
CREATE INDEX idx_photo_versions_photo_id ON photo_versions(photo_id);
CREATE INDEX idx_photo_versions_type ON photo_versions(version_type);
CREATE INDEX idx_photo_versions_s3_key ON photo_versions(s3_key);

-- Composite index for common queries
CREATE INDEX idx_photo_versions_photo_type ON photo_versions(photo_id, version_type);

-- Comments
COMMENT ON TABLE photo_versions IS 'Processed versions of photos (thumbnails and WebP renditions)';
COMMENT ON COLUMN photo_versions.version_type IS 'Type of processed version';
COMMENT ON COLUMN photo_versions.s3_key IS 'S3 key for processed file';
COMMENT ON COLUMN photo_versions.width IS 'Width of processed image in pixels';
COMMENT ON COLUMN photo_versions.height IS 'Height of processed image in pixels';
