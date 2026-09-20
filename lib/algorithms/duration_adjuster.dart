import '../models/project.dart';
import '../models/video_clip.dart';

/// Proportionally scales every clip's used duration so the concatenated
/// output does not exceed [ShortMixProject.targetDuration].
///
/// Spec section 18/19: MVP uses a proportional-allocation strategy. If the
/// combined source duration is already within the target, clips are left at
/// full length (no artificial looping to reach the target).
class DurationAdjuster {
  const DurationAdjuster();

  /// Returns a new clip list with [VideoClip.outputDuration] (and matching
  /// [VideoClip.endTime], anchored on [VideoClip.startTime]) adjusted so the
  /// sum of output durations plus transition overlap stays within
  /// [project.targetDuration].
  List<VideoClip> adjust(ShortMixProject project) {
    final clips = project.clips;
    if (clips.isEmpty) return clips;

    final totalSource = project.totalSourceDuration;
    final budget = project.targetDuration - project.totalTransitionDuration;
    if (budget <= 0 || totalSource <= 0) {
      return clips.map((c) => c.copyWith(outputDuration: 0)).toList();
    }

    // Already within budget: keep clips at their full trimmed length.
    if (totalSource <= budget) {
      return clips
          .map((c) => c.copyWith(outputDuration: c.trimmedDuration))
          .toList();
    }

    final scale = budget / totalSource;
    return clips.map((clip) {
      final newDuration = clip.duration * scale;
      return clip.copyWith(outputDuration: newDuration);
    }).toList();
  }
}
