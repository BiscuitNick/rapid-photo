-- V1: Create users table
-- Users are managed by AWS Cognito, but we store additional metadata

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cognito_user_id VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    storage_quota_bytes BIGINT NOT NULL DEFAULT 10737418240, -- 10GB default
    storage_used_bytes BIGINT NOT NULL DEFAULT 0
);

-- Indexes
CREATE INDEX idx_users_cognito_user_id ON users(cognito_user_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- Comments
COMMENT ON TABLE users IS 'User accounts with Cognito integration';
COMMENT ON COLUMN users.cognito_user_id IS 'AWS Cognito sub claim from JWT';
COMMENT ON COLUMN users.storage_quota_bytes IS 'Maximum storage allowed in bytes';
COMMENT ON COLUMN users.storage_used_bytes IS 'Current storage used in bytes';
