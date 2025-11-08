// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_label.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoLabel {
  String get labelName;
  double get confidence;
  String get confidenceLevel;

  /// Create a copy of PhotoLabel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PhotoLabelCopyWith<PhotoLabel> get copyWith =>
      _$PhotoLabelCopyWithImpl<PhotoLabel>(this as PhotoLabel, _$identity);

  /// Serializes this PhotoLabel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhotoLabel &&
            (identical(other.labelName, labelName) ||
                other.labelName == labelName) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.confidenceLevel, confidenceLevel) ||
                other.confidenceLevel == confidenceLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, labelName, confidence, confidenceLevel);

  @override
  String toString() {
    return 'PhotoLabel(labelName: $labelName, confidence: $confidence, confidenceLevel: $confidenceLevel)';
  }
}

/// @nodoc
abstract mixin class $PhotoLabelCopyWith<$Res> {
  factory $PhotoLabelCopyWith(
          PhotoLabel value, $Res Function(PhotoLabel) _then) =
      _$PhotoLabelCopyWithImpl;
  @useResult
  $Res call({String labelName, double confidence, String confidenceLevel});
}

/// @nodoc
class _$PhotoLabelCopyWithImpl<$Res> implements $PhotoLabelCopyWith<$Res> {
  _$PhotoLabelCopyWithImpl(this._self, this._then);

  final PhotoLabel _self;
  final $Res Function(PhotoLabel) _then;

  /// Create a copy of PhotoLabel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? labelName = null,
    Object? confidence = null,
    Object? confidenceLevel = null,
  }) {
    return _then(_self.copyWith(
      labelName: null == labelName
          ? _self.labelName
          : labelName // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _self.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      confidenceLevel: null == confidenceLevel
          ? _self.confidenceLevel
          : confidenceLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [PhotoLabel].
extension PhotoLabelPatterns on PhotoLabel {
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
    TResult Function(_PhotoLabel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoLabel() when $default != null:
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
    TResult Function(_PhotoLabel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoLabel():
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
    TResult? Function(_PhotoLabel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoLabel() when $default != null:
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
            String labelName, double confidence, String confidenceLevel)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhotoLabel() when $default != null:
        return $default(
            _that.labelName, _that.confidence, _that.confidenceLevel);
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
            String labelName, double confidence, String confidenceLevel)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoLabel():
        return $default(
            _that.labelName, _that.confidence, _that.confidenceLevel);
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
            String labelName, double confidence, String confidenceLevel)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhotoLabel() when $default != null:
        return $default(
            _that.labelName, _that.confidence, _that.confidenceLevel);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PhotoLabel implements PhotoLabel {
  const _PhotoLabel(
      {required this.labelName,
      required this.confidence,
      required this.confidenceLevel});
  factory _PhotoLabel.fromJson(Map<String, dynamic> json) =>
      _$PhotoLabelFromJson(json);

  @override
  final String labelName;
  @override
  final double confidence;
  @override
  final String confidenceLevel;

  /// Create a copy of PhotoLabel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PhotoLabelCopyWith<_PhotoLabel> get copyWith =>
      __$PhotoLabelCopyWithImpl<_PhotoLabel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PhotoLabelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PhotoLabel &&
            (identical(other.labelName, labelName) ||
                other.labelName == labelName) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.confidenceLevel, confidenceLevel) ||
                other.confidenceLevel == confidenceLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, labelName, confidence, confidenceLevel);

  @override
  String toString() {
    return 'PhotoLabel(labelName: $labelName, confidence: $confidence, confidenceLevel: $confidenceLevel)';
  }
}

/// @nodoc
abstract mixin class _$PhotoLabelCopyWith<$Res>
    implements $PhotoLabelCopyWith<$Res> {
  factory _$PhotoLabelCopyWith(
          _PhotoLabel value, $Res Function(_PhotoLabel) _then) =
      __$PhotoLabelCopyWithImpl;
  @override
  @useResult
  $Res call({String labelName, double confidence, String confidenceLevel});
}

/// @nodoc
class __$PhotoLabelCopyWithImpl<$Res> implements _$PhotoLabelCopyWith<$Res> {
  __$PhotoLabelCopyWithImpl(this._self, this._then);

  final _PhotoLabel _self;
  final $Res Function(_PhotoLabel) _then;

  /// Create a copy of PhotoLabel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? labelName = null,
    Object? confidence = null,
    Object? confidenceLevel = null,
  }) {
    return _then(_PhotoLabel(
      labelName: null == labelName
          ? _self.labelName
          : labelName // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _self.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      confidenceLevel: null == confidenceLevel
          ? _self.confidenceLevel
          : confidenceLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
