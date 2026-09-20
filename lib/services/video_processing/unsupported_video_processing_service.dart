import '../../models/project.dart';
import 'processing_progress.dart';
import 'video_info.dart';
import 'video_processing_service.dart';

/// Selected only on compile targets that are neither Web nor a `dart:io`
/// platform (i.e. never, for Flutter's Web/iOS/Android targets). Exists so
/// the conditional export in `platform_video_processing_service.dart`
/// always has a fallback branch.
VideoProcessingService createVideoProcessingService() =>
    _UnsupportedVideoProcessingService();

class _UnsupportedVideoProcessingService implements VideoProcessingService {
  @override
  Stream<ProcessingProgress> get progress => const Stream.empty();

  @override
  Future<VideoInfo> analyze(String path) =>
      throw UnsupportedError('No VideoProcessingService for this platform.');

  @override
  Future<String> createPreview(ShortMixProject project) =>
      throw UnsupportedError('No VideoProcessingService for this platform.');

  @override
  Future<String> export(ShortMixProject project, String outputPath) =>
      throw UnsupportedError('No VideoProcessingService for this platform.');

  @override
  Future<void> cancel() async {}
}
