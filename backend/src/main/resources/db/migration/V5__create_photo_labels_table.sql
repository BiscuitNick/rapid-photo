-- V5: Create photo_labels table
-- Stores AI-detected labels from AWS Rekognition

-- Create extension for trigram similarity search (must be first)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS photo_labels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    photo_id UUID NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    label_name VARCHAR(255) NOT NULL,
    confidence DECIMAL(5, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_confidence_range CHECK (confidence >= 0 AND confidence <= 100),
    CONSTRAINT uq_photo_label UNIQUE (photo_id, label_name)
);

-- Indexes
CREATE INDEX idx_photo_labels_photo_id ON photo_labels(photo_id);
CREATE INDEX idx_photo_labels_label_name ON photo_labels(label_name);
CREATE INDEX idx_photo_labels_confidence ON photo_labels(confidence DESC);

-- Composite index for tag search
CREATE INDEX idx_photo_labels_label_confidence ON photo_labels(label_name, confidence DESC);

-- GIN index for full-text search on labels (if needed in future)
CREATE INDEX idx_photo_labels_label_name_gin ON photo_labels USING gin(label_name gin_trgm_ops);

-- Comments
COMMENT ON TABLE photo_labels IS 'AI-detected labels from AWS Rekognition';
COMMENT ON COLUMN photo_labels.label_name IS 'Label/tag name detected by Rekognition';
COMMENT ON COLUMN photo_labels.confidence IS 'Confidence score from Rekognition (0-100)';

-- Create a view for easy tag-based photo search
CREATE OR REPLACE VIEW photo_tags_view AS
SELECT
    p.id AS photo_id,
    p.user_id,
    p.file_name,
    p.created_at,
    p.status,
    pl.label_name AS tag,
    pl.confidence
FROM photos p
LEFT JOIN photo_labels pl ON p.id = pl.photo_id
WHERE p.status = 'READY'
ORDER BY p.created_at DESC;

COMMENT ON VIEW photo_tags_view IS 'Convenient view for tag-based photo queries';
