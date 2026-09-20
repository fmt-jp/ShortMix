/// Metadata read back from a source video by
/// [VideoProcessingService.analyze].
class VideoInfo {
  const VideoInfo({
    required this.duration,
    required this.width,
    required this.height,
  });

  final double duration;
  final int width;
  final int height;
}
