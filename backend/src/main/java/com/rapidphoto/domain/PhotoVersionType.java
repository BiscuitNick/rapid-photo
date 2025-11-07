package com.rapidphoto.domain;

/**
 * Types of processed photo versions.
 */
public enum PhotoVersionType {
    THUMBNAIL,      // 300x300 center crop
    WEBP_640,       // 640px wide WebP
    WEBP_1280,      // 1280px wide WebP
    WEBP_1920,      // 1920px wide WebP
    WEBP_2560       // 2560px wide WebP
}
