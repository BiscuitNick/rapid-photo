-- V5: Relax constraints on photo_versions to allow missing dimensions/file size

ALTER TABLE photo_versions
    ALTER COLUMN file_size DROP NOT NULL,
    ALTER COLUMN height DROP NOT NULL,
    ALTER COLUMN mime_type DROP NOT NULL;

ALTER TABLE photo_versions
    DROP CONSTRAINT IF EXISTS chk_version_file_size_positive;

ALTER TABLE photo_versions
    DROP CONSTRAINT IF EXISTS chk_version_dimensions_positive;
