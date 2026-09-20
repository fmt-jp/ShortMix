import '../../models/project.dart';
import 'processing_progress.dart';
import 'video_info.dart';

/// Abstraction over the platform-specific video engine (spec section 11).
///
/// Common Flutter code (screens, widgets, algorithms) never calls
/// ffmpeg.wasm / AVFoundation / MediaCodec directly — it only depends on
/// this interface. Each platform provides its own implementation:
///
/// - Web: `web/web_video_processing_service.dart` (ffmpeg.wasm)
/// - iOS: `ios/ios_video_processing_service.dart` (AVFoundation / native engine)
/// - Android: `android/android_video_processing_service.dart` (Media3 / native engine)
abstract class VideoProcessingService {
  /// Reads duration/resolution for a single source video.
  Future<VideoInfo> analyze(String path);

  /// Renders a low-cost preview of the assembled [project] (may be lower
  /// resolution/bitrate than the final export) and returns a playable
  /// path/URL for it.
  Future<String> createPreview(ShortMixProject project);

  /// Renders the final MP4 for [project] to [outputPath] and returns the
  /// resulting file path/URL.
  Future<String> export(ShortMixProject project, String outputPath);

  /// Aborts the in-flight [createPreview]/[export] call, if any, and cleans
  /// up temporary files. Never touches the original source videos.
  Future<void> cancel();

  Stream<ProcessingProgress> get progress;
}
