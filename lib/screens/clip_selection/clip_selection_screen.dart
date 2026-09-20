import 'package:flutter/material.dart';

import '../../models/video_clip.dart';
import '../../services/media_picker/media_picker_service.dart';
import '../../services/video_processing/video_source.dart';
import '../../widgets/video_list.dart';
import '../editor/editor_screen.dart';

/// Spec sections 13–16: pick videos, list them, reorder, delete.
class ClipSelectionScreen extends StatefulWidget {
  const ClipSelectionScreen({super.key});

  @override
  State<ClipSelectionScreen> createState() => _ClipSelectionScreenState();
}

class _ClipSelectionScreenState extends State<ClipSelectionScreen> {
  final _picker = const MediaPickerService();
  final List<VideoClip> _clips = [];
  int _nextId = 0;
  bool _loading = false;
  String? _error;

  Future<void> _pickVideos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final picked = await _picker.pickVideos();
      for (final video in picked) {
        final controller = openVideoController(video.uri);
        try {
          await controller.initialize();
          final duration = controller.value.duration.inMilliseconds / 1000.0;
          if (!mounted) return;
          setState(() {
            _clips.add(VideoClip(
              id: 'clip_${_nextId++}',
              path: video.uri.toString(),
              fileName: video.name,
              duration: duration,
              order: _clips.length,
            ));
          });
        } finally {
          await controller.dispose();
        }
      }
    } catch (e) {
      setState(() {
        _error = '動画を読み込めませんでした。対応していない形式か、ファイルが破損している可能性があります。';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final clip = _clips.removeAt(oldIndex);
      _clips.insert(newIndex, clip);
      for (var i = 0; i < _clips.length; i++) {
        _clips[i] = _clips[i].copyWith(order: i);
      }
    });
  }

  void _onDelete(VideoClip clip) {
    setState(() => _clips.remove(clip));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('動画を選択')),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _clips.isEmpty && !_loading
                ? const Center(child: Text('右下のボタンから動画を追加してください'))
                : ListView(
                    children: [
                      VideoList(
                        clips: _clips,
                        onReorder: _onReorder,
                        onDelete: _onDelete,
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _pickVideos,
                      icon: const Icon(Icons.add),
                      label: const Text('動画を追加'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _clips.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditorScreen(clips: List.of(_clips)),
                                ),
                              ),
                      child: const Text('次へ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
