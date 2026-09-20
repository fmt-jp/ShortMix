import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../../../models/project.dart';
import '../processing_progress.dart';
import '../video_info.dart';
import '../video_processing_service.dart';
import '../video_source.dart';
import 'ffmpeg_command_builder.dart';
import 'ffmpeg_interop.dart';

/// Web implementation, backed by ffmpeg.wasm (`@ffmpeg/ffmpeg@0.12.15` /
/// `@ffmpeg/core@0.12.10`, self-hosted under `web/ffmpeg/` — see README)
/// running inside its own Web Worker (spec sections 7/33/34).
VideoProcessingService createVideoProcessingService() =>
    WebVideoProcessingService();

class WebVideoProcessingService implements VideoProcessingService {
  WebVideoProcessingService() {
    _ffmpeg.onProgress((fraction, _) {
      _progressController.add(ProcessingProgress(
        stage: ProcessingStage.encoding,
        fraction: fraction.clamp(0, 1),
        message: 'エンコードしています',
      ));
    });
  }

  final _ffmpeg = FfmpegClient();
  final _progressController = StreamController<ProcessingProgress>.broadcast();
  bool _cancelled = false;

  @override
  Stream<ProcessingProgress> get progress => _progressController.stream;

  @override
  Future<VideoInfo> analyze(String path) async {
    final controller = openVideoController(Uri.parse(path));
    try {
      await controller.initialize();
      final value = controller.value;
      return VideoInfo(
        duration: value.duration.inMilliseconds / 1000.0,
        width: value.size.width.round(),
        height: value.size.height.round(),
      );
    } finally {
      await controller.dispose();
    }
  }

  @override
  Future<String> createPreview(ShortMixProject project) async {
    final bytes = await _render(project);
    return _createObjectUrl(bytes);
  }

  @override
  Future<String> export(ShortMixProject project, String outputPath) async {
    final bytes = await _render(project);
    final url = _createObjectUrl(bytes);
    _triggerDownload(url, outputPath);
    return url;
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    _ffmpeg.terminate();
    _progressController.add(const ProcessingProgress(
      stage: ProcessingStage.cancelled,
      fraction: 0,
    ));
  }

  Future<Uint8List> _render(ShortMixProject project) async {
    _cancelled = false;
    _progressController.add(const ProcessingProgress(
      stage: ProcessingStage.analyzing,
      fraction: 0,
      message: '動画を処理しています',
    ));

    await _ffmpeg.load();
    _checkCancelled();

    final inputNames = <String>[];
    for (var i = 0; i < project.clips.length; i++) {
      final clip = project.clips[i];
      final name = 'input$i.mp4';
      final bytes = await _fetchBytes(clip.path);
      _checkCancelled();
      await _ffmpeg.writeFile(name, bytes);
      inputNames.add(name);
    }

    const outputName = 'output.mp4';
    final args = const FfmpegCommandBuilder().build(
      project: project,
      inputFileNames: inputNames,
      outputFileName: outputName,
    );

    _progressController.add(const ProcessingProgress(
      stage: ProcessingStage.encoding,
      fraction: 0,
      message: 'トランジションを適用中...',
    ));
    final ret = await _ffmpeg.exec(args);
    _checkCancelled();
    if (ret != 0) {
      _progressController.add(const ProcessingProgress(
        stage: ProcessingStage.failed,
        fraction: 0,
      ));
      throw Exception(
        '動画を処理できませんでした。この動画は対応していない形式か、ファイルが破損している可能性があります。 (ffmpeg exit code $ret)',
      );
    }

    // ffmpeg's own progress events track encode position, not the muxer's
    // final flush (in particular `-movflags +faststart` rewrites the whole
    // file to move its index to the front) — exec() can keep running well
    // after the last progress tick, so without these the UI would sit at
    // "100%" looking frozen for that entire stretch (spec section 29 wants
    // the user to see *something* moving, not just a percentage).
    _progressController.add(const ProcessingProgress(
      stage: ProcessingStage.encoding,
      fraction: 1,
      message: 'ファイルを書き出しています...',
    ));
    final output = await _ffmpeg.readFile(outputName);

    _progressController.add(const ProcessingProgress(
      stage: ProcessingStage.encoding,
      fraction: 1,
      message: '後片付けをしています...',
    ));
    for (final name in inputNames) {
      await _ffmpeg.deleteFile(name);
    }
    await _ffmpeg.deleteFile(outputName);

    _progressController.add(const ProcessingProgress(
      stage: ProcessingStage.completed,
      fraction: 1,
    ));
    return output;
  }

  void _checkCancelled() {
    if (_cancelled) {
      throw Exception('ユーザーによりキャンセルされました');
    }
  }

  Future<Uint8List> _fetchBytes(String path) async {
    final response = await http.get(Uri.parse(path));
    return response.bodyBytes;
  }

  String _createObjectUrl(Uint8List bytes) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'video/mp4'),
    );
    return web.URL.createObjectURL(blob);
  }

  void _triggerDownload(String url, String fileName) {
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }
}
