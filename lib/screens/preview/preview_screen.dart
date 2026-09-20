import 'package:flutter/material.dart';

import '../../models/project.dart';
import '../../widgets/video_list.dart' show formatDuration;

/// Spec section 25: plays back the assembled result.
///
/// Actual rendering of the merged/transitioned/9:16 output requires a
/// [VideoProcessingService.createPreview] implementation, which is Web
/// ffmpeg.wasm work landing in Phase 3/6. Until then this screen shows the
/// computed plan so the 60-second-adjustment and clip-selection algorithms
/// (already implemented and exercised from [EditorScreen]) are visible and
/// testable end-to-end.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.project});

  final ShortMixProject project;

  @override
  Widget build(BuildContext context) {
    final total = project.clips.fold<double>(0, (s, c) => s + c.outputDuration) +
        project.totalTransitionDuration;

    return Scaffold(
      appBar: AppBar(title: const Text('プレビュー')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '動画の合成プレビュー(MP4書き出し)はまだ実装されていません。\n'
                'ffmpeg.wasm を使った Web 版の書き出しは Phase 3 で実装予定です。\n'
                '以下は自動編集アルゴリズムが計算した構成です。',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('合計 ${formatDuration(total)} / 目標 ${project.targetDuration.round()}秒',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...project.clips.asMap().entries.map((entry) {
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('保存 (Phase 3)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('共有 (Phase 3)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
