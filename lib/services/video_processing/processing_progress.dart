/// Lifecycle stages of a video processing job (spec section 29).
enum ProcessingStage {
  analyzing,
  cutting,
  transition,
  encoding,
  completed,
  failed,
  cancelled,
}

/// A single progress update emitted on [VideoProcessingService.progress].
class ProcessingProgress {
  const ProcessingProgress({
    required this.stage,
    this.fraction = 0,
    this.message,
  });

  final ProcessingStage stage;

  /// Overall completion, from 0.0 to 1.0.
  final double fraction;

  /// Short user-facing status text (e.g. "トランジションを適用中...").
  final String? message;
}
