# Product Requirements Document: RapidPhotoUpload
## AI-Assisted High-Volume Photo Upload System

**Version:** 2.0 (Updated)  
**Date:** November 7, 2025  
**Status:** Final Specification - Updated with Latest Library Versions

---

## 1. Executive Summary

RapidPhotoUpload is a production-grade, high-performance photo upload and management platform supporting 100 concurrent uploads with real-time processing, AI-powered tagging, and multi-platform access (Flutter mobile + React web). The system demonstrates enterprise-level architectural patterns including DDD, CQRS, VSA, event-driven processing, and reactive programming.

**Key Metrics:**
- **Concurrency:** 100 simultaneous uploads per user session
- **Upload Time:** 100 photos (2MB avg) in ≤90 seconds
- **Processing:** Automated thumbnail generation, WebP optimization, AI tagging
- **Platforms:** Flutter mobile app + React web application + Spring WebFlux backend

---

## 2. Business Requirements

### 2.1 Core Functionality

| Feature | Description | Priority |
|---------|-------------|----------|
| High-Volume Upload | Support 100 concurrent photo uploads per session | P0 |
| Real-Time Progress | Individual and batch upload status with progress indicators | P0 |
| Async UI | Non-blocking interface during uploads (mobile + web) | P0 |
| Photo Gallery | View, search, filter uploaded photos with metadata | P0 |
| AI Tagging | Automatic categorization using AWS Rekognition | P1 |
| Image Optimization | Multi-resolution WebP conversion + thumbnails | P1 |
| Secure Auth | AWS Amplify authentication (mobile + web) | P0 |
| Download | Individual and batch photo downloads | P1 |

### 2.2 User Stories

**US-001:** As a user, I can select and upload up to 100 photos simultaneously while continuing to browse the app.

**US-002:** As a user, I see real-time progress for each upload with status indicators (queued, uploading, processing, complete, failed).

**US-003:** As a user, I can view all my uploaded photos in a gallery with thumbnails, sorted by date or tags.

**US-004:** As a user, I can search photos by AI-generated tags (e.g., "beach", "sunset", "people").

**US-005:** As a user, I can download photos in their original resolution or optimized formats.

---

## 3. Technical Architecture

### 3.1 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
├──────────────────────────────┬──────────────────────────────────┤
│   Flutter Mobile (Riverpod)  │   React Web (Tailwind/shadcn)   │
│   - Photo Picker             │   - Gallery View                 │
│   - Upload Queue Manager     │   - Batch Operations             │
│   - Progress Tracking        │   - Search/Filter                │
└──────────────┬───────────────┴────────────┬─────────────────────┘
               │                            │
               │         AWS Amplify Auth   │
               │                            │
┌──────────────▼────────────────────────────▼─────────────────────┐
│                   API GATEWAY + ALB                              │
└──────────────┬───────────────────────────────────────────────────┘
               │
┌──────────────▼───────────────────────────────────────────────────┐
│              SPRING WEBFLUX API (ECS Fargate)                    │
├──────────────────────────────────────────────────────────────────┤
│  Vertical Slices:                                                │
│  • GeneratePresignedUrlSlice (Command)                           │
│  • ConfirmUploadSlice (Command)                                  │
│  • GetPhotosSlice (Query)                                        │
│  • GetPhotoMetadataSlice (Query)                                 │
│  • SearchPhotosByTagSlice (Query)                                │
│                                                                  │
│  DDD Domain Models:                                              │
│  • Photo (Aggregate Root)                                        │
│  • UploadJob (Entity)                                            │
│  • User (Aggregate Root)                                         │
│  • PhotoMetadata (Value Object)                                  │
│                                                                  │
│  CQRS: Commands → Domain → Events | Queries → Read Models       │
└────┬─────────────────────────────────────────────┬───────────────┘
     │                                             │
     │ R2DBC (Reactive)                            │ Presigned URLs
     │                                             │
┌────▼─────────────────┐              ┌───────────▼──────────────┐
│   RDS PostgreSQL     │              │      AWS S3 Bucket       │
│   - Users            │              │  - originals/            │
│   - Photos           │              │  - processed/            │
│   - UploadJobs       │              │    ├─ thumbnails/        │
│   - PhotoTags        │              │    ├─ 320/640/1024/      │
└──────────────────────┘              │    └─ 1600/2560/         │
                                      └───────────┬──────────────┘
                                                  │ S3 Event
                                      ┌───────────▼──────────────┐
                                      │       SQS Queue          │
                                      │  - DLQ for failures      │
                                      └───────────┬──────────────┘
                                                  │
                                      ┌───────────▼──────────────┐
                                      │   Lambda: ImageProcessor │
                                      │   (Python 3.13)          │
                                      ├──────────────────────────┤
                                      │  Dependencies:           │
                                      │  - Pillow (PIL) 11.x     │
                                      │  - boto3 1.35.96+        │
                                      │  - psycopg2-binary 2.9+  │
                                      ├──────────────────────────┤
                                      │  1. Generate thumbnails  │
                                      │  2. Create WebP versions │
                                      │  3. Call Rekognition     │
                                      │  4. Update PostgreSQL    │
                                      │  5. Publish completion   │
                                      └──────────────────────────┘
                                                  │
                                      ┌───────────▼──────────────┐
                                      │   AWS Rekognition        │
                                      │   - Label Detection      │
                                      │   - Scene Detection      │
                                      └──────────────────────────┘
```

### 3.2 Technology Stack (UPDATED)

| Layer | Technology | **Version** | Justification |
|-------|------------|-------------|---------------|
| **Mobile** | Flutter | **3.27+** | Latest stable, improved performance, full Material 3 |
| **State Mgmt** | Riverpod | **3.0.1** (flutter_riverpod) | Type-safe AsyncNotifier, improved code generation |
| **Web** | React | **19.2.0** + TypeScript 5.x | Server Components, improved concurrency features |
| **Web UI** | Tailwind CSS + shadcn/ui | **3.4.17 + Latest** | Rapid development, consistent design system |
| **Backend** | Spring Boot + WebFlux | **3.5.3** | Latest stable, improved observability & performance |
| **Java** | OpenJDK | **17 (min), 21 recommended** | Spring Boot 3.5.3 requirement, LTS support |
| **Build Tool** | Gradle | **8.1.1+** or Maven **3.8.5+** | Required for Spring Boot 3.5.3 |
| **Database** | PostgreSQL | **17.6** | Latest stable, improved query planner, better JSON |
| **DB Driver** | R2DBC PostgreSQL | **Latest (Spring managed)** | Reactive, non-blocking database access |
| **Storage** | AWS S3 | **Current API** | Scalable, durable (99.999999999%) |
| **Processing** | AWS Lambda | **Python 3.13 runtime** | Latest stable, improved performance |
| **Image Library** | Pillow (PIL) | **11.x** | Latest stable, improved WebP support |
| **AI Tagging** | AWS Rekognition | **Current API** | Pre-trained models, high accuracy |
| **Auth** | AWS Amplify + Cognito | **Gen 2 (v6.x JS, v2.7 Flutter)** | TypeScript-first, improved DX |
| **Queue** | AWS SQS | **Current API** | Reliable message delivery, DLQ support |
| **Monitoring** | CloudWatch + X-Ray | **Current APIs** | Native AWS integration, distributed tracing |
| **Container** | Docker + ECS Fargate | **Latest Platform Version** | Serverless containers, auto-scaling |
| **IaC** | Terraform | **1.9.x+** | Latest stable, version control infrastructure |

### 3.3 Architectural Patterns

**Domain-Driven Design (DDD):**
- Bounded contexts: Upload, Gallery, User Management
- Aggregates: Photo, User, UploadJob
- Value Objects: PhotoMetadata, ImageDimensions, TagCollection
- Domain Events: PhotoUploaded, ProcessingCompleted, TagsGenerated

**CQRS (Command Query Responsibility Segregation):**
- **Commands:** GeneratePresignedUrl, ConfirmUpload, DeletePhoto
- **Queries:** GetPhotos, GetPhotosByTag, GetUploadStatus
- Separate read/write models for optimization

**Vertical Slice Architecture (VSA):**
```
src/
├── features/
│   ├── upload/
│   │   ├── GeneratePresignedUrlSlice.java
│   │   ├── ConfirmUploadSlice.java
│   │   └── domain/
│   ├── gallery/
│   │   ├── GetPhotosSlice.java
│   │   ├── SearchPhotosByTagSlice.java
│   │   └── domain/
│   └── processing/
│       └── ImageProcessingService.java
└── shared/
    ├── domain/
    └── infrastructure/
```

### 3.4 Upload Flow (Direct S3 Upload)

1. **Client requests presigned URL** from Spring WebFlux API
   - `POST /api/v1/uploads/initiate`
   - Payload: `{ fileName, fileSize, mimeType }`
   - Response: `{ uploadId, presignedUrl, expiresIn, s3Key }`

2. **Client uploads directly to S3** using presigned URL
   - `PUT https://s3.amazonaws.com/bucket/originals/{key}`
   - Headers: `Content-Type`, `x-amz-meta-user-id`

3. **Client confirms upload** to Spring WebFlux
   - `POST /api/v1/uploads/{uploadId}/confirm`
   - API creates Photo record with status: `PENDING_PROCESSING`

4. **S3 event triggers** SQS message → Lambda
   - Lambda reads S3 object metadata
   - Generates thumbnails (300x300 square, center-crop)
   - Creates multi-resolution WebP (320, 640, 1024, 1600, 2560 max-width @ 80% quality)
   - Calls Rekognition for labels/tags
   - Updates Photo record: status `COMPLETE`, adds tags, URLs

5. **Client polls or receives WebSocket notification**
   - `GET /api/v1/photos/{photoId}/status`
   - Status: `COMPLETE` with all processed URLs

### 3.5 Image Processing Specifications

**Thumbnail:**
- Size: 300x300 pixels (square)
- Method: Center-crop (maintain aspect ratio, crop excess)
- Format: WebP @ 80% quality
- Path: `s3://bucket/processed/thumbnails/{photoId}.webp`

**Multi-Resolution WebP:**
- Max widths: 320, 640, 1024, 1600, 2560 pixels
- Maintain aspect ratio (height auto-calculated)
- Quality: 80%
- Paths: `s3://bucket/processed/{width}/{photoId}.webp`
- Original preserved: `s3://bucket/originals/{photoId}.{ext}`

**AI Tagging:**
- Service: AWS Rekognition DetectLabels
- Confidence threshold: ≥80%
- Max labels: 20 per image
- Categories: Objects, Scenes, Activities, Concepts

---

## 4. API Specifications

### 4.1 REST API Endpoints

#### Authentication (AWS Amplify handled)
- Sign Up: Amplify SDK handles
- Sign In: Amplify SDK handles
- Token Refresh: Automatic via Amplify

#### Upload Management

**POST /api/v1/uploads/initiate**
```json
Request:
{
  "fileName": "beach-sunset.jpg",
  "fileSize": 2048576,
  "mimeType": "image/jpeg"
}

Response: 201 Created
{
  "uploadId": "upl_abc123",
  "presignedUrl": "https://s3.amazonaws.com/...",
  "expiresIn": 900,
  "s3Key": "originals/user123/uuid.jpg"
}
```

**POST /api/v1/uploads/{uploadId}/confirm**
```json
Request:
{
  "uploadId": "upl_abc123",
  "etag": "d41d8cd98f00b204e9800998ecf8427e"
}

Response: 200 OK
{
  "photoId": "pho_xyz789",
  "status": "PENDING_PROCESSING"
}
```

**GET /api/v1/uploads/batch/status?uploadIds=id1,id2,id3**
```json
Response: 200 OK
{
  "statuses": [
    { "uploadId": "id1", "status": "COMPLETE", "photoId": "pho_1" },
    { "uploadId": "id2", "status": "PROCESSING", "photoId": "pho_2" },
    { "uploadId": "id3", "status": "FAILED", "error": "Invalid format" }
  ]
}
```

#### Gallery Management

**GET /api/v1/photos?page=0&size=50&sort=createdAt,desc**
```json
Response: 200 OK
{
  "content": [
    {
      "photoId": "pho_xyz789",
      "originalUrl": "https://s3.../originals/photo.jpg",
      "thumbnailUrl": "https://s3.../thumbnails/photo.webp",
      "processedUrls": {
        "320": "https://s3.../320/photo.webp",
        "640": "https://s3.../640/photo.webp",
        ...
      },
      "tags": ["beach", "sunset", "ocean", "sky"],
      "metadata": {
        "width": 4032,
        "height": 3024,
        "size": 2048576,
        "capturedAt": "2025-11-07T10:30:00Z"
      },
      "createdAt": "2025-11-07T14:20:00Z"
    }
  ],
  "page": 0,
  "size": 50,
  "totalElements": 1250,
  "totalPages": 25
}
```

**GET /api/v1/photos/search?tags=beach,sunset&page=0&size=20**
```json
Response: 200 OK
{
  "content": [ /* Photo objects matching tags */ ],
  "matchedTags": ["beach", "sunset"],
  "page": 0,
  "totalElements": 45
}
```

**GET /api/v1/photos/{photoId}**
```json
Response: 200 OK
{
  "photoId": "pho_xyz789",
  "originalUrl": "https://s3.../originals/photo.jpg",
  "thumbnailUrl": "https://s3.../thumbnails/photo.webp",
  "processedUrls": { ... },
  "tags": [ ... ],
  "metadata": { ... }
}
```

**DELETE /api/v1/photos/{photoId}**
```json
Response: 204 No Content
```

### 4.2 WebSocket Events (Optional for real-time updates)

**Connection:** `wss://api.example.com/ws?token={jwt}`

**Events:**
```json
// Upload progress
{
  "event": "upload.progress",
  "uploadId": "upl_abc123",
  "bytesUploaded": 1048576,
  "totalBytes": 2048576,
  "percentage": 51.2
}

// Processing complete
{
  "event": "photo.processing.complete",
  "photoId": "pho_xyz789",
  "thumbnailUrl": "https://...",
  "tags": ["beach", "sunset"]
}
```

---

## 5. Database Schema

### 5.1 PostgreSQL Tables (PostgreSQL 17.6)

**users**
```sql
CREATE TABLE users (
    user_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cognito_user_id VARCHAR(255) UNIQUE NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_cognito ON users(cognito_user_id);
```

**photos**
```sql
CREATE TABLE photos (
    photo_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    original_key      VARCHAR(500) NOT NULL,
    original_url      VARCHAR(1000) NOT NULL,
    thumbnail_key     VARCHAR(500),
    thumbnail_url     VARCHAR(1000),
    file_name         VARCHAR(255) NOT NULL,
    file_size         BIGINT NOT NULL,
    mime_type         VARCHAR(100) NOT NULL,
    width             INTEGER,
    height            INTEGER,
    status            VARCHAR(50) NOT NULL, -- PENDING_PROCESSING, PROCESSING, COMPLETE, FAILED
    error_message     TEXT,
    metadata          JSONB, -- EXIF data, camera info, etc.
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at      TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_photos_user_id ON photos(user_id);
CREATE INDEX idx_photos_status ON photos(status);
CREATE INDEX idx_photos_created_at ON photos(created_at DESC);
```

**photo_versions**
```sql
CREATE TABLE photo_versions (
    version_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    photo_id      UUID NOT NULL REFERENCES photos(photo_id) ON DELETE CASCADE,
    width         INTEGER NOT NULL,
    s3_key        VARCHAR(500) NOT NULL,
    url           VARCHAR(1000) NOT NULL,
    file_size     BIGINT NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_photo_versions_photo_id ON photo_versions(photo_id);
```

**photo_tags**
```sql
CREATE TABLE photo_tags (
    tag_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    photo_id    UUID NOT NULL REFERENCES photos(photo_id) ON DELETE CASCADE,
    tag_name    VARCHAR(100) NOT NULL,
    confidence  DECIMAL(5,2), -- Rekognition confidence score
    source      VARCHAR(50) NOT NULL, -- 'REKOGNITION' or 'USER'
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_photo_tags_photo_id ON photo_tags(photo_id);
CREATE INDEX idx_photo_tags_tag_name ON photo_tags(tag_name);
CREATE INDEX idx_photo_tags_composite ON photo_tags(tag_name, photo_id);
```

**upload_jobs**
```sql
CREATE TABLE upload_jobs (
    upload_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    photo_id        UUID REFERENCES photos(photo_id) ON DELETE SET NULL,
    s3_key          VARCHAR(500) NOT NULL,
    presigned_url   TEXT NOT NULL,
    file_name       VARCHAR(255) NOT NULL,
    file_size       BIGINT NOT NULL,
    mime_type       VARCHAR(100) NOT NULL,
    status          VARCHAR(50) NOT NULL, -- INITIATED, CONFIRMED, FAILED, EXPIRED
    etag            VARCHAR(255),
    error_message   TEXT,
    expires_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    confirmed_at    TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_upload_jobs_user_id ON upload_jobs(user_id);
CREATE INDEX idx_upload_jobs_status ON upload_jobs(status);
```

---

## 6. Updated Dependencies & Configuration

### 6.1 Backend Dependencies (Spring Boot 3.5.3)

**Maven (pom.xml)**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.5.3</version>
        <relativePath/>
    </parent>
    
    <groupId>com.rapidphoto</groupId>
    <artifactId>rapidphoto-backend</artifactId>
    <version>1.0.0</version>
    <name>RapidPhotoUpload Backend</name>
    
    <properties>
        <java.version>17</java.version>
        <spring-cloud-aws.version>3.2.1</spring-cloud-aws.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-r2dbc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <!-- R2DBC PostgreSQL Driver -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>r2dbc-postgresql</artifactId>
        </dependency>
        
        <!-- Flyway for Database Migrations -->
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-database-postgresql</artifactId>
        </dependency>
        
        <!-- AWS SDK v2 -->
        <dependency>
            <groupId>io.awspring.cloud</groupId>
            <artifactId>spring-cloud-aws-starter-s3</artifactId>
        </dependency>
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>sqs</artifactId>
        </dependency>
        
        <!-- Observability -->
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-tracing-bridge-brave</artifactId>
        </dependency>
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-cloudwatch2</artifactId>
        </dependency>
        
        <!-- Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>io.projectreactor</groupId>
            <artifactId>reactor-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>postgresql</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>io.awspring.cloud</groupId>
                <artifactId>spring-cloud-aws-dependencies</artifactId>
                <version>${spring-cloud-aws.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

**Gradle (build.gradle)**
```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.5.3'
    id 'io.spring.dependency-management' version '1.1.7'
}

group = 'com.rapidphoto'
version = '1.0.0'
sourceCompatibility = '17'

repositories {
    mavenCentral()
}

ext {
    set('springCloudAwsVersion', "3.2.1")
}

dependencies {
    // Spring Boot Starters
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
    implementation 'org.springframework.boot:spring-boot-starter-data-r2dbc'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    
    // R2DBC PostgreSQL
    implementation 'org.postgresql:r2dbc-postgresql'
    
    // Flyway
    implementation 'org.flywaydb:flyway-core'
    implementation 'org.flywaydb:flyway-database-postgresql'
    
    // AWS
    implementation 'io.awspring.cloud:spring-cloud-aws-starter-s3'
    implementation 'software.amazon.awssdk:sqs'
    
    // Observability
    implementation 'io.micrometer:micrometer-tracing-bridge-brave'
    implementation 'io.micrometer:micrometer-registry-cloudwatch2'
    
    // Validation
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    
    // Lombok
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    
    // Testing
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'io.projectreactor:reactor-test'
    testImplementation 'org.testcontainers:postgresql'
}

dependencyManagement {
    imports {
        mavenBom "io.awspring.cloud:spring-cloud-aws-dependencies:${springCloudAwsVersion}"
    }
}

tasks.named('test') {
    useJUnitPlatform()
}
```

**application.yml**
```yaml
spring:
  application:
    name: rapidphoto-api
  
  r2dbc:
    url: r2dbc:postgresql://localhost:5432/rapidphoto
    username: postgres
    password: ${DB_PASSWORD}
    pool:
      initial-size: 10
      max-size: 50
  
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true

server:
  port: 8080

aws:
  region: us-east-1
  s3:
    bucket-name: rapidphoto-${ENVIRONMENT}-media
  sqs:
    upload-queue-url: ${SQS_UPLOAD_QUEUE_URL}

management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  metrics:
    export:
      cloudwatch:
        namespace: RapidPhoto
        step: 1m
  tracing:
    sampling:
      probability: 1.0
```

### 6.2 Flutter Dependencies (3.27+)

**pubspec.yaml**
```yaml
name: rapidphoto_mobile
description: RapidPhotoUpload Flutter Mobile App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: ">=3.27.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^3.0.1
  riverpod_annotation: ^2.6.0
  
  # AWS Amplify Gen 2
  amplify_flutter: ^2.7.0
  amplify_auth_cognito: ^2.7.0
  amplify_storage_s3: ^2.7.0
  
  # HTTP & API
  dio: ^5.7.0
  retrofit: ^4.4.1
  
  # Image Handling
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  photo_view: ^0.15.0
  
  # UI Components
  flutter_hooks: ^0.20.5
  
  # Utilities
  uuid: ^4.5.1
  path_provider: ^2.1.5
  shared_preferences: ^2.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  riverpod_generator: ^2.6.0
  build_runner: ^2.4.13
  
  # Linting
  flutter_lints: ^5.0.0
  
  # Testing
  mockito: ^5.4.4
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
```

### 6.3 React Web Dependencies (19.2.0)

**package.json**
```json
{
  "name": "rapidphoto-web",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:e2e": "playwright test"
  },
  "dependencies": {
    "react": "^19.2.0",
    "react-dom": "^19.2.0",
    "react-router-dom": "^7.9.4",
    
    "@aws-amplify/ui-react": "^6.5.4",
    "aws-amplify": "^6.9.0",
    
    "axios": "^1.7.9",
    "@tanstack/react-query": "^5.62.3",
    "zustand": "^5.0.2",
    
    "tailwindcss": "^3.4.17",
    "@radix-ui/react-dialog": "^1.1.4",
    "@radix-ui/react-dropdown-menu": "^2.1.4",
    "@radix-ui/react-progress": "^1.1.1",
    "@radix-ui/react-toast": "^1.2.4",
    
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.6.0",
    "lucide-react": "^0.468.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.6",
    "@types/react-dom": "^19.0.2",
    "typescript": "^5.7.2",
    
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.5",
    
    "vitest": "^2.1.8",
    "@testing-library/react": "^16.1.0",
    "@testing-library/jest-dom": "^6.6.3",
    "@testing-library/user-event": "^14.5.2",
    
    "playwright": "^1.49.1",
    
    "eslint": "^9.16.0",
    "prettier": "^3.4.2",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.49"
  },
  "engines": {
    "node": ">=18.17.0",
    "npm": ">=9.0.0"
  }
}
```

### 6.4 Lambda Function Dependencies (Python 3.13)

**requirements.txt**
```txt
boto3>=1.35.96
Pillow>=11.0.0
psycopg2-binary>=2.9.10
```

**Lambda Configuration**
```yaml
# AWS SAM template.yaml or Terraform configuration
Runtime: python3.13
Architecture: arm64  # Graviton2 for better price/performance
Handler: handler.lambda_handler
MemorySize: 3008
Timeout: 300
Environment:
  Variables:
    DB_HOST: !Ref RDSEndpoint
    DB_NAME: rapidphoto
    DB_USER: lambda_user
    S3_BUCKET: !Ref MediaBucket
```

---

## 7. Docker Configuration

### 7.1 Backend Dockerfile (Multi-stage)

```dockerfile
# Stage 1: Build
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app

# Copy dependency files
COPY pom.xml .
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy JAR from builder
COPY --from=builder /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# JVM optimization flags
ENV JAVA_OPTS="-XX:+UseZGC -XX:MaxRAMPercentage=75.0 -XX:+UseStringDeduplication"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### 7.2 Lambda Dockerfile (Python 3.13)

```dockerfile
FROM public.ecr.aws/lambda/python:3.13

# Install system dependencies for Pillow
RUN dnf install -y \
    gcc \
    libjpeg-turbo-devel \
    zlib-devel \
    freetype-devel \
    lcms2-devel \
    openjpeg2-devel \
    libtiff-devel \
    libwebp-devel \
    && dnf clean all

# Copy requirements
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy function code
COPY handler.py ${LAMBDA_TASK_ROOT}/
COPY image_processor.py ${LAMBDA_TASK_ROOT}/
COPY thumbnail_generator.py ${LAMBDA_TASK_ROOT}/
COPY webp_converter.py ${LAMBDA_TASK_ROOT}/
COPY rekognition_service.py ${LAMBDA_TASK_ROOT}/

# Lambda handler
CMD ["handler.lambda_handler"]
```

---

## 8. Testing Strategy

### 8.1 Test Coverage Requirements

| Test Type | Coverage | Tools |
|-----------|----------|-------|
| Unit Tests | 80%+ | JUnit 5, Mockito, Flutter Test, Vitest |
| Integration Tests | Critical paths | Spring WebFlux Test, Testcontainers |
| E2E Tests | Key user flows | Patrol (Flutter), Playwright (React) |
| Load Tests | 100 concurrent uploads | JMeter, K6 |
| Contract Tests | API contracts | Spring Cloud Contract |

### 8.2 Key Test Scenarios

**TS-001: 100 Concurrent Upload Simulation**
```java
@Test
void testConcurrentUploads() {
    // Simulate 100 simultaneous presigned URL requests
    List<Mono<PresignedUrlResponse>> requests = IntStream.range(0, 100)
        .mapToObj(i -> uploadService.generatePresignedUrl(createRequest(i)))
        .collect(Collectors.toList());
    
    // Execute all requests concurrently
    StepVerifier.create(Flux.merge(requests))
        .expectNextCount(100)
        .expectComplete()
        .verify(Duration.ofSeconds(5));
    
    // Verify no errors and all URLs valid
    assertThat(errors).isEmpty();
}
```

**TS-002: Spring Boot 3.5.3 Observability**
```java
@Test
@WithMockUser
void testUploadObservability() {
    // Execute upload
    webTestClient.post()
        .uri("/api/v1/uploads/initiate")
        .bodyValue(request)
        .exchange()
        .expectStatus().isCreated();
    
    // Verify metrics recorded
    MeterRegistry registry = applicationContext.getBean(MeterRegistry.class);
    assertThat(registry.get("upload.presigned.url.generation").timer().count())
        .isEqualTo(1);
}
```

**TS-003: React 19 Concurrent Rendering**
```typescript
import { render, screen, waitFor } from '@testing-library/react';
import { act } from 'react';

test('handles 100 concurrent uploads without UI freeze', async () => {
  const { container } = render(<UploadQueue />);
  
  // Add 100 files
  const files = Array.from({ length: 100 }, (_, i) => 
    new File([`content${i}`], `photo${i}.jpg`, { type: 'image/jpeg' })
  );
  
  // Trigger concurrent uploads
  await act(async () => {
    files.forEach(file => uploadQueue.add(file));
  });
  
  // Verify UI remains responsive
  await waitFor(() => {
    expect(screen.getByText('100 uploads complete')).toBeInTheDocument();
  }, { timeout: 10000 });
  
  // Verify no UI blocking
  expect(performance.now() - startTime).toBeLessThan(100); // Under 100ms
});
```

**TS-004: Flutter 3.27 Material 3 Upload UI**
```dart
testWidgets('Upload progress displays correctly', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: UploadScreen()),
    ),
  );
  
  // Add 100 photos to queue
  final container = ProviderContainer();
  final notifier = container.read(uploadQueueProvider.notifier);
  
  for (var i = 0; i < 100; i++) {
    notifier.addToQueue(mockPhoto(i));
  }
  
  await tester.pumpAndSettle();
  
  // Verify Material 3 progress indicators
  expect(find.byType(CircularProgressIndicator), findsNWidgets(100));
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});
```

**TS-005: PostgreSQL 17 Performance**
```java
@Test
void testPostgres17QueryPerformance() {
    // Insert 10,000 photos
    Flux.range(0, 10000)
        .flatMap(i -> photoRepository.save(createPhoto(i)))
        .blockLast();
    
    // Measure query performance
    long startTime = System.currentTimeMillis();
    
    List<Photo> results = photoRepository
        .findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, 50))
        .collectList()
        .block();
    
    long duration = System.currentTimeMillis() - startTime;
    
    // Assert query completes in <100ms (PostgreSQL 17 optimization)
    assertThat(duration).isLessThan(100);
    assertThat(results).hasSize(50);
}
```

---

## 9. Monitoring & Observability

### 9.1 CloudWatch Configuration

**Logs:**
- `/aws/ecs/rapidphoto-api` - Spring WebFlux application logs
- `/aws/lambda/image-processor` - Lambda function logs
- `/aws/sqs/upload-queue` - SQS message logs

**Metrics (Custom):**
- `UploadSuccess` - Counter (Dimensions: UserId)
- `UploadFailure` - Counter (Dimensions: UserId, ErrorType)
- `PresignedUrlGeneration` - Timer (Percentiles: p50, p95, p99)
- `ProcessingDuration` - Timer (Dimensions: ImageSize)
- `RekognitionTagCount` - Histogram

**Alarms (Must-Have):**
- API Error Rate > 5% (5 minutes)
- Lambda Error Rate > 2% (5 minutes)
- SQS DLQ Messages > 10 (immediate)
- RDS CPU > 80% (5 minutes)
- ECS Task Count < 2 (1 minute)
- S3 Upload Failures > 50/hour

### 9.2 CloudWatch Dashboard (RED/USE)

**RED Metrics (Requests, Errors, Duration):**
- API Request Rate (req/sec)
- API Error Rate (%)
- API Latency (p50, p95, p99)

**USE Metrics (Utilization, Saturation, Errors):**
- ECS CPU/Memory Utilization (%)
- RDS Connections (active/max)
- SQS Queue Depth (messages)
- Lambda Concurrent Executions (count/limit)

### 9.3 X-Ray Tracing (Spring Boot 3.5.3)

```java
@Configuration
public class ObservabilityConfig {
    
    @Bean
    public ObservationHandler<Context> xrayObservationHandler() {
        return new XRayObservationHandler();
    }
    
    @Bean
    public ObservationRegistryCustomizer<ObservationRegistry> 
            observationRegistryCustomizer() {
        return registry -> {
            registry.observationConfig()
                .observationHandler(new ObservationTextPublisher());
        };
    }
}

// Use @Observed annotation for tracing
@Service
public class UploadService {
    
    @Observed(name = "upload.presigned.url", 
              contextualName = "generate-presigned-url")
    public Mono<PresignedUrlResponse> generatePresignedUrl(
            PresignedUrlRequest request) {
        // Implementation
    }
}
```

---

## 10. Deployment Architecture

### 10.1 Infrastructure (AWS)

**Compute:**
- **ECS Fargate:** Spring WebFlux API (2 tasks min, 10 max)
  - CPU: 1 vCPU, Memory: 2 GB
  - Auto-scaling: Target CPU 70%
  - Platform Version: LATEST
- **Lambda:** Image processing (Python 3.13 runtime, arm64)
  - Memory: 3008 MB
  - Timeout: 5 minutes
  - Reserved Concurrency: 100

**Storage:**
- **S3 Bucket:** `rapidphoto-{env}-media`
  - Lifecycle: Move to Glacier after 1 year
  - Versioning: Disabled
  - Encryption: AES-256 (SSE-S3)
- **RDS PostgreSQL 17.6:** db.t4g.medium (2 vCPU, 4 GB RAM)
  - Multi-AZ: No (dev), Yes (prod)
  - Backup retention: 7 days
  - Engine: PostgreSQL 17.6

**Networking:**
- **VPC:** 10.0.0.0/16
  - Public Subnets: 10.0.1.0/24, 10.0.2.0/24 (ALB)
  - Private Subnets: 10.0.10.0/24, 10.0.11.0/24 (ECS, RDS)
- **ALB:** Application Load Balancer (internet-facing)
- **NAT Gateway:** 1 per AZ (for ECS → S3/Rekognition)

**Security:**
- **IAM Roles:**
  - ECS Task Role: S3 read/write, SQS publish, CloudWatch logs
  - Lambda Execution Role: S3 read/write, Rekognition, RDS access
- **Security Groups:**
  - ALB: Ingress 443 (HTTPS)
  - ECS: Ingress 8080 from ALB
  - RDS: Ingress 5432 from ECS/Lambda

### 10.2 Terraform Configuration

**terraform/main.tf**
```hcl
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "rapidphoto-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "RapidPhotoUpload"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "./modules/vpc"
  
  cidr_block           = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  environment          = var.environment
}

module "rds" {
  source = "./modules/rds"
  
  engine_version       = "17.6"
  instance_class       = "db.t4g.medium"
  allocated_storage    = 100
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  multi_az             = var.environment == "prod"
}

module "ecs" {
  source = "./modules/ecs"
  
  cluster_name         = "rapidphoto-${var.environment}"
  task_cpu             = 1024
  task_memory          = 2048
  min_capacity         = 2
  max_capacity         = 10
  target_cpu_percent   = 70
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
}

module "lambda" {
  source = "./modules/lambda"
  
  function_name        = "rapidphoto-image-processor"
  runtime              = "python3.13"
  architecture         = "arm64"
  memory_size          = 3008
  timeout              = 300
  reserved_concurrency = 100
}
```

### 10.3 CI/CD Pipeline (GitHub Actions)

**.github/workflows/backend.yml**
```yaml
name: Backend CI/CD

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:17.6
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Cache Maven packages
        uses: actions/cache@v4
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
      
      - name: Run tests
        run: mvn clean test
      
      - name: Build
        run: mvn clean package -DskipTests
  
  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      
      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: rapidphoto-api
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
      
      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster rapidphoto-prod \
            --service rapidphoto-api \
            --force-new-deployment
```

---

## 11. Cost Analysis

### 11.1 Per-User Cost (1,000 Photos Uploaded)

**Assumptions:**
- Average photo size: 2 MB
- User uploads 1,000 photos over 30 days
- Photos stored for 1 year
- 500 photo views/month (50% thumbnail, 50% mid-res)

**AWS Service Costs:**

| Service | Calculation | Monthly Cost |
|---------|-------------|--------------|
| **S3 Storage** | Original: 2 GB @ $0.023/GB + Processed: 1.5 GB @ $0.023/GB | $0.08 |
| **S3 Requests** | 1,000 PUT (upload) @ $0.005/1k + 1,000 PUT (processing) @ $0.005/1k + 500 GET (views) @ $0.0004/1k | $0.01 |
| **Data Transfer** | 1 GB egress @ $0.09/GB | $0.09 |
| **Lambda Invocations** | 1,000 invocations @ $0.20/1M | $0.0002 |
| **Lambda Duration** | 1,000 × 10 sec @ 3 GB memory = 10,000 GB-sec @ $0.0000166667/GB-sec | $0.17 |
| **Rekognition** | 1,000 images @ $0.001/image | $1.00 |
| **SQS** | 1,000 messages @ $0.40/1M | $0.0004 |
| **RDS (allocated)** | db.t4g.medium ($0.073/hr × 730 hrs) ÷ 1,000 users | $0.05 |
| **ECS Fargate (allocated)** | 1 vCPU × 730 hrs ($0.04048/hr) + 2 GB × 730 hrs ($0.004445/hr) ÷ 1,000 users | $0.04 |
| **Data Transfer (ALB)** | 1 GB processed @ $0.008/GB | $0.008 |
| **CloudWatch** | 5 GB logs @ $0.50/GB + 10 custom metrics @ $0.30/metric | $0.003 |

**Total per user (1,000 photos):** ~**$1.50/month** or **$0.0015 per photo**

**Total per user (amortized over 12 months):** ~**$18/year**

### 11.2 Budget Optimization Strategies

1. **S3 Intelligent-Tiering:** Save 20-30% on storage for infrequently accessed photos
2. **Lambda Graviton2 (arm64):** Use arm64 architecture for 20% cost savings
3. **RDS Autostop:** Stop dev/test instances during off-hours (save 60%)
4. **CloudFront CDN:** Cache processed images (reduce S3 GET costs by 80%)
5. **Spot Instances (ECS):** Use for non-critical workloads (save 70%)
6. **S3 Lifecycle Policies:** Move to Glacier after 1 year (save 80% storage)

**Optimized Cost:** ~**$1.00/month per user** (33% reduction)

---

## 12. Project Structure (Monorepo)

```
rapidphoto/
├── backend/                          # Spring WebFlux API (Java 17)
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/rapidphoto/
│   │   │   │   ├── features/
│   │   │   │   │   ├── upload/
│   │   │   │   │   │   ├── GeneratePresignedUrlSlice.java
│   │   │   │   │   │   ├── ConfirmUploadSlice.java
│   │   │   │   │   │   └── domain/
│   │   │   │   │   │       ├── UploadJob.java
│   │   │   │   │   │       └── UploadJobRepository.java
│   │   │   │   │   ├── gallery/
│   │   │   │   │   │   ├── GetPhotosSlice.java
│   │   │   │   │   │   ├── SearchPhotosByTagSlice.java
│   │   │   │   │   │   └── domain/
│   │   │   │   │   │       ├── Photo.java
│   │   │   │   │   │       ├── PhotoRepository.java
│   │   │   │   │   │       └── PhotoTag.java
│   │   │   │   │   └── user/
│   │   │   │   │       ├── GetCurrentUserSlice.java
│   │   │   │   │       └── domain/
│   │   │   │   │           └── User.java
│   │   │   │   ├── shared/
│   │   │   │   │   ├── config/
│   │   │   │   │   │   ├── R2dbcConfig.java
│   │   │   │   │   │   ├── S3Config.java
│   │   │   │   │   │   ├── SecurityConfig.java
│   │   │   │   │   │   └── ObservabilityConfig.java
│   │   │   │   │   └── infrastructure/
│   │   │   │   │       ├── S3Service.java
│   │   │   │   │       └── JwtValidator.java
│   │   │   │   └── RapidPhotoApplication.java
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       ├── application-dev.yml
│   │   │       ├── application-prod.yml
│   │   │       └── db/migration/
│   │   │           ├── V1__create_users_table.sql
│   │   │           ├── V2__create_photos_table.sql
│   │   │           ├── V3__create_photo_versions_table.sql
│   │   │           ├── V4__create_photo_tags_table.sql
│   │   │           └── V5__create_upload_jobs_table.sql
│   │   └── test/
│   │       └── java/com/rapidphoto/
│   │           ├── integration/
│   │           │   └── UploadFlowIntegrationTest.java
│   │           └── load/
│   │               └── ConcurrentUploadLoadTest.java
│   ├── Dockerfile
│   ├── pom.xml
│   └── build.gradle
│
├── lambda/                           # Image Processing Lambda (Python 3.13)
│   ├── src/
│   │   ├── handler.py
│   │   ├── image_processor.py
│   │   ├── thumbnail_generator.py
│   │   ├── webp_converter.py
│   │   └── rekognition_service.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── mobile/                           # Flutter Mobile App (3.27+)
│   ├── lib/
│   │   ├── features/
│   │   │   ├── upload/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── upload_screen.dart
│   │   │   │   │   └── upload_progress_widget.dart
│   │   │   │   ├── providers/
│   │   │   │   │   ├── upload_queue_provider.dart
│   │   │   │   │   └── upload_progress_provider.dart
│   │   │   │   └── services/
│   │   │   │       └── upload_service.dart
│   │   │   └── gallery/
│   │   │       ├── presentation/
│   │   │       │   ├── gallery_screen.dart
│   │   │       │   └── photo_detail_screen.dart
│   │   │       ├── providers/
│   │   │       │   └── gallery_provider.dart
│   │   │       └── services/
│   │   │           └── gallery_service.dart
│   │   ├── shared/
│   │   │   ├── auth/
│   │   │   │   └── amplify_auth_service.dart
│   │   │   ├── api/
│   │   │   │   └── api_client.dart
│   │   │   └── widgets/
│   │   └── main.dart
│   ├── test/
│   │   ├── unit/
│   │   └── widget/
│   └── pubspec.yaml
│
├── web/                              # React Web App (19.2.0)
│   ├── src/
│   │   ├── features/
│   │   │   ├── upload/
│   │   │   │   ├── components/
│   │   │   │   │   ├── UploadButton.tsx
│   │   │   │   │   └── UploadProgressBar.tsx
│   │   │   │   ├── hooks/
│   │   │   │   │   └── useUploadQueue.ts
│   │   │   │   └── services/
│   │   │   │       └── uploadService.ts
│   │   │   └── gallery/
│   │   │       ├── components/
│   │   │       │   ├── GalleryGrid.tsx
│   │   │       │   ├── PhotoCard.tsx
│   │   │       │   └── SearchBar.tsx
│   │   │       ├── hooks/
│   │   │       │   └── usePhotos.ts
│   │   │       └── services/
│   │   │           └── galleryService.ts
│   │   ├── shared/
│   │   │   ├── auth/
│   │   │   │   └── amplifyConfig.ts
│   │   │   ├── api/
│   │   │   │   └── apiClient.ts
│   │   │   ├── components/
│   │   │   │   └── ui/ (shadcn/ui components)
│   │   │   └── lib/
│   │   │       └── utils.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── tests/
│   │   ├── unit/
│   │   └── e2e/
│   ├── tailwind.config.js
│   ├── package.json
│   └── vite.config.ts
│
├── infrastructure/                   # Terraform IaC (1.9+)
│   ├── modules/
│   │   ├── ecs/
│   │   ├── lambda/
│   │   ├── rds/
│   │   ├── s3/
│   │   └── vpc/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   └── terraform.tfvars
│   │   └── prod/
│   │       ├── main.tf
│   │       └── terraform.tfvars
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── docs/
│   ├── architecture.md
│   ├── api-spec.md
│   ├── deployment.md
│   └── version-migration-guide.md
│
├── .github/
│   └── workflows/
│       ├── backend-ci.yml
│       ├── lambda-ci.yml
│       ├── mobile-ci.yml
│       └── web-ci.yml
│
├── docker-compose.yml                # Local dev environment
└── README.md
```

---

## 13. High-Level Implementation Tasks (UPDATED)

### Phase 1: Infrastructure & Backend Core (Days 1-2)

**Backend Foundation (Spring Boot 3.5.3)**
- [ ] **BACK-001:** Initialize Spring Boot 3.5.3 + WebFlux project with Maven/Gradle
- [ ] **BACK-002:** Configure R2DBC for PostgreSQL 17.6 (reactive repositories)
- [ ] **BACK-003:** Implement DDD domain models (Photo, User, UploadJob)
- [ ] **BACK-004:** Setup Flyway migrations for database schema (V1-V5)
- [ ] **BACK-005:** Configure AWS SDK v2 for S3 (async client, Spring Cloud AWS)
- [ ] **BACK-006:** Implement JWT validation with AWS Amplify/Cognito tokens
- [ ] **BACK-007:** Setup X-Ray tracing with Spring Boot 3.5.3 @Observed annotations

**Upload Feature (VSA Slice)**
- [ ] **BACK-008:** Implement `GeneratePresignedUrlSlice` (Command handler)
- [ ] **BACK-009:** Implement `ConfirmUploadSlice` (Command handler)

**Gallery Feature (VSA Slice)**
- [ ] **BACK-010:** Implement `GetPhotosSlice` (Query handler)
- [ ] **BACK-011:** Implement `SearchPhotosByTagSlice` (Query handler)

**Infrastructure (Terraform 1.9+)**
- [ ] **INFRA-001:** Create Terraform modules (VPC, RDS 17.6, S3, ECS, Lambda)
- [ ] **INFRA-002:** Setup S3 bucket with lifecycle policies and event notifications
- [ ] **INFRA-003:** Configure SQS queue with DLQ
- [ ] **INFRA-004:** Setup RDS PostgreSQL 17.6 (db.t4g.medium)
- [ ] **INFRA-005:** Create ECS cluster with Fargate task definitions
- [ ] **INFRA-006:** Configure ALB with target groups and health checks

### Phase 2: Lambda Processing Pipeline (Day 2)

**Lambda Function (Python 3.13, arm64)**
- [ ] **LAMBDA-001:** Create Python 3.13 Lambda project (arm64 architecture)
- [ ] **LAMBDA-002:** Implement SQS event handler
- [ ] **LAMBDA-003:** Implement thumbnail generation (Pillow 11.x, 300x300)
- [ ] **LAMBDA-004:** Implement multi-resolution WebP conversion
- [ ] **LAMBDA-005:** Integrate AWS Rekognition DetectLabels API
- [ ] **LAMBDA-006:** Update Photo record in RDS via psycopg2
- [ ] **LAMBDA-007:** Implement error handling and CloudWatch logging
- [ ] **LAMBDA-008:** Deploy Lambda with Terraform (arm64, 3 GB memory)

### Phase 3: Flutter Mobile App (Days 3-4)

**Project Setup (Flutter 3.27+, Riverpod 3.0.1)**
- [ ] **MOBILE-001:** Initialize Flutter 3.27+ project with Riverpod 3.0.1
- [ ] **MOBILE-002:** Configure AWS Amplify Gen 2 (Cognito, S3)
- [ ] **MOBILE-003:** Setup API client with Dio 5.7+

**Authentication**
- [ ] **MOBILE-004:** Implement Amplify authentication flow
- [ ] **MOBILE-005:** Create auth state provider (AsyncNotifier)
- [ ] **MOBILE-006:** Implement protected route wrapper

**Upload Feature**
- [ ] **MOBILE-007:** Implement multi-photo picker (image_picker 1.1.2)
- [ ] **MOBILE-008:** Create `UploadQueueNotifier` (Riverpod 3.0.1)
- [ ] **MOBILE-009:** Implement concurrent upload logic (max 10 parallel)
- [ ] **MOBILE-010:** Create Material 3 upload progress UI
- [ ] **MOBILE-011:** Implement background upload handling

**Gallery Feature**
- [ ] **MOBILE-012:** Create `GalleryAsyncNotifier` (AsyncNotifier)
- [ ] **MOBILE-013:** Implement infinite scroll gallery (paginated)
- [ ] **MOBILE-014:** Create photo grid with cached_network_image 3.4.1
- [ ] **MOBILE-015:** Implement photo detail screen (Material 3)
- [ ] **MOBILE-016:** Add search by tags functionality
- [ ] **MOBILE-017:** Implement pull-to-refresh

**Testing**
- [ ] **MOBILE-018:** Write unit tests for upload queue logic
- [ ] **MOBILE-019:** Write widget tests for Material 3 UI
- [ ] **MOBILE-020:** Write E2E tests with Patrol

### Phase 4: React Web App (Days 4-5)

**Project Setup (React 19.2.0)**
- [ ] **WEB-001:** Initialize Vite + React 19.2.0 + TypeScript 5.7
- [ ] **WEB-002:** Setup Tailwind CSS 3.4.17 + shadcn/ui
- [ ] **WEB-003:** Configure AWS Amplify Gen 2 for authentication
- [ ] **WEB-004:** Setup Axios API client with interceptors

**Authentication**
- [ ] **WEB-005:** Implement Amplify auth flow (React 19 patterns)
- [ ] **WEB-006:** Create auth context with useAuth hook
- [ ] **WEB-007:** Implement protected route component (React Router 7)

**Upload Feature**
- [ ] **WEB-008:** Create file input with drag-and-drop (react-dropzone)
- [ ] **WEB-009:** Implement `useUploadQueue` hook (React Query 5.x)
- [ ] **WEB-010:** Implement concurrent upload logic (Promise.allSettled)
- [ ] **WEB-011:** Create upload progress UI (shadcn/ui components)
- [ ] **WEB-012:** Implement retry logic for failed uploads

**Gallery Feature**
- [ ] **WEB-013:** Create `usePhotos` hook with React Query
- [ ] **WEB-014:** Implement responsive photo grid (CSS Grid)
- [ ] **WEB-015:** Create photo card component (shadcn/ui)
- [ ] **WEB-016:** Implement photo lightbox modal
- [ ] **WEB-017:** Add search/filter controls
- [ ] **WEB-018:** Implement batch download functionality

**Testing**
- [ ] **WEB-019:** Write unit tests with Vitest 2.1.8
- [ ] **WEB-020:** Write component tests with Testing Library 16.1
- [ ] **WEB-021:** Write E2E tests with Playwright 1.49

### Phase 5: Integration Testing & Load Testing (Day 5)

**Integration Tests**
- [ ] **TEST-001:** Setup Testcontainers (PostgreSQL 17.6, LocalStack)
- [ ] **TEST-002:** Write end-to-end upload flow test
- [ ] **TEST-003:** Write Lambda processing test (Python 3.13)
- [ ] **TEST-004:** Write gallery query tests (PostgreSQL 17.6)
- [ ] **TEST-005:** Verify X-Ray traces with @Observed annotations

**Load Testing**
- [ ] **TEST-006:** Create JMeter/K6 script for 100 concurrent uploads
- [ ] **TEST-007:** Measure API response times (Spring Boot 3.5.3)
- [ ] **TEST-008:** Verify zero timeout errors
- [ ] **TEST-009:** Monitor CloudWatch metrics during load test
- [ ] **TEST-010:** Generate load test report

### Phase 6: Deployment & Documentation (Day 5)

**Deployment**
- [ ] **DEPLOY-001:** Build and push Docker image to ECR (Java 17)
- [ ] **DEPLOY-002:** Deploy backend to ECS Fargate (Spring Boot 3.5.3)
- [ ] **DEPLOY-003:** Deploy Lambda function with Terraform (Python 3.13, arm64)
- [ ] **DEPLOY-004:** Deploy web app to S3 + CloudFront or Vercel
- [ ] **DEPLOY-005:** Build Flutter APK/AAB (Flutter 3.27+)
- [ ] **DEPLOY-006:** Configure CloudWatch dashboard (Spring Boot 3.5.3 metrics)
- [ ] **DEPLOY-007:** Setup CloudWatch alarms

**Documentation**
- [ ] **DOC-001:** Write technical architecture document
- [ ] **DOC-002:** Document API endpoints (OpenAPI/Swagger)
- [ ] **DOC-003:** Create deployment guide (Terraform 1.9+)
- [ ] **DOC-004:** Write version migration guide (3.2→3.5.3, 18→19, etc.)
- [ ] **DOC-005:** Record demo video (5-10 minutes)

---

## 14. Risk Assessment & Mitigation (UPDATED)

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **React 19 Breaking Changes** | Medium | Low | Follow React 19 migration guide, test Suspense boundaries |
| **Spring Boot 3.5 Observability Changes** | Low | Low | Update CloudWatch agent, test @Observed annotations |
| **Flutter 3.27 Material 3 Changes** | Low | Low | Update theme configurations, test UI components |
| **PostgreSQL 17 Migration Issues** | Medium | Low | Test in staging, use pg_upgrade, validate query plans |
| **Lambda cold start delays (arm64)** | Medium | Medium | Reserve concurrency (10 instances), use SnapStart if needed |
| **S3 presigned URL expiry** | Medium | Low | Set 15-min expiry, implement client-side retry |
| **RDS connection pool exhaustion** | High | Medium | Use R2DBC with small pool (10), implement backpressure |
| **SQS message loss** | High | Low | Enable DLQ, set visibility timeout > Lambda duration |
| **Rekognition API rate limits** | Medium | Low | Implement exponential backoff, use batch processing |
| **Mobile app background upload interruption** | Medium | High | Implement persistent queue, retry on app reopen |
| **Cost overruns (Rekognition)** | Medium | Medium | Cache tags, skip re-processing on duplicates |

---

## 15. Success Criteria (UPDATED)

**Functional:**
- ✅ System handles 100 concurrent uploads without errors
- ✅ All photos processed within 2 minutes
- ✅ Mobile (Flutter 3.27) and web (React 19) apps remain responsive
- ✅ AI tagging accuracy ≥80% confidence on 95% of photos
- ✅ Zero data loss during upload/processing failures

**Non-Functional:**
- ✅ API p99 latency <500ms (Spring Boot 3.5.3 performance)
- ✅ Lambda processing time <15 seconds per photo (Python 3.13, arm64)
- ✅ UI frame rate ≥60 FPS during uploads
- ✅ Test coverage ≥80% (backend), ≥70% (mobile/web)
- ✅ Zero critical security vulnerabilities

**Operational:**
- ✅ All CloudWatch alarms configured and tested
- ✅ X-Ray traces visible with Spring Boot 3.5.3 @Observed
- ✅ Infrastructure deployable via Terraform 1.9+ in <15 minutes
- ✅ CI/CD pipeline passes all tests on every commit
- ✅ Documentation complete and accurate

**Performance Expectations (with updated versions):**
- **~15% faster** Spring WebFlux throughput (3.5.3 improvements)
- **~20% faster** React rendering (concurrent features in 19.x)
- **~10% faster** PostgreSQL queries (improved planner in 17.x)
- **~8% faster** Lambda cold starts (Python 3.13 optimizations)
- **~20% cost savings** Lambda execution (arm64 Graviton2)

---

## 16. Future Enhancements (Out of Scope)

- Real-time WebSocket notifications for upload progress
- Offline upload queue persistence (PWA, background sync)
- Video upload support with transcoding
- Social features (sharing, commenting, likes)
- Advanced search (facial recognition, object detection filters)
- Multi-user collaboration (shared albums)
- Mobile notifications for processing completion
- CDN integration for global photo delivery
- AVIF format support (next-gen image codec)
- Machine learning model fine-tuning (custom tag categories)

---

## 17. Version Migration Checklist

### 17.1 Spring Boot 3.2 → 3.5.3

- [ ] Update parent POM/Gradle plugin to 3.5.3
- [ ] Verify Java 17 compatibility (or upgrade to Java 21)
- [ ] Update Gradle to 8.1.1+ or Maven to 3.8.5+
- [ ] Test @Observed annotations for observability
- [ ] Validate R2DBC connection pooling behavior
- [ ] Update Spring Cloud AWS to 3.2.1
- [ ] Test actuator endpoints (/health, /metrics)
- [ ] Verify CloudWatch metrics integration

### 17.2 React 18 → 19.2.0

- [ ] Update React and React-DOM to 19.2.0
- [ ] Update React Router to 7.9.4
- [ ] Add Suspense boundaries for async components
- [ ] Update Testing Library to 16.1.0
- [ ] Test concurrent rendering behavior
- [ ] Verify Server Component compatibility (if using)
- [ ] Update build tools (Vite 6.0.5)
- [ ] Test hydration behavior

### 17.3 Flutter 3.16 → 3.27+

- [ ] Update Flutter SDK to 3.27+
- [ ] Update Dart SDK to 3.5+
- [ ] Update Riverpod to 3.0.1
- [ ] Update AWS Amplify to 2.7.0
- [ ] Migrate to Material 3 theme
- [ ] Test all UI components with Material 3
- [ ] Update dependencies (image_picker, cached_network_image)
- [ ] Run `flutter pub upgrade --major-versions`
- [ ] Test on both iOS and Android

### 17.4 PostgreSQL 15 → 17.6

- [ ] Backup production database
- [ ] Test migration in staging environment
- [ ] Run pg_upgrade or logical replication
- [ ] Validate query execution plans (EXPLAIN ANALYZE)
- [ ] Test JSONB operations (improved in 17.x)
- [ ] Verify connection pooling behavior
- [ ] Monitor performance metrics post-migration
- [ ] Update RDS parameter groups if needed

### 17.5 Python 3.12 → 3.13 (Lambda)

- [ ] Update Lambda runtime to python3.13
- [ ] Test Pillow 11.x compatibility
- [ ] Verify boto3 behavior (1.35.96+)
- [ ] Test psycopg2-binary compatibility
- [ ] Measure cold start times
- [ ] Update Lambda deployment packages
- [ ] Test image processing pipeline end-to-end

---

## 18. Appendix

### 18.1 Glossary

- **DDD:** Domain-Driven Design - Software design modeling complex domains
- **CQRS:** Command Query Responsibility Segregation - Separate read/write operations
- **VSA:** Vertical Slice Architecture - Organize code by features, not layers
- **Presigned URL:** Temporary URL granting time-limited S3 access
- **R2DBC:** Reactive Relational Database Connectivity - Reactive SQL driver
- **WebFlux:** Spring's reactive web framework (non-blocking, event-driven)
- **Fargate:** AWS serverless container compute engine
- **Riverpod:** Flutter state management library (Notifier/AsyncNotifier)
- **shadcn/ui:** Re-usable component library for React (Tailwind-based)
- **Graviton2:** AWS ARM-based processors (arm64 architecture)

### 18.2 References

- [Spring Boot 3.5.3 Release Notes](https://github.com/spring-projects/spring-boot/releases/tag/v3.5.3)
- [React 19 Documentation](https://react.dev/blog/2024/12/05/react-19)
- [Flutter 3.27 Release](https://docs.flutter.dev/release/release-notes)
- [PostgreSQL 17 Release Notes](https://www.postgresql.org/docs/17/release-17.html)
- [AWS Lambda Python 3.13 Runtime](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
- [AWS Amplify Gen 2](https://docs.amplify.aws/)
- [Riverpod 3.0 Documentation](https://riverpod.dev/)
- [Terraform 1.9+ Documentation](https://www.terraform.io/docs)