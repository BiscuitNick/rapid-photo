# Upload Feature

This feature implements the upload experience for RapidPhoto using Flutter 3.27, Riverpod 3.0.1, and Material 3.

## Architecture

The upload feature follows a clean architecture pattern with the following structure:

```
features/upload/
├── models/          # Data models (UploadItem, UploadQueueState)
├── providers/       # Riverpod providers and notifiers
├── services/        # Business logic services
└── widgets/         # UI components
```

## Key Components

### Models

- **UploadItem**: Represents a single file upload with status, progress, and metadata
- **UploadQueueState**: Manages the state of the entire upload queue

### Services

- **UploadService**: Handles backend API communication
  - Generate presigned URLs
  - Upload to S3
  - Confirm upload completion

- **UploadPersistenceService**: Manages queue state persistence
  - Save/load queue state to SharedPreferences
  - Resume uploads after app restart

### Providers

- **UploadQueueNotifier**: Core upload queue manager
  - Manages concurrency (max 10 parallel uploads)
  - Handles queue processing
  - Supports pause/resume
  - Automatic retry logic
  - State persistence

### Widgets

- **UploadScreen**: Main upload UI
  - Material 3 segmented button filters
  - Progress summary
  - Control buttons (pause/resume/retry/clear)
  - Upload list

- **UploadProgressCard**: Individual upload item display
  - Thumbnail preview
  - Progress indicator
  - Status chip
  - Actions menu

## Features

### Concurrent Upload Management
- Supports up to 100 files in queue
- Maximum 10 parallel uploads
- Automatic batching and queue processing

### Upload Flow
1. User selects photos using ImagePicker
2. Files are added to queue with status `queued`
3. Queue processor generates presigned URLs from backend
4. Files are uploaded to S3 with progress tracking
5. Upload is confirmed with backend (ETag validation)
6. Status updates to `processing` while backend processes
7. Final status becomes `complete` or `failed`

### State Persistence
- Queue state is automatically saved to SharedPreferences
- Uploads can resume after app restart
- Individual item progress is preserved

### Error Handling
- Failed uploads are tracked with error messages
- Retry mechanism for failed uploads
- Network error handling with Dio

### UI Features
- Material 3 design
- Segmented button filters (All/Uploading/Complete/Failed)
- Linear progress indicators
- Status chips with colors
- Pull-to-refresh capability
- Item detail view
- Pause/Resume controls
- Batch operations (clear completed, retry failed)

## Usage

### Basic Upload Flow

```dart
// Navigate to upload screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const UploadScreen()),
);

// Or use the provider directly
final notifier = ref.read(uploadQueueProvider.notifier);

// Add files
await notifier.addFiles(selectedFiles);

// Pause queue
await notifier.pauseQueue();

// Resume queue
await notifier.resumeQueue();

// Retry failed uploads
await notifier.retryFailed();

// Clear completed
await notifier.clearCompleted();
```

### Watching Queue State

```dart
// Watch the entire queue state
final queueState = ref.watch(uploadQueueProvider);

queueState.when(
  data: (state) {
    // Access state properties
    final totalItems = state.items.length;
    final progress = state.totalProgress;
    final completed = state.completedItems.length;
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

## Backend Integration

The upload feature expects the following backend endpoints:

### POST /api/v1/uploads/initiate
Request:
```json
{
  "fileName": "photo.jpg",
  "fileSize": 1024000,
  "mimeType": "image/jpeg"
}
```

Response:
```json
{
  "uploadJobId": "uuid",
  "presignedUrl": "https://s3.amazonaws.com/...",
  "s3Key": "originals/{userId}/{uuid}",
  "expiresAt": "2025-11-07T12:00:00Z"
}
```

### POST /api/v1/uploads/{uploadJobId}/confirm
Request:
```json
{
  "etag": "abc123..."
}
```

Response: 204 No Content

### GET /api/v1/uploads/batch/status
Response:
```json
[
  {
    "uploadJobId": "uuid",
    "status": "PROCESSING",
    "photoId": "uuid"
  }
]
```

## Testing

Run tests with:
```bash
flutter test test/features/upload/
```

Tests cover:
- Upload queue state management
- Model extensions and utilities
- Concurrency limits
- Status filtering
- Progress calculation

## Configuration

### Backend URL
Update the base URL in `UploadService`:
```dart
static const String _baseUrl = 'https://api.rapidphoto.com/api/v1';
```

### Amplify Configuration
Update Amplify config in `AmplifyAuthService` with your Cognito and S3 settings.

### Concurrency Limit
Adjust max parallel uploads in `UploadQueueNotifier`:
```dart
static const int maxParallelUploads = 10;
```

## Performance

- Queue processing uses efficient batching
- State persistence is debounced (500ms)
- UI updates are optimized with Riverpod
- Thumbnail loading uses efficient file access
- Progress updates are throttled

## Future Enhancements

- [ ] Background upload using WorkManager
- [ ] Upload analytics and metrics
- [ ] Bandwidth throttling
- [ ] Compression options
- [ ] Camera integration
- [ ] Multi-selection from gallery
- [ ] Upload scheduling
- [ ] Wi-Fi only mode
