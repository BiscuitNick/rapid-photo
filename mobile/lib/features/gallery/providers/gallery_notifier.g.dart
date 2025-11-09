// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing gallery state

@ProviderFor(GalleryNotifier)
const galleryProvider = GalleryNotifierProvider._();

/// Notifier for managing gallery state
final class GalleryNotifierProvider
    extends $AsyncNotifierProvider<GalleryNotifier, GalleryState> {
  /// Notifier for managing gallery state
  const GalleryNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'galleryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$galleryNotifierHash();

  @$internal
  @override
  GalleryNotifier create() => GalleryNotifier();
}

String _$galleryNotifierHash() => r'1524a1c613a6974e493de64d7b1318fcf2df6276';

/// Notifier for managing gallery state

abstract class _$GalleryNotifier extends $AsyncNotifier<GalleryState> {
  FutureOr<GalleryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<GalleryState>, GalleryState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<GalleryState>, GalleryState>,
        AsyncValue<GalleryState>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
