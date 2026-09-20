import 'transition.dart';
import 'video_clip.dart';

/// The full editable state of a ShortMix project: clips, transitions between
/// them, and output settings. Shared across every platform target.
class ShortMixProject {
  ShortMixProject({
    List<VideoClip>? clips,
    List<Transition>? transitions,
    this.targetDuration = 60,
    this.aspectRatio = '9:16',
    this.outputWidth = 1080,
    this.outputHeight = 1920,
  })  : clips = clips ?? [],
        transitions = transitions ?? [];

  final List<VideoClip> clips;

  /// Transition applied between clips[i] and clips[i+1].
  /// Always has length `clips.length - 1` (or 0 when there are <2 clips).
  final List<Transition> transitions;

  /// Maximum output duration, in seconds. MVP default: 60.
  final double targetDuration;

  final String aspectRatio;
  final int outputWidth;
  final int outputHeight;

  /// Sum of each clip's original (untrimmed) duration.
  double get totalSourceDuration =>
      clips.fold(0, (sum, clip) => sum + clip.duration);

  /// Sum of the transition time that will be consumed once trimmed clips are
  /// concatenated (crossfade/slide/zoom overlap two clips; cut has none).
  double get totalTransitionDuration =>
      transitions.fold(0, (sum, t) => sum + t.effectiveDuration);

  ShortMixProject copyWith({
    List<VideoClip>? clips,
    List<Transition>? transitions,
    double? targetDuration,
    String? aspectRatio,
    int? outputWidth,
    int? outputHeight,
  }) {
    return ShortMixProject(
      clips: clips ?? this.clips,
      transitions: transitions ?? this.transitions,
      targetDuration: targetDuration ?? this.targetDuration,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      outputWidth: outputWidth ?? this.outputWidth,
      outputHeight: outputHeight ?? this.outputHeight,
    );
  }
}
