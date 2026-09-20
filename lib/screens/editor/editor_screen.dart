import 'package:flutter/material.dart';

import '../../algorithms/clip_selector.dart';
import '../../algorithms/duration_adjuster.dart';
import '../../models/project.dart';
import '../../models/transition.dart';
import '../../models/video_clip.dart';
import '../../widgets/transition_selector.dart';
import '../../widgets/video_list.dart' show formatDuration;
import '../preview/preview_screen.dart';

/// Spec section 17: builds the [ShortMixProject] from the selected clips,
/// lets the user pick a transition, then runs the (pure-Dart, no video
/// engine needed yet) 60-second adjustment algorithm to produce a plan.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.clips});

  final List<VideoClip> clips;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  Transition _transition = const Transition();
  List<VideoClip>? _plan;

  static const _durationAdjuster = DurationAdjuster();
  static const _clipSelector = ClipSelector();

  ShortMixProject get _project => ShortMixProject(
        clips: widget.clips,
        transitions: List.generate(
          widget.clips.length > 1 ? widget.clips.length - 1 : 0,
          (_) => _transition,
        ),
      );

  void _runAutoEdit() {
    final project = _project;
    final adjusted = _durationAdjuster.adjust(project);
    final windowed = adjusted.map(_clipSelector.selectWindow).toList();
    setState(() => _plan = windowed);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final outputTotal = plan == null
        ? null
        : plan.fold<double>(0, (sum, c) => sum + c.outputDuration) +
            (widget.clips.length > 1 ? (widget.clips.length - 1) * _transition.effectiveDuration : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('自動編集')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TransitionSelector(
              transition: _transition,
              onChanged: (t) => setState(() {
                _transition = t;
                _plan = null;
              }),
            ),
          ),
          const Divider(height: 32),
          Text('${widget.clips.length}本の動画・合計 ${formatDuration(_project.totalSourceDuration)}'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _runAutoEdit,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('自動編集'),
          ),
          if (plan != null) ...[
            const SizedBox(height: 16),
            Text(
              '出力予定: ${formatDuration(outputTotal!)} / 60秒',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...plan.map(
              (clip) => ListTile(
                dense: true,
                title: Text(clip.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  '${formatDuration(clip.duration)} → ${formatDuration(clip.outputDuration)}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PreviewScreen(project: _project.copyWith(clips: plan)),
                ),
              ),
              child: const Text('プレビュー'),
            ),
          ],
        ],
      ),
    );
  }
}
