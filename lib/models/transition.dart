/// Transition effects available between two clips in a [ShortMixProject].
///
/// MVP scope per spec section 21: cut, fade, crossfade, slide, zoom.
enum TransitionType {
  cut,
  fade,
  crossfade,
  slide,
  zoom;

  String get label {
    switch (this) {
      case TransitionType.cut:
        return 'カット';
      case TransitionType.fade:
        return 'フェード';
      case TransitionType.crossfade:
        return 'クロスフェード';
      case TransitionType.slide:
        return 'スライド';
      case TransitionType.zoom:
        return 'ズーム';
    }
  }
}

/// A transition applied between two consecutive clips.
class Transition {
  const Transition({
    this.type = TransitionType.cut,
    this.duration = 0.5,
  });

  final TransitionType type;

  /// Duration of the transition, in seconds. Ignored when [type] is
  /// [TransitionType.cut].
  final double duration;

  double get effectiveDuration => type == TransitionType.cut ? 0 : duration;

  Transition copyWith({TransitionType? type, double? duration}) {
    return Transition(
      type: type ?? this.type,
      duration: duration ?? this.duration,
    );
  }
}
