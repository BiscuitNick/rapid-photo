// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoVersion {
  PhotoVersionType get versionType;
  String get url;
  int? get width;
  int? get height;
  int? get fileSize;
  String? get mimeType;

  /// Create a copy of PhotoVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PhotoVersionCopyWith<PhotoVersion> get copyWith =>
      _$PhotoVersionCopyWithImpl<PhotoVersion>(
          this as PhotoVersion, _$identity);

  /// Serializes this PhotoVersion to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhotoVersion &&
            (identical(other.versionType, versionType) ||
                other.versionType == versionType) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, versionType, url, width, height, fileSize, mimeType);

  @override
  String toString() {
    return 'PhotoVersion(versionType: $versionType, url: $url, width: $width, height: $height, fileSize: $fileSize, mimeType: $mimeType)';
  }
}

/// @nodoc
abstract mixin class $PhotoVersionCopyWith<$Res> {
  factory $PhotoVersionCopyWith(
          PhotoVersion value, $Res Function(PhotoVersion) _then) =
      _$PhotoVersionCopyWithImpl;
  @useResult
  $Res call(
      {PhotoVersionType versionType,
      String url,
      int? width,
      int? height,
      int? fileSize,
      String? mimeType});
}

/// @nodoc
class _$PhotoVersionCopyWithImpl<$Res> implements $PhotoVersionCopyWith<$Res> {
  _$PhotoVersionCopyWithImpl(this._self, this._then);

  final PhotoVersion _self;
  final $Res Function(PhotoVersion) _then;

  /// Create a copy of PhotoVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? versionType = null,
    Object? url = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(_self.copyWith(
      versionType: null == versionType
          ? _self.versionType
          : versionType // ignore: cast_nullable_to_non_nullable
              as PhotoVersionType,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      fileSize: freezed == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      mimeType: freezed == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PhotoVersion].
extension PhotoVersionPatterns on PhotoVersion {
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
    TResult Function(_PhotoVersion value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoVersion() when $default != null:
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
    TResult Function(_PhotoVersion value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoVersion():
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
    TResult? Function(_PhotoVersion value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoVersion() when $default != null:
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
    TResult Function(PhotoVersionType versionType, String url, int? width,
            int? height, int? fileSize, String? mimeType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoVersion() when $default != null:
        return $default(_that.versionType, _that.url, _that.width, _that.height,
            _that.fileSize, _that.mimeType);
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
    TResult Function(PhotoVersionType versionType, String url, int? width,
            int? height, int? fileSize, String? mimeType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoVersion():
        return $default(_that.versionType, _that.url, _that.width, _that.height,
            _that.fileSize, _that.mimeType);
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
    TResult? Function(PhotoVersionType versionType, String url, int? width,
            int? height, int? fileSize, String? mimeType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoVersion() when $default != null:
        return $default(_that.versionType, _that.url, _that.width, _that.height,
            _that.fileSize, _that.mimeType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PhotoVersion implements PhotoVersion {
  const _PhotoVersion(
      {required this.versionType,
      required this.url,
      this.width,
      this.height,
      this.fileSize,
      this.mimeType});
  factory _PhotoVersion.fromJson(Map<String, dynamic> json) =>
      _$PhotoVersionFromJson(json);

  @override
  final PhotoVersionType versionType;
  @override
  final String url;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final int? fileSize;
  @override
  final String? mimeType;

  /// Create a copy of PhotoVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PhotoVersionCopyWith<_PhotoVersion> get copyWith =>
      __$PhotoVersionCopyWithImpl<_PhotoVersion>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PhotoVersionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PhotoVersion &&
            (identical(other.versionType, versionType) ||
                other.versionType == versionType) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, versionType, url, width, height, fileSize, mimeType);

  @override
  String toString() {
    return 'PhotoVersion(versionType: $versionType, url: $url, width: $width, height: $height, fileSize: $fileSize, mimeType: $mimeType)';
  }
}

/// @nodoc
abstract mixin class _$PhotoVersionCopyWith<$Res>
    implements $PhotoVersionCopyWith<$Res> {
  factory _$PhotoVersionCopyWith(
          _PhotoVersion value, $Res Function(_PhotoVersion) _then) =
      __$PhotoVersionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {PhotoVersionType versionType,
      String url,
      int? width,
      int? height,
      int? fileSize,
      String? mimeType});
}

/// @nodoc
class __$PhotoVersionCopyWithImpl<$Res>
    implements _$PhotoVersionCopyWith<$Res> {
  __$PhotoVersionCopyWithImpl(this._self, this._then);

  final _PhotoVersion _self;
  final $Res Function(_PhotoVersion) _then;

  /// Create a copy of PhotoVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? versionType = null,
    Object? url = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(_PhotoVersion(
      versionType: null == versionType
          ? _self.versionType
          : versionType // ignore: cast_nullable_to_non_nullable
              as PhotoVersionType,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      fileSize: freezed == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      mimeType: freezed == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
