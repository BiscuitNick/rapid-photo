// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoListItem {
  String get id;
  String get fileName;
  PhotoStatus get status;
  String get thumbnailUrl;
  int? get width;
  int? get height;
  List<String> get labels;
  DateTime get createdAt;
  DateTime? get takenAt;

  /// Create a copy of PhotoListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PhotoListItemCopyWith<PhotoListItem> get copyWith =>
      _$PhotoListItemCopyWithImpl<PhotoListItem>(
          this as PhotoListItem, _$identity);

  /// Serializes this PhotoListItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhotoListItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            const DeepCollectionEquality().equals(other.labels, labels) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.takenAt, takenAt) || other.takenAt == takenAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      fileName,
      status,
      thumbnailUrl,
      width,
      height,
      const DeepCollectionEquality().hash(labels),
      createdAt,
      takenAt);

  @override
  String toString() {
    return 'PhotoListItem(id: $id, fileName: $fileName, status: $status, thumbnailUrl: $thumbnailUrl, width: $width, height: $height, labels: $labels, createdAt: $createdAt, takenAt: $takenAt)';
  }
}

/// @nodoc
abstract mixin class $PhotoListItemCopyWith<$Res> {
  factory $PhotoListItemCopyWith(
          PhotoListItem value, $Res Function(PhotoListItem) _then) =
      _$PhotoListItemCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String fileName,
      PhotoStatus status,
      String thumbnailUrl,
      int? width,
      int? height,
      List<String> labels,
      DateTime createdAt,
      DateTime? takenAt});
}

/// @nodoc
class _$PhotoListItemCopyWithImpl<$Res>
    implements $PhotoListItemCopyWith<$Res> {
  _$PhotoListItemCopyWithImpl(this._self, this._then);

  final PhotoListItem _self;
  final $Res Function(PhotoListItem) _then;

  /// Create a copy of PhotoListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? status = null,
    Object? thumbnailUrl = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? labels = null,
    Object? createdAt = null,
    Object? takenAt = freezed,
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
      thumbnailUrl: null == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      labels: null == labels
          ? _self.labels
          : labels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      takenAt: freezed == takenAt
          ? _self.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PhotoListItem].
extension PhotoListItemPatterns on PhotoListItem {
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
    TResult Function(_PhotoListItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoListItem() when $default != null:
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
    TResult Function(_PhotoListItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoListItem():
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
    TResult? Function(_PhotoListItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoListItem() when $default != null:
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
            String thumbnailUrl,
            int? width,
            int? height,
            List<String> labels,
            DateTime createdAt,
            DateTime? takenAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoListItem() when $default != null:
        return $default(
            _that.id,
            _that.fileName,
            _that.status,
            _that.thumbnailUrl,
            _that.width,
            _that.height,
            _that.labels,
            _that.createdAt,
            _that.takenAt);
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
            String thumbnailUrl,
            int? width,
            int? height,
            List<String> labels,
            DateTime createdAt,
            DateTime? takenAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoListItem():
        return $default(
            _that.id,
            _that.fileName,
            _that.status,
            _that.thumbnailUrl,
            _that.width,
            _that.height,
            _that.labels,
            _that.createdAt,
            _that.takenAt);
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
            String thumbnailUrl,
            int? width,
            int? height,
            List<String> labels,
            DateTime createdAt,
            DateTime? takenAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoListItem() when $default != null:
        return $default(
            _that.id,
            _that.fileName,
            _that.status,
            _that.thumbnailUrl,
            _that.width,
            _that.height,
            _that.labels,
            _that.createdAt,
            _that.takenAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PhotoListItem implements PhotoListItem {
  const _PhotoListItem(
      {required this.id,
      required this.fileName,
      required this.status,
      required this.thumbnailUrl,
      this.width,
      this.height,
      final List<String> labels = const [],
      required this.createdAt,
      this.takenAt})
      : _labels = labels;
  factory _PhotoListItem.fromJson(Map<String, dynamic> json) =>
      _$PhotoListItemFromJson(json);

  @override
  final String id;
  @override
  final String fileName;
  @override
  final PhotoStatus status;
  @override
  final String thumbnailUrl;
  @override
  final int? width;
  @override
  final int? height;
  final List<String> _labels;
  @override
  @JsonKey()
  List<String> get labels {
    if (_labels is EqualUnmodifiableListView) return _labels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_labels);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? takenAt;

  /// Create a copy of PhotoListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PhotoListItemCopyWith<_PhotoListItem> get copyWith =>
      __$PhotoListItemCopyWithImpl<_PhotoListItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PhotoListItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PhotoListItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            const DeepCollectionEquality().equals(other._labels, _labels) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.takenAt, takenAt) || other.takenAt == takenAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      fileName,
      status,
      thumbnailUrl,
      width,
      height,
      const DeepCollectionEquality().hash(_labels),
      createdAt,
      takenAt);

  @override
  String toString() {
    return 'PhotoListItem(id: $id, fileName: $fileName, status: $status, thumbnailUrl: $thumbnailUrl, width: $width, height: $height, labels: $labels, createdAt: $createdAt, takenAt: $takenAt)';
  }
}

/// @nodoc
abstract mixin class _$PhotoListItemCopyWith<$Res>
    implements $PhotoListItemCopyWith<$Res> {
  factory _$PhotoListItemCopyWith(
          _PhotoListItem value, $Res Function(_PhotoListItem) _then) =
      __$PhotoListItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String fileName,
      PhotoStatus status,
      String thumbnailUrl,
      int? width,
      int? height,
      List<String> labels,
      DateTime createdAt,
      DateTime? takenAt});
}

/// @nodoc
class __$PhotoListItemCopyWithImpl<$Res>
    implements _$PhotoListItemCopyWith<$Res> {
  __$PhotoListItemCopyWithImpl(this._self, this._then);

  final _PhotoListItem _self;
  final $Res Function(_PhotoListItem) _then;

  /// Create a copy of PhotoListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? status = null,
    Object? thumbnailUrl = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? labels = null,
    Object? createdAt = null,
    Object? takenAt = freezed,
  }) {
    return _then(_PhotoListItem(
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
      thumbnailUrl: null == thumbnailUrl
          ? _self.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      labels: null == labels
          ? _self._labels
          : labels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      takenAt: freezed == takenAt
          ? _self.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
