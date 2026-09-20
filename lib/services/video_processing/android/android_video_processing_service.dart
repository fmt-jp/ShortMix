import 'dart:async';

import '../../../models/project.dart';
import '../processing_progress.dart';
import '../video_info.dart';
import '../video_processing_service.dart';

/// Android implementation, backed by a native video engine (spec section 10).
///
/// `ffmpeg_kit_flutter` was retired by its maintainer in 2025 (last release
/// 2023-09) and must not be adopted here — per spec section 50, the actual
/// engine (Media3/MediaCodec via a platform channel, or another currently
/// maintained option) is selected when Phase 8 starts, checking what is
/// maintained at that time rather than assuming this comment stays current.
///
/// Not yet implemented — lands in Phase 8 (Android動画選択・動画処理・保存).
class AndroidVideoProcessingService implements VideoProcessingService {
  final _progressController = StreamController<ProcessingProgress>.broadcast();

  @override
  Stream<ProcessingProgress> get progress => _progressController.stream;

  @override
  Future<VideoInfo> analyze(String path) {
    throw UnimplementedError(
      'AndroidVideoProcessingService.analyze: native engine integration lands in Phase 8.',
    );
  }

  @override
  Future<String> createPreview(ShortMixProject project) {
    throw UnimplementedError(
      'AndroidVideoProcessingService.createPreview: native engine integration lands in Phase 8.',
    );
  }

  @override
  Future<String> export(ShortMixProject project, String outputPath) {
    throw UnimplementedError(
      'AndroidVideoProcessingService.export: native engine integration lands in Phase 8.',
    );
  }

  @override
  Future<void> cancel() async {}
}
