import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../../models/project.dart';
import '../../services/video_processing/platform_video_processing_service.dart';
import '../../services/video_processing/processing_progress.dart';
import '../../services/video_processing/video_processing_service.dart';
import '../../widgets/processing_progress.dart';
import '../../widgets/simple_video_player.dart';
import '../../widgets/video_list.dart' show formatDuration;

enum _Status { idle, processing, ready, error }

/// Spec section 25/26/28: renders the final MP4 (transitions + 9:16 crop,
/// via [VideoProcessingService.export]) and plays it back, then offers
/// save/share. `export()` already triggers the browser download on Web
/// (spec section 27), so there is a single "生成" action rather than a
/// separate lower-cost preview step — [VideoProcessingService.createPreview]
/// stays available for that optimization later without changing this screen.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.project});

  final ShortMixProject project;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final _service = createVideoProcessingService();
  StreamSubscription<ProcessingProgress>? _progressSub;

  _Status _status = _Status.idle;
  ProcessingProgress _lastProgress = const ProcessingProgress(stage: ProcessingStage.analyzing);
  String? _outputUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _status = _Status.processing;
      _errorMessage = null;
    });
    _progressSub = _service.progress.listen((p) {
      if (mounted) setState(() => _lastProgress = p);
    });
    try {
      final url = await _service.export(widget.project, 'shortmix_output.mp4');
      if (!mounted) return;
      setState(() {
        _outputUrl = url;
        _status = _Status.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _errorMessage = '動画を処理できませんでした。この動画は対応していない形式か、ファイルが破損している可能性があります。';
      });
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
    }
  }

  Future<void> _cancel() async {
    await _service.cancel();
  }

  Future<void> _share() async {
    final url = _outputUrl;
    if (url == null) return;
    try {
      final response = await http.get(Uri.parse(url));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(response.bodyBytes, mimeType: 'video/mp4', name: 'shortmix_output.mp4')],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('共有に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プレビュー')),
      body: switch (_status) {
        _Status.idle => _buildIdle(context),
        _Status.processing => Center(
            child: ProcessingProgressView(progress: _lastProgress, onCancel: _cancel),
          ),
        _Status.ready => _buildReady(context),
        _Status.error => _buildError(context),
      },
    );
  }

  Widget _buildIdle(BuildContext context) {
    final total = widget.project.clips.fold<double>(0, (s, c) => s + c.outputDuration) +
        widget.project.totalTransitionDuration;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('合計 ${formatDuration(total)} / 目標 ${widget.project.targetDuration.round()}秒',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...widget.project.clips.asMap().entries.map((entry) {
          final clip = entry.value;
          return ListTile(
            leading: CircleAvatar(child: Text('${entry.key + 1}')),
            title: Text(clip.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${formatDuration(clip.startTime)} - ${formatDuration(clip.endTime)}'
              ' (${formatDuration(clip.outputDuration)})',
            ),
          );
        }),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.movie_creation_outlined),
          label: const Text('動画を作成'),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '処理中はこの画面を開いたままにしてください。',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SimpleVideoPlayer(url: _outputUrl!),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.download_done_outlined),
                label: const Text('保存済み'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.ios_share),
                label: const Text('共有'),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'ブラウザのダウンロードに保存済みです。',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage ?? '動画を処理できませんでした。', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _generate, child: const Text('再試行')),
          ],
        ),
      ),
    );
  }
}
