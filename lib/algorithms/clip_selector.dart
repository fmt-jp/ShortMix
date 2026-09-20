import '../models/video_clip.dart';

/// Chooses which portion of each source video to use once its allotted
/// [VideoClip.outputDuration] has been decided.
///
/// MVP (spec section 20): center of the clip. Kept as its own strategy so
/// future modes (start-weighted, silence removal, scene-change, AI
/// highlight extraction) can be swapped in without touching callers.
class ClipSelector {
  const ClipSelector();

  /// Returns a copy of [clip] with [VideoClip.startTime]/[VideoClip.endTime]
  /// set to a centered window of length [clip.outputDuration].
  VideoClip selectWindow(VideoClip clip) {
    final window = clip.outputDuration.clamp(0.0, clip.duration).toDouble();
    final start =
        ((clip.duration - window) / 2).clamp(0.0, clip.duration).toDouble();
    return clip.copyWith(startTime: start, endTime: start + window);
  }
}
