// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paged_photos_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PagedPhotosResponse {
  List<PhotoListItem> get content;
  int get page;
  int get size;
  int get totalElements;
  int get totalPages;
  bool get hasNext;
  bool get hasPrevious;

  /// Create a copy of PagedPhotosResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PagedPhotosResponseCopyWith<PagedPhotosResponse> get copyWith =>
      _$PagedPhotosResponseCopyWithImpl<PagedPhotosResponse>(
          this as PagedPhotosResponse, _$identity);

  /// Serializes this PagedPhotosResponse to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PagedPhotosResponse &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.totalElements, totalElements) ||
                other.totalElements == totalElements) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.hasNext, hasNext) || other.hasNext == hasNext) &&
            (identical(other.hasPrevious, hasPrevious) ||
                other.hasPrevious == hasPrevious));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(content),
      page,
      size,
      totalElements,
      totalPages,
      hasNext,
      hasPrevious);

  @override
  String toString() {
    return 'PagedPhotosResponse(content: $content, page: $page, size: $size, totalElements: $totalElements, totalPages: $totalPages, hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }
}

/// @nodoc
abstract mixin class $PagedPhotosResponseCopyWith<$Res> {
  factory $PagedPhotosResponseCopyWith(
          PagedPhotosResponse value, $Res Function(PagedPhotosResponse) _then) =
      _$PagedPhotosResponseCopyWithImpl;
  @useResult
  $Res call(
      {List<PhotoListItem> content,
      int page,
      int size,
      int totalElements,
      int totalPages,
      bool hasNext,
      bool hasPrevious});
}

/// @nodoc
class _$PagedPhotosResponseCopyWithImpl<$Res>
    implements $PagedPhotosResponseCopyWith<$Res> {
  _$PagedPhotosResponseCopyWithImpl(this._self, this._then);

  final PagedPhotosResponse _self;
  final $Res Function(PagedPhotosResponse) _then;

  /// Create a copy of PagedPhotosResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? page = null,
    Object? size = null,
    Object? totalElements = null,
    Object? totalPages = null,
    Object? hasNext = null,
    Object? hasPrevious = null,
  }) {
    return _then(_self.copyWith(
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as List<PhotoListItem>,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      totalElements: null == totalElements
          ? _self.totalElements
          : totalElements // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      hasNext: null == hasNext
          ? _self.hasNext
          : hasNext // ignore: cast_nullable_to_non_nullable
              as bool,
      hasPrevious: null == hasPrevious
          ? _self.hasPrevious
          : hasPrevious // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [PagedPhotosResponse].
extension PagedPhotosResponsePatterns on PagedPhotosResponse {
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
    TResult Function(_PagedPhotosResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PagedPhotosResponse() when $default != null:
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
    TResult Function(_PagedPhotosResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PagedPhotosResponse():
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
    TResult? Function(_PagedPhotosResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PagedPhotosResponse() when $default != null:
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
    TResult Function(List<PhotoListItem> content, int page, int size,
            int totalElements, int totalPages, bool hasNext, bool hasPrevious)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PagedPhotosResponse() when $default != null:
        return $default(
            _that.content,
            _that.page,
            _that.size,
            _that.totalElements,
            _that.totalPages,
            _that.hasNext,
            _that.hasPrevious);
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
    TResult Function(List<PhotoListItem> content, int page, int size,
            int totalElements, int totalPages, bool hasNext, bool hasPrevious)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PagedPhotosResponse():
        return $default(
            _that.content,
            _that.page,
            _that.size,
            _that.totalElements,
            _that.totalPages,
            _that.hasNext,
            _that.hasPrevious);
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
    TResult? Function(List<PhotoListItem> content, int page, int size,
            int totalElements, int totalPages, bool hasNext, bool hasPrevious)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PagedPhotosResponse() when $default != null:
        return $default(
            _that.content,
            _that.page,
            _that.size,
            _that.totalElements,
            _that.totalPages,
            _that.hasNext,
            _that.hasPrevious);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PagedPhotosResponse implements PagedPhotosResponse {
  const _PagedPhotosResponse(
      {final List<PhotoListItem> content = const [],
      this.page = 0,
      this.size = 20,
      this.totalElements = 0,
      this.totalPages = 0,
      this.hasNext = false,
      this.hasPrevious = false})
      : _content = content;
  factory _PagedPhotosResponse.fromJson(Map<String, dynamic> json) =>
      _$PagedPhotosResponseFromJson(json);

  final List<PhotoListItem> _content;
  @override
  @JsonKey()
  List<PhotoListItem> get content {
    if (_content is EqualUnmodifiableListView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_content);
  }

  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final int size;
  @override
  @JsonKey()
  final int totalElements;
  @override
  @JsonKey()
  final int totalPages;
  @override
  @JsonKey()
  final bool hasNext;
  @override
  @JsonKey()
  final bool hasPrevious;

  /// Create a copy of PagedPhotosResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PagedPhotosResponseCopyWith<_PagedPhotosResponse> get copyWith =>
      __$PagedPhotosResponseCopyWithImpl<_PagedPhotosResponse>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PagedPhotosResponseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PagedPhotosResponse &&
            const DeepCollectionEquality().equals(other._content, _content) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.totalElements, totalElements) ||
                other.totalElements == totalElements) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.hasNext, hasNext) || other.hasNext == hasNext) &&
            (identical(other.hasPrevious, hasPrevious) ||
                other.hasPrevious == hasPrevious));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_content),
      page,
      size,
      totalElements,
      totalPages,
      hasNext,
      hasPrevious);

  @override
  String toString() {
    return 'PagedPhotosResponse(content: $content, page: $page, size: $size, totalElements: $totalElements, totalPages: $totalPages, hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }
}

/// @nodoc
abstract mixin class _$PagedPhotosResponseCopyWith<$Res>
    implements $PagedPhotosResponseCopyWith<$Res> {
  factory _$PagedPhotosResponseCopyWith(_PagedPhotosResponse value,
          $Res Function(_PagedPhotosResponse) _then) =
      __$PagedPhotosResponseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<PhotoListItem> content,
      int page,
      int size,
      int totalElements,
      int totalPages,
      bool hasNext,
      bool hasPrevious});
}

/// @nodoc
class __$PagedPhotosResponseCopyWithImpl<$Res>
    implements _$PagedPhotosResponseCopyWith<$Res> {
  __$PagedPhotosResponseCopyWithImpl(this._self, this._then);

  final _PagedPhotosResponse _self;
  final $Res Function(_PagedPhotosResponse) _then;

  /// Create a copy of PagedPhotosResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? content = null,
    Object? page = null,
    Object? size = null,
    Object? totalElements = null,
    Object? totalPages = null,
    Object? hasNext = null,
    Object? hasPrevious = null,
  }) {
    return _then(_PagedPhotosResponse(
      content: null == content
          ? _self._content
          : content // ignore: cast_nullable_to_non_nullable
              as List<PhotoListItem>,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      totalElements: null == totalElements
          ? _self.totalElements
          : totalElements // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      hasNext: null == hasNext
          ? _self.hasNext
          : hasNext // ignore: cast_nullable_to_non_nullable
              as bool,
      hasPrevious: null == hasPrevious
          ? _self.hasPrevious
          : hasPrevious // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
