// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GalleryState {
  /// List of photos
  List<PhotoListItem> get photos;

  /// Current page number
  int get currentPage;

  /// Whether there are more pages to load
  bool get hasMore;

  /// Total number of photos
  int get totalPhotos;

  /// Active filter tags
  List<String> get filterTags;

  /// Sort field (e.g., 'createdAt', 'takenAt')
  String? get sortBy;

  /// Sort direction ('asc' or 'desc')
  String get sortDirection;

  /// Whether currently loading
  bool get isLoading;

  /// Whether currently refreshing
  bool get isRefreshing;

  /// Error message if any
  String? get error;

  /// Create a copy of GalleryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GalleryStateCopyWith<GalleryState> get copyWith =>
      _$GalleryStateCopyWithImpl<GalleryState>(
          this as GalleryState, _$identity);

  /// Serializes this GalleryState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GalleryState &&
            const DeepCollectionEquality().equals(other.photos, photos) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.totalPhotos, totalPhotos) ||
                other.totalPhotos == totalPhotos) &&
            const DeepCollectionEquality()
                .equals(other.filterTags, filterTags) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortDirection, sortDirection) ||
                other.sortDirection == sortDirection) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(photos),
      currentPage,
      hasMore,
      totalPhotos,
      const DeepCollectionEquality().hash(filterTags),
      sortBy,
      sortDirection,
      isLoading,
      isRefreshing,
      error);

  @override
  String toString() {
    return 'GalleryState(photos: $photos, currentPage: $currentPage, hasMore: $hasMore, totalPhotos: $totalPhotos, filterTags: $filterTags, sortBy: $sortBy, sortDirection: $sortDirection, isLoading: $isLoading, isRefreshing: $isRefreshing, error: $error)';
  }
}

/// @nodoc
abstract mixin class $GalleryStateCopyWith<$Res> {
  factory $GalleryStateCopyWith(
          GalleryState value, $Res Function(GalleryState) _then) =
      _$GalleryStateCopyWithImpl;
  @useResult
  $Res call(
      {List<PhotoListItem> photos,
      int currentPage,
      bool hasMore,
      int totalPhotos,
      List<String> filterTags,
      String? sortBy,
      String sortDirection,
      bool isLoading,
      bool isRefreshing,
      String? error});
}

/// @nodoc
class _$GalleryStateCopyWithImpl<$Res> implements $GalleryStateCopyWith<$Res> {
  _$GalleryStateCopyWithImpl(this._self, this._then);

  final GalleryState _self;
  final $Res Function(GalleryState) _then;

  /// Create a copy of GalleryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? photos = null,
    Object? currentPage = null,
    Object? hasMore = null,
    Object? totalPhotos = null,
    Object? filterTags = null,
    Object? sortBy = freezed,
    Object? sortDirection = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_self.copyWith(
      photos: null == photos
          ? _self.photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<PhotoListItem>,
      currentPage: null == currentPage
          ? _self.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      totalPhotos: null == totalPhotos
          ? _self.totalPhotos
          : totalPhotos // ignore: cast_nullable_to_non_nullable
              as int,
      filterTags: null == filterTags
          ? _self.filterTags
          : filterTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortBy: freezed == sortBy
          ? _self.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String?,
      sortDirection: null == sortDirection
          ? _self.sortDirection
          : sortDirection // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _self.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [GalleryState].
extension GalleryStatePatterns on GalleryState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_GalleryState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GalleryState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_GalleryState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GalleryState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_GalleryState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GalleryState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            List<PhotoListItem> photos,
            int currentPage,
            bool hasMore,
            int totalPhotos,
            List<String> filterTags,
            String? sortBy,
            String sortDirection,
            bool isLoading,
            bool isRefreshing,
            String? error)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GalleryState() when $default != null:
        return $default(
            _that.photos,
            _that.currentPage,
            _that.hasMore,
            _that.totalPhotos,
            _that.filterTags,
            _that.sortBy,
            _that.sortDirection,
            _that.isLoading,
            _that.isRefreshing,
            _that.error);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            List<PhotoListItem> photos,
            int currentPage,
            bool hasMore,
            int totalPhotos,
            List<String> filterTags,
            String? sortBy,
            String sortDirection,
            bool isLoading,
            bool isRefreshing,
            String? error)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GalleryState():
        return $default(
            _that.photos,
            _that.currentPage,
            _that.hasMore,
            _that.totalPhotos,
            _that.filterTags,
            _that.sortBy,
            _that.sortDirection,
            _that.isLoading,
            _that.isRefreshing,
            _that.error);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            List<PhotoListItem> photos,
            int currentPage,
            bool hasMore,
            int totalPhotos,
            List<String> filterTags,
            String? sortBy,
            String sortDirection,
            bool isLoading,
            bool isRefreshing,
            String? error)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GalleryState() when $default != null:
        return $default(
            _that.photos,
            _that.currentPage,
            _that.hasMore,
            _that.totalPhotos,
            _that.filterTags,
            _that.sortBy,
            _that.sortDirection,
            _that.isLoading,
            _that.isRefreshing,
            _that.error);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GalleryState implements GalleryState {
  const _GalleryState(
      {final List<PhotoListItem> photos = const [],
      this.currentPage = 0,
      this.hasMore = true,
      this.totalPhotos = 0,
      final List<String> filterTags = const [],
      this.sortBy,
      this.sortDirection = 'desc',
      this.isLoading = false,
      this.isRefreshing = false,
      this.error})
      : _photos = photos,
        _filterTags = filterTags;
  factory _GalleryState.fromJson(Map<String, dynamic> json) =>
      _$GalleryStateFromJson(json);

  /// List of photos
  final List<PhotoListItem> _photos;

  /// List of photos
  @override
  @JsonKey()
  List<PhotoListItem> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  /// Current page number
  @override
  @JsonKey()
  final int currentPage;

  /// Whether there are more pages to load
  @override
  @JsonKey()
  final bool hasMore;

  /// Total number of photos
  @override
  @JsonKey()
  final int totalPhotos;

  /// Active filter tags
  final List<String> _filterTags;

  /// Active filter tags
  @override
  @JsonKey()
  List<String> get filterTags {
    if (_filterTags is EqualUnmodifiableListView) return _filterTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filterTags);
  }

  /// Sort field (e.g., 'createdAt', 'takenAt')
  @override
  final String? sortBy;

  /// Sort direction ('asc' or 'desc')
  @override
  @JsonKey()
  final String sortDirection;

  /// Whether currently loading
  @override
  @JsonKey()
  final bool isLoading;

  /// Whether currently refreshing
  @override
  @JsonKey()
  final bool isRefreshing;

  /// Error message if any
  @override
  final String? error;

  /// Create a copy of GalleryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GalleryStateCopyWith<_GalleryState> get copyWith =>
      __$GalleryStateCopyWithImpl<_GalleryState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GalleryStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GalleryState &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.totalPhotos, totalPhotos) ||
                other.totalPhotos == totalPhotos) &&
            const DeepCollectionEquality()
                .equals(other._filterTags, _filterTags) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortDirection, sortDirection) ||
                other.sortDirection == sortDirection) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_photos),
      currentPage,
      hasMore,
      totalPhotos,
      const DeepCollectionEquality().hash(_filterTags),
      sortBy,
      sortDirection,
      isLoading,
      isRefreshing,
      error);

  @override
  String toString() {
    return 'GalleryState(photos: $photos, currentPage: $currentPage, hasMore: $hasMore, totalPhotos: $totalPhotos, filterTags: $filterTags, sortBy: $sortBy, sortDirection: $sortDirection, isLoading: $isLoading, isRefreshing: $isRefreshing, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$GalleryStateCopyWith<$Res>
    implements $GalleryStateCopyWith<$Res> {
  factory _$GalleryStateCopyWith(
          _GalleryState value, $Res Function(_GalleryState) _then) =
      __$GalleryStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<PhotoListItem> photos,
      int currentPage,
      bool hasMore,
      int totalPhotos,
      List<String> filterTags,
      String? sortBy,
      String sortDirection,
      bool isLoading,
      bool isRefreshing,
      String? error});
}

/// @nodoc
class __$GalleryStateCopyWithImpl<$Res>
    implements _$GalleryStateCopyWith<$Res> {
  __$GalleryStateCopyWithImpl(this._self, this._then);

  final _GalleryState _self;
  final $Res Function(_GalleryState) _then;

  /// Create a copy of GalleryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? photos = null,
    Object? currentPage = null,
    Object? hasMore = null,
    Object? totalPhotos = null,
    Object? filterTags = null,
    Object? sortBy = freezed,
    Object? sortDirection = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_GalleryState(
      photos: null == photos
          ? _self._photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<PhotoListItem>,
      currentPage: null == currentPage
          ? _self.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      totalPhotos: null == totalPhotos
          ? _self.totalPhotos
          : totalPhotos // ignore: cast_nullable_to_non_nullable
              as int,
      filterTags: null == filterTags
          ? _self._filterTags
          : filterTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortBy: freezed == sortBy
          ? _self.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String?,
      sortDirection: null == sortDirection
          ? _self.sortDirection
          : sortDirection // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _self.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
