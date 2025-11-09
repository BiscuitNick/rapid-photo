// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoResponse {
  String get id;
  String get fileName;
  PhotoStatus get status;
  int? get fileSize;
  String? get mimeType;
  int? get width;
  int? get height;
  String? get originalUrl;
  String? get thumbnailUrl;
  List<PhotoVersion> get versions;
  List<PhotoLabel> get labels;
  @JsonKey(fromJson: _dateTimeFromEpochSeconds)
  DateTime get createdAt;
  @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
  DateTime? get processedAt;
  @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
  DateTime? get takenAt;
  String? get cameraMake;
  String? get cameraModel;
  double? get gpsLatitude;
  double? get gpsLongitude;

  /// Create a copy of PhotoResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PhotoResponseCopyWith<PhotoResponse> get copyWith =>
      _$PhotoResponseCopyWithImpl<PhotoResponse>(
          this as PhotoResponse, _$identity);

  /// Serializes this PhotoResponse to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhotoResponse &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.originalUrl, originalUrl) ||
                other.originalUrl == originalUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality().equals(other.versions, versions) &&
            const DeepCollectionEquality().equals(other.labels, labels) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.takenAt, takenAt) || other.takenAt == takenAt) &&
            (identical(other.cameraMake, cameraMake) ||
                other.cameraMake == cameraMake) &&
            (identical(other.cameraModel, cameraModel) ||
                other.cameraModel == cameraModel) &&
            (identical(other.gpsLatitude, gpsLatitude) ||
                other.gpsLatitude == gpsLatitude) &&
            (identical(other.gpsLongitude, gpsLongitude) ||
                other.gpsLongitude == gpsLongitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      fileName,
      status,
      fileSize,
      mimeType,
      width,
      height,
      originalUrl,
      thumbnailUrl,
      const DeepCollectionEquality().hash(versions),
      const DeepCollectionEquality().hash(labels),
      createdAt,
      processedAt,
      takenAt,
      cameraMake,
      cameraModel,
      gpsLatitude,
      gpsLongitude);

  @override
  String toString() {
    return 'PhotoResponse(id: $id, fileName: $fileName, status: $status, fileSize: $fileSize, mimeType: $mimeType, width: $width, height: $height, originalUrl: $originalUrl, thumbnailUrl: $thumbnailUrl, versions: $versions, labels: $labels, createdAt: $createdAt, processedAt: $processedAt, takenAt: $takenAt, cameraMake: $cameraMake, cameraModel: $cameraModel, gpsLatitude: $gpsLatitude, gpsLongitude: $gpsLongitude)';
  }
}

/// @nodoc
abstract mixin class $PhotoResponseCopyWith<$Res> {
  factory $PhotoResponseCopyWith(
          PhotoResponse value, $Res Function(PhotoResponse) _then) =
      _$PhotoResponseCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String fileName,
      PhotoStatus status,
      int? fileSize,
      String? mimeType,
      int? width,
      int? height,
      String? originalUrl,
      String? thumbnailUrl,
      List<PhotoVersion> versions,
      List<PhotoLabel> labels,
      @JsonKey(fromJson: _dateTimeFromEpochSeconds) DateTime createdAt,
      @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
      DateTime? processedAt,
      @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable) DateTime? takenAt,
      String? cameraMake,
      String? cameraModel,
      double? gpsLatitude,
      double? gpsLongitude});
}

/// @nodoc
class _$PhotoResponseCopyWithImpl<$Res>
    implements $PhotoResponseCopyWith<$Res> {
  _$PhotoResponseCopyWithImpl(this._self, this._then);

  final PhotoResponse _self;
  final $Res Function(PhotoResponse) _then;

  /// Create a copy of PhotoResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? status = null,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? originalUrl = freezed,
    Object? thumbnailUrl = freezed,
    Object? versions = null,
    Object? labels = null,
    Object? createdAt = null,
    Object? processedAt = freezed,
    Object? takenAt = freezed,
    Object? cameraMake = freezed,
    Object? cameraModel = freezed,
    Object? gpsLatitude = freezed,
    Object? gpsLongitude = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PhotoStatus,
      fileSize: freezed == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      mimeType: freezed == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      originalUrl: freezed == originalUrl
          ? _self.originalUrl
          : originalUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      versions: null == versions
          ? _self.versions
          : versions // ignore: cast_nullable_to_non_nullable
              as List<PhotoVersion>,
      labels: null == labels
          ? _self.labels
          : labels // ignore: cast_nullable_to_non_nullable
              as List<PhotoLabel>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      processedAt: freezed == processedAt
          ? _self.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      takenAt: freezed == takenAt
          ? _self.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cameraMake: freezed == cameraMake
          ? _self.cameraMake
          : cameraMake // ignore: cast_nullable_to_non_nullable
              as String?,
      cameraModel: freezed == cameraModel
          ? _self.cameraModel
          : cameraModel // ignore: cast_nullable_to_non_nullable
              as String?,
      gpsLatitude: freezed == gpsLatitude
          ? _self.gpsLatitude
          : gpsLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      gpsLongitude: freezed == gpsLongitude
          ? _self.gpsLongitude
          : gpsLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PhotoResponse].
extension PhotoResponsePatterns on PhotoResponse {
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
    TResult Function(_PhotoResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoResponse() when $default != null:
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
    TResult Function(_PhotoResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoResponse():
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
    TResult? Function(_PhotoResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoResponse() when $default != null:
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
            String fileName,
            PhotoStatus status,
            int? fileSize,
            String? mimeType,
            int? width,
            int? height,
            String? originalUrl,
            String? thumbnailUrl,
            List<PhotoVersion> versions,
            List<PhotoLabel> labels,
            @JsonKey(fromJson: _dateTimeFromEpochSeconds) DateTime createdAt,
            @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
            DateTime? processedAt,
            @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
            DateTime? takenAt,
            String? cameraMake,
            String? cameraModel,
            double? gpsLatitude,
            double? gpsLongitude)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoResponse() when $default != null:
        return $default(
            _that.id,
            _that.fileName,
            _that.status,
            _that.fileSize,
            _that.mimeType,
            _that.width,
            _that.height,
            _that.originalUrl,
            _that.thumbnailUrl,
            _that.versions,
            _that.labels,
            _that.createdAt,
            _that.processedAt,
            _that.takenAt,
            _that.cameraMake,
            _that.cameraModel,
            _that.gpsLatitude,
            _that.gpsLongitude);
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
            String fileName,
            PhotoStatus status,
            int? fileSize,
            String? mimeType,
            int? width,
            int? height,
            String? originalUrl,
            String? thumbnailUrl,
            List<PhotoVersion> versions,
            List<PhotoLabel> labels,
            @JsonKey(fromJson: _dateTimeFromEpochSeconds) DateTime createdAt,
            @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
            DateTime? processedAt,
            @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
            DateTime? takenAt,
            String? cameraMake,
            String? cameraModel,
            double? gpsLatitude,
            double? gpsLongitude)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoResponse():
        return $default(
            _that.id,
            _that.fileName,
            _that.status,
            _that.fileSize,
            _that.mimeType,
            _that.width,
            _that.height,
            _that.originalUrl,
            _that.thumbnailUrl,
            _that.versions,
            _that.labels,
            _that.createdAt,
            _that.processedAt,
            _that.takenAt,
            _that.cameraMake,
            _that.cameraModel,
            _that.gpsLatitude,
            _that.gpsLongitude);
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
            String fileName,
            PhotoStatus status,
            int? fileSize,
            String? mimeType,
            int? width,
            int? height,
            String? originalUrl,
            String? thumbnailUrl,
            List<PhotoVersion> versions,
            List<PhotoLabel> labels,
            @JsonKey(fromJson: _dateTimeFromEpochSeconds) DateTime createdAt,
            @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
            DateTime? processedAt,
            @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
            DateTime? takenAt,
            String? cameraMake,
            String? cameraModel,
            double? gpsLatitude,
            double? gpsLongitude)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoResponse() when $default != null:
        return $default(
            _that.id,
            _that.fileName,
            _that.status,
            _that.fileSize,
            _that.mimeType,
            _that.width,
            _that.height,
            _that.originalUrl,
            _that.thumbnailUrl,
            _that.versions,
            _that.labels,
            _that.createdAt,
            _that.processedAt,
            _that.takenAt,
            _that.cameraMake,
            _that.cameraModel,
            _that.gpsLatitude,
            _that.gpsLongitude);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PhotoResponse implements PhotoResponse {
  const _PhotoResponse(
      {required this.id,
      required this.fileName,
      required this.status,
      this.fileSize,
      this.mimeType,
      this.width,
      this.height,
      this.originalUrl,
      this.thumbnailUrl,
      final List<PhotoVersion> versions = const [],
      final List<PhotoLabel> labels = const [],
      @JsonKey(fromJson: _dateTimeFromEpochSeconds) required this.createdAt,
      @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable) this.processedAt,
      @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable) this.takenAt,
      this.cameraMake,
      this.cameraModel,
      this.gpsLatitude,
      this.gpsLongitude})
      : _versions = versions,
        _labels = labels;
  factory _PhotoResponse.fromJson(Map<String, dynamic> json) =>
      _$PhotoResponseFromJson(json);

  @override
  final String id;
  @override
  final String fileName;
  @override
  final PhotoStatus status;
  @override
  final int? fileSize;
  @override
  final String? mimeType;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final String? originalUrl;
  @override
  final String? thumbnailUrl;
  final List<PhotoVersion> _versions;
  @override
  @JsonKey()
  List<PhotoVersion> get versions {
    if (_versions is EqualUnmodifiableListView) return _versions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_versions);
  }

  final List<PhotoLabel> _labels;
  @override
  @JsonKey()
  List<PhotoLabel> get labels {
    if (_labels is EqualUnmodifiableListView) return _labels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_labels);
  }

  @override
  @JsonKey(fromJson: _dateTimeFromEpochSeconds)
  final DateTime createdAt;
  @override
  @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
  final DateTime? processedAt;
  @override
  @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
  final DateTime? takenAt;
  @override
  final String? cameraMake;
  @override
  final String? cameraModel;
  @override
  final double? gpsLatitude;
  @override
  final double? gpsLongitude;

  /// Create a copy of PhotoResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PhotoResponseCopyWith<_PhotoResponse> get copyWith =>
      __$PhotoResponseCopyWithImpl<_PhotoResponse>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PhotoResponseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PhotoResponse &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.originalUrl, originalUrl) ||
                other.originalUrl == originalUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality().equals(other._versions, _versions) &&
            const DeepCollectionEquality().equals(other._labels, _labels) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.takenAt, takenAt) || other.takenAt == takenAt) &&
            (identical(other.cameraMake, cameraMake) ||
                other.cameraMake == cameraMake) &&
            (identical(other.cameraModel, cameraModel) ||
                other.cameraModel == cameraModel) &&
            (identical(other.gpsLatitude, gpsLatitude) ||
                other.gpsLatitude == gpsLatitude) &&
            (identical(other.gpsLongitude, gpsLongitude) ||
                other.gpsLongitude == gpsLongitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      fileName,
      status,
      fileSize,
      mimeType,
      width,
      height,
      originalUrl,
      thumbnailUrl,
      const DeepCollectionEquality().hash(_versions),
      const DeepCollectionEquality().hash(_labels),
      createdAt,
      processedAt,
      takenAt,
      cameraMake,
      cameraModel,
      gpsLatitude,
      gpsLongitude);

  @override
  String toString() {
    return 'PhotoResponse(id: $id, fileName: $fileName, status: $status, fileSize: $fileSize, mimeType: $mimeType, width: $width, height: $height, originalUrl: $originalUrl, thumbnailUrl: $thumbnailUrl, versions: $versions, labels: $labels, createdAt: $createdAt, processedAt: $processedAt, takenAt: $takenAt, cameraMake: $cameraMake, cameraModel: $cameraModel, gpsLatitude: $gpsLatitude, gpsLongitude: $gpsLongitude)';
  }
}

/// @nodoc
abstract mixin class _$PhotoResponseCopyWith<$Res>
    implements $PhotoResponseCopyWith<$Res> {
  factory _$PhotoResponseCopyWith(
          _PhotoResponse value, $Res Function(_PhotoResponse) _then) =
      __$PhotoResponseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String fileName,
      PhotoStatus status,
      int? fileSize,
      String? mimeType,
      int? width,
      int? height,
      String? originalUrl,
      String? thumbnailUrl,
      List<PhotoVersion> versions,
      List<PhotoLabel> labels,
      @JsonKey(fromJson: _dateTimeFromEpochSeconds) DateTime createdAt,
      @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable)
      DateTime? processedAt,
      @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable) DateTime? takenAt,
      String? cameraMake,
      String? cameraModel,
      double? gpsLatitude,
      double? gpsLongitude});
}

/// @nodoc
class __$PhotoResponseCopyWithImpl<$Res>
    implements _$PhotoResponseCopyWith<$Res> {
  __$PhotoResponseCopyWithImpl(this._self, this._then);

  final _PhotoResponse _self;
  final $Res Function(_PhotoResponse) _then;

  /// Create a copy of PhotoResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? status = null,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? originalUrl = freezed,
    Object? thumbnailUrl = freezed,
    Object? versions = null,
    Object? labels = null,
    Object? createdAt = null,
    Object? processedAt = freezed,
    Object? takenAt = freezed,
    Object? cameraMake = freezed,
    Object? cameraModel = freezed,
    Object? gpsLatitude = freezed,
    Object? gpsLongitude = freezed,
  }) {
    return _then(_PhotoResponse(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PhotoStatus,
      fileSize: freezed == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      mimeType: freezed == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      originalUrl: freezed == originalUrl
          ? _self.originalUrl
          : originalUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      versions: null == versions
          ? _self._versions
          : versions // ignore: cast_nullable_to_non_nullable
              as List<PhotoVersion>,
      labels: null == labels
          ? _self._labels
          : labels // ignore: cast_nullable_to_non_nullable
              as List<PhotoLabel>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      processedAt: freezed == processedAt
          ? _self.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      takenAt: freezed == takenAt
          ? _self.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cameraMake: freezed == cameraMake
          ? _self.cameraMake
          : cameraMake // ignore: cast_nullable_to_non_nullable
              as String?,
      cameraModel: freezed == cameraModel
          ? _self.cameraModel
          : cameraModel // ignore: cast_nullable_to_non_nullable
              as String?,
      gpsLatitude: freezed == gpsLatitude
          ? _self.gpsLatitude
          : gpsLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      gpsLongitude: freezed == gpsLongitude
          ? _self.gpsLongitude
          : gpsLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

// dart format on
