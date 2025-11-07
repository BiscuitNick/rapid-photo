import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_response.dart';
import 'package:rapid_photo_mobile/features/gallery/services/gallery_service.dart';

/// Provider for fetching a single photo's details
final photoDetailProvider =
    FutureProvider.family<PhotoResponse, String>((ref, photoId) async {
  final galleryService = ref.watch(galleryServiceProvider);
  return galleryService.getPhoto(photoId);
});

/// Provider for download URLs
final downloadUrlProvider = FutureProvider.family<String, DownloadUrlParams>(
  (ref, params) async {
    final galleryService = ref.watch(galleryServiceProvider);
    return galleryService.getDownloadUrl(
      params.photoId,
      versionType: params.versionType,
    );
  },
);

/// Parameters for download URL provider
class DownloadUrlParams {
  final String photoId;
  final String? versionType;

  DownloadUrlParams({
    required this.photoId,
    this.versionType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadUrlParams &&
        other.photoId == photoId &&
        other.versionType == versionType;
  }

  @override
  int get hashCode => photoId.hashCode ^ versionType.hashCode;
}
