// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UploadItem {
  String get id;
  String get localPath;
  String get fileName;
  int get fileSize;
  String get mimeType;
  UploadStatus get status;
  double get progress;
  String? get uploadJobId;
  String? get s3Key;
  String? get presignedUrl;
  String? get etag;
  String? get errorMessage;
  DateTime? get queuedAt;
  DateTime? get startedAt;
  DateTime? get completedAt;

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UploadItemCopyWith<UploadItem> get copyWith =>
      _$UploadItemCopyWithImpl<UploadItem>(this as UploadItem, _$identity);

  /// Serializes this UploadItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UploadItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.uploadJobId, uploadJobId) ||
                other.uploadJobId == uploadJobId) &&
            (identical(other.s3Key, s3Key) || other.s3Key == s3Key) &&
            (identical(other.presignedUrl, presignedUrl) ||
                other.presignedUrl == presignedUrl) &&
            (identical(other.etag, etag) || other.etag == etag) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.queuedAt, queuedAt) ||
                other.queuedAt == queuedAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      localPath,
      fileName,
      fileSize,
      mimeType,
      status,
      progress,
      uploadJobId,
      s3Key,
      presignedUrl,
      etag,
      errorMessage,
      queuedAt,
      startedAt,
      completedAt);

  @override
  String toString() {
    return 'UploadItem(id: $id, localPath: $localPath, fileName: $fileName, fileSize: $fileSize, mimeType: $mimeType, status: $status, progress: $progress, uploadJobId: $uploadJobId, s3Key: $s3Key, presignedUrl: $presignedUrl, etag: $etag, errorMessage: $errorMessage, queuedAt: $queuedAt, startedAt: $startedAt, completedAt: $completedAt)';
  }
}

/// @nodoc
abstract mixin class $UploadItemCopyWith<$Res> {
  factory $UploadItemCopyWith(
          UploadItem value, $Res Function(UploadItem) _then) =
      _$UploadItemCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String localPath,
      String fileName,
      int fileSize,
      String mimeType,
      UploadStatus status,
      double progress,
      String? uploadJobId,
      String? s3Key,
      String? presignedUrl,
      String? etag,
      String? errorMessage,
      DateTime? queuedAt,
      DateTime? startedAt,
      DateTime? completedAt});
}

/// @nodoc
class _$UploadItemCopyWithImpl<$Res> implements $UploadItemCopyWith<$Res> {
  _$UploadItemCopyWithImpl(this._self, this._then);

  final UploadItem _self;
  final $Res Function(UploadItem) _then;

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? localPath = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? mimeType = null,
    Object? status = null,
    Object? progress = null,
    Object? uploadJobId = freezed,
    Object? s3Key = freezed,
    Object? presignedUrl = freezed,
    Object? etag = freezed,
    Object? errorMessage = freezed,
    Object? queuedAt = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      localPath: null == localPath
          ? _self.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      mimeType: null == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as UploadStatus,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      uploadJobId: freezed == uploadJobId
          ? _self.uploadJobId
          : uploadJobId // ignore: cast_nullable_to_non_nullable
              as String?,
      s3Key: freezed == s3Key
          ? _self.s3Key
          : s3Key // ignore: cast_nullable_to_non_nullable
              as String?,
      presignedUrl: freezed == presignedUrl
          ? _self.presignedUrl
          : presignedUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      etag: freezed == etag
          ? _self.etag
          : etag // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      queuedAt: freezed == queuedAt
          ? _self.queuedAt
          : queuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startedAt: freezed == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [UploadItem].
extension UploadItemPatterns on UploadItem {
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
    TResult Function(_UploadItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UploadItem() when $default != null:
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
    TResult Function(_UploadItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadItem():
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
    TResult? Function(_UploadItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadItem() when $default != null:
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
            String id,
            String localPath,
            String fileName,
            int fileSize,
            String mimeType,
            UploadStatus status,
            double progress,
            String? uploadJobId,
            String? s3Key,
            String? presignedUrl,
            String? etag,
            String? errorMessage,
            DateTime? queuedAt,
            DateTime? startedAt,
            DateTime? completedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UploadItem() when $default != null:
        return $default(
            _that.id,
            _that.localPath,
            _that.fileName,
            _that.fileSize,
            _that.mimeType,
            _that.status,
            _that.progress,
            _that.uploadJobId,
            _that.s3Key,
            _that.presignedUrl,
            _that.etag,
            _that.errorMessage,
            _that.queuedAt,
            _that.startedAt,
            _that.completedAt);
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
            String id,
            String localPath,
            String fileName,
            int fileSize,
            String mimeType,
            UploadStatus status,
            double progress,
            String? uploadJobId,
            String? s3Key,
            String? presignedUrl,
            String? etag,
            String? errorMessage,
            DateTime? queuedAt,
            DateTime? startedAt,
            DateTime? completedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadItem():
        return $default(
            _that.id,
            _that.localPath,
            _that.fileName,
            _that.fileSize,
            _that.mimeType,
            _that.status,
            _that.progress,
            _that.uploadJobId,
            _that.s3Key,
            _that.presignedUrl,
            _that.etag,
            _that.errorMessage,
            _that.queuedAt,
            _that.startedAt,
            _that.completedAt);
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
            String id,
            String localPath,
            String fileName,
            int fileSize,
            String mimeType,
            UploadStatus status,
            double progress,
            String? uploadJobId,
            String? s3Key,
            String? presignedUrl,
            String? etag,
            String? errorMessage,
            DateTime? queuedAt,
            DateTime? startedAt,
            DateTime? completedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadItem() when $default != null:
        return $default(
            _that.id,
            _that.localPath,
            _that.fileName,
            _that.fileSize,
            _that.mimeType,
            _that.status,
            _that.progress,
            _that.uploadJobId,
            _that.s3Key,
            _that.presignedUrl,
            _that.etag,
            _that.errorMessage,
            _that.queuedAt,
            _that.startedAt,
            _that.completedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UploadItem implements UploadItem {
  const _UploadItem(
      {required this.id,
      required this.localPath,
      required this.fileName,
      required this.fileSize,
      required this.mimeType,
      this.status = UploadStatus.queued,
      this.progress = 0.0,
      this.uploadJobId,
      this.s3Key,
      this.presignedUrl,
      this.etag,
      this.errorMessage,
      this.queuedAt,
      this.startedAt,
      this.completedAt});
  factory _UploadItem.fromJson(Map<String, dynamic> json) =>
      _$UploadItemFromJson(json);

  @override
  final String id;
  @override
  final String localPath;
  @override
  final String fileName;
  @override
  final int fileSize;
  @override
  final String mimeType;
  @override
  @JsonKey()
  final UploadStatus status;
  @override
  @JsonKey()
  final double progress;
  @override
  final String? uploadJobId;
  @override
  final String? s3Key;
  @override
  final String? presignedUrl;
  @override
  final String? etag;
  @override
  final String? errorMessage;
  @override
  final DateTime? queuedAt;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? completedAt;

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UploadItemCopyWith<_UploadItem> get copyWith =>
      __$UploadItemCopyWithImpl<_UploadItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UploadItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UploadItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.uploadJobId, uploadJobId) ||
                other.uploadJobId == uploadJobId) &&
            (identical(other.s3Key, s3Key) || other.s3Key == s3Key) &&
            (identical(other.presignedUrl, presignedUrl) ||
                other.presignedUrl == presignedUrl) &&
            (identical(other.etag, etag) || other.etag == etag) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.queuedAt, queuedAt) ||
                other.queuedAt == queuedAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      localPath,
      fileName,
      fileSize,
      mimeType,
      status,
      progress,
      uploadJobId,
      s3Key,
      presignedUrl,
      etag,
      errorMessage,
      queuedAt,
      startedAt,
      completedAt);

  @override
  String toString() {
    return 'UploadItem(id: $id, localPath: $localPath, fileName: $fileName, fileSize: $fileSize, mimeType: $mimeType, status: $status, progress: $progress, uploadJobId: $uploadJobId, s3Key: $s3Key, presignedUrl: $presignedUrl, etag: $etag, errorMessage: $errorMessage, queuedAt: $queuedAt, startedAt: $startedAt, completedAt: $completedAt)';
  }
}

/// @nodoc
abstract mixin class _$UploadItemCopyWith<$Res>
    implements $UploadItemCopyWith<$Res> {
  factory _$UploadItemCopyWith(
          _UploadItem value, $Res Function(_UploadItem) _then) =
      __$UploadItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String localPath,
      String fileName,
      int fileSize,
      String mimeType,
      UploadStatus status,
      double progress,
      String? uploadJobId,
      String? s3Key,
      String? presignedUrl,
      String? etag,
      String? errorMessage,
      DateTime? queuedAt,
      DateTime? startedAt,
      DateTime? completedAt});
}

/// @nodoc
class __$UploadItemCopyWithImpl<$Res> implements _$UploadItemCopyWith<$Res> {
  __$UploadItemCopyWithImpl(this._self, this._then);

  final _UploadItem _self;
  final $Res Function(_UploadItem) _then;

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? localPath = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? mimeType = null,
    Object? status = null,
    Object? progress = null,
    Object? uploadJobId = freezed,
    Object? s3Key = freezed,
    Object? presignedUrl = freezed,
    Object? etag = freezed,
    Object? errorMessage = freezed,
    Object? queuedAt = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_UploadItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      localPath: null == localPath
          ? _self.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      mimeType: null == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as UploadStatus,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      uploadJobId: freezed == uploadJobId
          ? _self.uploadJobId
          : uploadJobId // ignore: cast_nullable_to_non_nullable
              as String?,
      s3Key: freezed == s3Key
          ? _self.s3Key
          : s3Key // ignore: cast_nullable_to_non_nullable
              as String?,
      presignedUrl: freezed == presignedUrl
          ? _self.presignedUrl
          : presignedUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      etag: freezed == etag
          ? _self.etag
          : etag // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      queuedAt: freezed == queuedAt
          ? _self.queuedAt
          : queuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startedAt: freezed == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
mixin _$UploadQueueState {
  List<UploadItem> get items;
  int get activeUploads;
  bool get isPaused;
  bool get isProcessing;

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UploadQueueStateCopyWith<UploadQueueState> get copyWith =>
      _$UploadQueueStateCopyWithImpl<UploadQueueState>(
          this as UploadQueueState, _$identity);

  /// Serializes this UploadQueueState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UploadQueueState &&
            const DeepCollectionEquality().equals(other.items, items) &&
            (identical(other.activeUploads, activeUploads) ||
                other.activeUploads == activeUploads) &&
            (identical(other.isPaused, isPaused) ||
                other.isPaused == isPaused) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(items),
      activeUploads,
      isPaused,
      isProcessing);

  @override
  String toString() {
    return 'UploadQueueState(items: $items, activeUploads: $activeUploads, isPaused: $isPaused, isProcessing: $isProcessing)';
  }
}

/// @nodoc
abstract mixin class $UploadQueueStateCopyWith<$Res> {
  factory $UploadQueueStateCopyWith(
          UploadQueueState value, $Res Function(UploadQueueState) _then) =
      _$UploadQueueStateCopyWithImpl;
  @useResult
  $Res call(
      {List<UploadItem> items,
      int activeUploads,
      bool isPaused,
      bool isProcessing});
}

/// @nodoc
class _$UploadQueueStateCopyWithImpl<$Res>
    implements $UploadQueueStateCopyWith<$Res> {
  _$UploadQueueStateCopyWithImpl(this._self, this._then);

  final UploadQueueState _self;
  final $Res Function(UploadQueueState) _then;

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? activeUploads = null,
    Object? isPaused = null,
    Object? isProcessing = null,
  }) {
    return _then(_self.copyWith(
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<UploadItem>,
      activeUploads: null == activeUploads
          ? _self.activeUploads
          : activeUploads // ignore: cast_nullable_to_non_nullable
              as int,
      isPaused: null == isPaused
          ? _self.isPaused
          : isPaused // ignore: cast_nullable_to_non_nullable
              as bool,
      isProcessing: null == isProcessing
          ? _self.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [UploadQueueState].
extension UploadQueueStatePatterns on UploadQueueState {
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
    TResult Function(_UploadQueueState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UploadQueueState() when $default != null:
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
    TResult Function(_UploadQueueState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadQueueState():
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
    TResult? Function(_UploadQueueState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadQueueState() when $default != null:
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
    TResult Function(List<UploadItem> items, int activeUploads, bool isPaused,
            bool isProcessing)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UploadQueueState() when $default != null:
        return $default(_that.items, _that.activeUploads, _that.isPaused,
            _that.isProcessing);
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
    TResult Function(List<UploadItem> items, int activeUploads, bool isPaused,
            bool isProcessing)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadQueueState():
        return $default(_that.items, _that.activeUploads, _that.isPaused,
            _that.isProcessing);
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
    TResult? Function(List<UploadItem> items, int activeUploads, bool isPaused,
            bool isProcessing)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UploadQueueState() when $default != null:
        return $default(_that.items, _that.activeUploads, _that.isPaused,
            _that.isProcessing);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UploadQueueState implements UploadQueueState {
  const _UploadQueueState(
      {final List<UploadItem> items = const [],
      this.activeUploads = 0,
      this.isPaused = false,
      this.isProcessing = false})
      : _items = items;
  factory _UploadQueueState.fromJson(Map<String, dynamic> json) =>
      _$UploadQueueStateFromJson(json);

  final List<UploadItem> _items;
  @override
  @JsonKey()
  List<UploadItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final int activeUploads;
  @override
  @JsonKey()
  final bool isPaused;
  @override
  @JsonKey()
  final bool isProcessing;

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UploadQueueStateCopyWith<_UploadQueueState> get copyWith =>
      __$UploadQueueStateCopyWithImpl<_UploadQueueState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UploadQueueStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UploadQueueState &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.activeUploads, activeUploads) ||
                other.activeUploads == activeUploads) &&
            (identical(other.isPaused, isPaused) ||
                other.isPaused == isPaused) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      activeUploads,
      isPaused,
      isProcessing);

  @override
  String toString() {
    return 'UploadQueueState(items: $items, activeUploads: $activeUploads, isPaused: $isPaused, isProcessing: $isProcessing)';
  }
}

/// @nodoc
abstract mixin class _$UploadQueueStateCopyWith<$Res>
    implements $UploadQueueStateCopyWith<$Res> {
  factory _$UploadQueueStateCopyWith(
          _UploadQueueState value, $Res Function(_UploadQueueState) _then) =
      __$UploadQueueStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<UploadItem> items,
      int activeUploads,
      bool isPaused,
      bool isProcessing});
}

/// @nodoc
class __$UploadQueueStateCopyWithImpl<$Res>
    implements _$UploadQueueStateCopyWith<$Res> {
  __$UploadQueueStateCopyWithImpl(this._self, this._then);

  final _UploadQueueState _self;
  final $Res Function(_UploadQueueState) _then;

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? items = null,
    Object? activeUploads = null,
    Object? isPaused = null,
    Object? isProcessing = null,
  }) {
    return _then(_UploadQueueState(
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<UploadItem>,
      activeUploads: null == activeUploads
          ? _self.activeUploads
          : activeUploads // ignore: cast_nullable_to_non_nullable
              as int,
      isPaused: null == isPaused
          ? _self.isPaused
          : isPaused // ignore: cast_nullable_to_non_nullable
              as bool,
      isProcessing: null == isProcessing
          ? _self.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
