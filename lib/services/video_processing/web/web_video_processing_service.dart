import 'dart:async';

import '../../../models/project.dart';
import '../processing_progress.dart';
import '../video_info.dart';
import '../video_processing_service.dart';

/// Web implementation, to be backed by ffmpeg.wasm (`@ffmpeg/ffmpeg`) running
/// inside a Web Worker (spec sections 7/33/34): current stable version
/// `@ffmpeg/ffmpeg@0.12.15` / `@ffmpeg/core@0.12.10`, checked at Phase 3
/// start per spec section 50.
///
/// Not yet implemented — this is wired up in Phase 3 (60秒自動編集の前段:
/// analyze/cut/9:16変換/MP4出力).
VideoProcessingService createVideoProcessingService() =>
    WebVideoProcessingService();

class WebVideoProcessingService implements VideoProcessingService {
  final _progressController = StreamController<ProcessingProgress>.broadcast();

  @override
  Stream<ProcessingProgress> get progress => _progressController.stream;

  @override
  Future<VideoInfo> analyze(String path) {
    throw UnimplementedError(
      'WebVideoProcessingService.analyze: ffmpeg.wasm integration lands in Phase 3.',
    );
  }

  @override
  Future<String> createPreview(ShortMixProject project) {
    throw UnimplementedError(
      'WebVideoProcessingService.createPreview: ffmpeg.wasm integration lands in Phase 3/6.',
    );
  }

  @override
  Future<String> export(ShortMixProject project, String outputPath) {
    throw UnimplementedError(
      'WebVideoProcessingService.export: ffmpeg.wasm integration lands in Phase 3.',
    );
  }

  @override
  Future<void> cancel() async {}
}
