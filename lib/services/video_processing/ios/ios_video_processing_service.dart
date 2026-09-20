import 'dart:async';

import '../../../models/project.dart';
import '../processing_progress.dart';
import '../video_info.dart';
import '../video_processing_service.dart';

/// iOS implementation, backed by a native video engine (spec section 10).
///
/// `ffmpeg_kit_flutter` was retired by its maintainer in 2025 (last release
/// 2023-09) and must not be adopted here — per spec section 50, the actual
/// engine (AVFoundation via a platform channel, or another currently
/// maintained option) is selected when Phase 7 starts, checking what is
/// maintained at that time rather than assuming this comment stays current.
///
/// Not yet implemented — lands in Phase 7 (iOS動画選択・動画処理・保存).
class IosVideoProcessingService implements VideoProcessingService {
  final _progressController = StreamController<ProcessingProgress>.broadcast();

  @override
  Stream<ProcessingProgress> get progress => _progressController.stream;

  @override
  Future<VideoInfo> analyze(String path) {
    throw UnimplementedError(
      'IosVideoProcessingService.analyze: native engine integration lands in Phase 7.',
    );
  }

  @override
  Future<String> createPreview(ShortMixProject project) {
    throw UnimplementedError(
      'IosVideoProcessingService.createPreview: native engine integration lands in Phase 7.',
    );
  }

  @override
  Future<String> export(ShortMixProject project, String outputPath) {
    throw UnimplementedError(
      'IosVideoProcessingService.export: native engine integration lands in Phase 7.',
    );
  }

  @override
  Future<void> cancel() async {}
}
