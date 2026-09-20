import 'package:flutter/material.dart';

import '../services/video_processing/processing_progress.dart';

/// Full-screen processing indicator (spec section 29).
class ProcessingProgressView extends StatelessWidget {
  const ProcessingProgressView({
    super.key,
    required this.progress,
    this.onCancel,
  });

  final ProcessingProgress progress;
  final VoidCallback? onCancel;

  String get _stageLabel {
    switch (progress.stage) {
      case ProcessingStage.analyzing:
        return '動画を解析しています';
      case ProcessingStage.cutting:
        return 'カットしています';
      case ProcessingStage.transition:
        return 'トランジションを適用中...';
      case ProcessingStage.encoding:
        return 'エンコードしています';
      case ProcessingStage.completed:
        return '完了しました';
      case ProcessingStage.failed:
        return '処理に失敗しました';
      case ProcessingStage.cancelled:
        return 'キャンセルしました';
    }
  }

  /// Once the encoder reports 100%, ffmpeg can still be busy for a while
  /// finalizing the file (muxing/`-movflags +faststart` rewrites it to move
  /// the index to the front) without emitting any further progress ticks.
  /// A progress bar frozen at "100%" for that whole stretch reads as stuck,
  /// so once we're this close we switch to an indeterminate (animated) bar
  /// and stop printing a percentage that isn't moving anyway.
  bool get _isFinishingUp =>
      progress.fraction >= 0.99 &&
      progress.stage != ProcessingStage.completed &&
      progress.stage != ProcessingStage.failed &&
      progress.stage != ProcessingStage.cancelled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ShortMix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('動画を処理しています', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _isFinishingUp ? null : progress.fraction.clamp(0, 1),
          ),
          const SizedBox(height: 8),
          if (!_isFinishingUp) Text('${(progress.fraction * 100).round()}%'),
          const SizedBox(height: 8),
          Text(progress.message ?? _stageLabel),
          if (onCancel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onCancel, child: const Text('キャンセル')),
          ],
        ],
      ),
    );
  }
}
