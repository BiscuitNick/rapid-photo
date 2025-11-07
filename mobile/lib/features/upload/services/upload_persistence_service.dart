import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:rapid_photo_mobile/features/upload/models/upload_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting upload queue state
class UploadPersistenceService {
  static const String _queueStateKey = 'upload_queue_state';
  final Logger _logger = Logger();

  /// Save upload queue state
  Future<void> saveQueueState(UploadQueueState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.toJson());
      await prefs.setString(_queueStateKey, json);
      _logger.d('Upload queue state saved');
    } catch (e) {
      _logger.e('Failed to save upload queue state: $e');
    }
  }

  /// Load upload queue state
  Future<UploadQueueState?> loadQueueState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_queueStateKey);

      if (json == null) {
        _logger.d('No saved upload queue state found');
        return null;
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      final state = UploadQueueState.fromJson(data);
      _logger.d('Upload queue state loaded: ${state.items.length} items');
      return state;
    } catch (e) {
      _logger.e('Failed to load upload queue state: $e');
      return null;
    }
  }

  /// Clear saved queue state
  Future<void> clearQueueState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueStateKey);
      _logger.d('Upload queue state cleared');
    } catch (e) {
      _logger.e('Failed to clear upload queue state: $e');
    }
  }

  /// Save individual upload item
  Future<void> saveUploadItem(UploadItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'upload_item_${item.id}';
      final json = jsonEncode(item.toJson());
      await prefs.setString(key, json);
      _logger.d('Upload item saved: ${item.id}');
    } catch (e) {
      _logger.e('Failed to save upload item: $e');
    }
  }

  /// Load individual upload item
  Future<UploadItem?> loadUploadItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'upload_item_$itemId';
      final json = prefs.getString(key);

      if (json == null) {
        return null;
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      return UploadItem.fromJson(data);
    } catch (e) {
      _logger.e('Failed to load upload item: $e');
      return null;
    }
  }

  /// Remove individual upload item
  Future<void> removeUploadItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'upload_item_$itemId';
      await prefs.remove(key);
      _logger.d('Upload item removed: $itemId');
    } catch (e) {
      _logger.e('Failed to remove upload item: $e');
    }
  }
}

/// Provider for UploadPersistenceService
final uploadPersistenceServiceProvider = Provider<UploadPersistenceService>((ref) {
  return UploadPersistenceService();
});
