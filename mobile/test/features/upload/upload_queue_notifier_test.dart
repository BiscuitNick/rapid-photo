import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/upload/models/upload_item.dart';
import 'package:rapid_photo_mobile/features/upload/providers/upload_queue_notifier.dart';

void main() {
  group('UploadQueueNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () async {
      final notifier = container.read(uploadQueueProvider.notifier);
      final initialState = await container.read(uploadQueueProvider.future);

      expect(initialState.items, isEmpty);
      expect(initialState.isPaused, false);
      expect(initialState.isProcessing, false);
      expect(initialState.activeUploads, 0);
    });

    test('UploadQueueState extensions work correctly', () {
      final state = UploadQueueState(
        items: [
          UploadItem(
            id: '1',
            localPath: '/path/1.jpg',
            fileName: 'test1.jpg',
            fileSize: 1024,
            mimeType: 'image/jpeg',
            status: UploadStatus.queued,
          ),
          UploadItem(
            id: '2',
            localPath: '/path/2.jpg',
            fileName: 'test2.jpg',
            fileSize: 2048,
            mimeType: 'image/jpeg',
            status: UploadStatus.uploading,
            progress: 0.5,
          ),
          UploadItem(
            id: '3',
            localPath: '/path/3.jpg',
            fileName: 'test3.jpg',
            fileSize: 3072,
            mimeType: 'image/jpeg',
            status: UploadStatus.complete,
            progress: 1.0,
          ),
          UploadItem(
            id: '4',
            localPath: '/path/4.jpg',
            fileName: 'test4.jpg',
            fileSize: 4096,
            mimeType: 'image/jpeg',
            status: UploadStatus.failed,
          ),
        ],
      );

      expect(state.queuedItems.length, 1);
      expect(state.uploadingItems.length, 1);
      expect(state.completedItems.length, 1);
      expect(state.failedItems.length, 1);
      expect(state.isEmpty, false);
      expect(state.isComplete, false);

      // Total progress: (0 + 0.5 + 1.0 + 0) / 4 = 0.375
      expect(state.totalProgress, closeTo(0.375, 0.001));
    });

    test('itemsByStatus filters correctly', () {
      final state = UploadQueueState(
        items: [
          UploadItem(
            id: '1',
            localPath: '/path/1.jpg',
            fileName: 'test1.jpg',
            fileSize: 1024,
            mimeType: 'image/jpeg',
            status: UploadStatus.queued,
          ),
          UploadItem(
            id: '2',
            localPath: '/path/2.jpg',
            fileName: 'test2.jpg',
            fileSize: 2048,
            mimeType: 'image/jpeg',
            status: UploadStatus.uploading,
          ),
          UploadItem(
            id: '3',
            localPath: '/path/3.jpg',
            fileName: 'test3.jpg',
            fileSize: 3072,
            mimeType: 'image/jpeg',
            status: UploadStatus.queued,
          ),
        ],
      );

      final queuedItems = state.itemsByStatus(UploadStatus.queued);
      expect(queuedItems.length, 2);
      expect(queuedItems[0].id, '1');
      expect(queuedItems[1].id, '3');

      final uploadingItems = state.itemsByStatus(UploadStatus.uploading);
      expect(uploadingItems.length, 1);
      expect(uploadingItems[0].id, '2');
    });

    test('isComplete returns true when all items are done', () {
      final state = UploadQueueState(
        items: [
          UploadItem(
            id: '1',
            localPath: '/path/1.jpg',
            fileName: 'test1.jpg',
            fileSize: 1024,
            mimeType: 'image/jpeg',
            status: UploadStatus.complete,
            progress: 1.0,
          ),
          UploadItem(
            id: '2',
            localPath: '/path/2.jpg',
            fileName: 'test2.jpg',
            fileSize: 2048,
            mimeType: 'image/jpeg',
            status: UploadStatus.failed,
          ),
        ],
      );

      expect(state.isComplete, true);
    });

    test('isComplete returns false when items are in progress', () {
      final state = UploadQueueState(
        items: [
          UploadItem(
            id: '1',
            localPath: '/path/1.jpg',
            fileName: 'test1.jpg',
            fileSize: 1024,
            mimeType: 'image/jpeg',
            status: UploadStatus.uploading,
            progress: 0.5,
          ),
          UploadItem(
            id: '2',
            localPath: '/path/2.jpg',
            fileName: 'test2.jpg',
            fileSize: 2048,
            mimeType: 'image/jpeg',
            status: UploadStatus.complete,
            progress: 1.0,
          ),
        ],
      );

      expect(state.isComplete, false);
    });

    test('totalProgress with empty items returns 0', () {
      const state = UploadQueueState(items: []);
      expect(state.totalProgress, 0.0);
    });
  });
}
