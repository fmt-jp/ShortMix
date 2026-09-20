import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/video_clip.dart';
import '../services/video_processing/video_source.dart';

/// Shows a paused, muted first-frame preview of [clip].
///
/// True thumbnail image extraction (`video_thumbnail` and similar plugins)
/// has no Web support, so the MVP thumbnail is the video element itself,
/// frozen on its first frame — this already works identically on
/// Web/iOS/Android since it only relies on `video_player`.
class VideoThumbnail extends StatefulWidget {
  const VideoThumbnail({super.key, required this.clip});

  final VideoClip clip;

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final uri = Uri.parse(widget.clip.path);
      final controller = openVideoController(uri);
      await controller.initialize();
      await controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: ColoredBox(
          color: Colors.black12,
          child: controller != null && controller.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              : Center(
                  child: _failed
                      ? const Icon(Icons.broken_image_outlined, size: 20)
                      : const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                ),
        ),
      ),
    );
  }
}
