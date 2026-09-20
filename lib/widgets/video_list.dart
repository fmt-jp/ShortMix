import 'package:flutter/material.dart';

import '../models/video_clip.dart';
import 'video_thumbnail.dart';

String formatDuration(double seconds) {
  final total = seconds.round();
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Vertical, reorderable list of the project's clips (spec sections 14–16):
/// thumbnail, file name, original/used length, drag handle, delete.
///
/// Long-press-to-drag on touch and plain drag-and-drop on desktop/web are
/// both handled by [ReorderableListView] out of the box.
class VideoList extends StatelessWidget {
  const VideoList({
    super.key,
    required this.clips,
    required this.onReorder,
    required this.onDelete,
  });

  final List<VideoClip> clips;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(VideoClip clip) onDelete;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clips.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final clip = clips[index];
        return Card(
          key: ValueKey(clip.id),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: SizedBox(
              width: 48,
              child: VideoThumbnail(clip: clip),
            ),
            title: Text(clip.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '元の長さ ${formatDuration(clip.duration)} ・ 使用 ${formatDuration(clip.outputDuration)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '削除',
                  onPressed: () => onDelete(clip),
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
          ),
        );
      },
    );
  }
}
