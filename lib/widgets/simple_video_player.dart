import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_list.dart' show formatDuration;

/// Minimal playback UI for the rendered preview (spec section 25):
/// play/pause, seek, current/total time.
class SimpleVideoPlayer extends StatefulWidget {
  const SimpleVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {
        // The file itself is already saved/downloaded by this point (spec
        // section 27) — a playback failure here (e.g. a browser without
        // H.264 support) shouldn't block that, just the in-app preview.
        if (mounted) setState(() => _failed = true);
      })
      ..addListener(() => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: ColoredBox(
          color: Colors.black12,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_outlined, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'このブラウザではプレビューを再生できませんが、\nファイルは保存済みです。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final value = _controller.value;
    final position = value.position;
    final duration = value.duration;

    void togglePlay() =>
        setState(() => value.isPlaying ? _controller.pause() : _controller.play());

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stack gives non-positioned children loose constraints, so
                // VideoPlayer (which has no intrinsic size of its own) would
                // otherwise collapse to zero size — invisible-but-rendered
                // via the platform view's own compositing, yet with no area
                // left for GestureDetector to actually hit-test taps against.
                Positioned.fill(
                  child: GestureDetector(
                    onTap: togglePlay,
                    child: VideoPlayer(_controller),
                  ),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.play_circle_fill,
                      size: 72,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Slider(
          value: position.inMilliseconds
              .clamp(0, duration.inMilliseconds)
              .toDouble(),
          max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
          onChanged: (v) => _controller.seekTo(Duration(milliseconds: v.round())),
        ),
        Text(
          '${formatDuration(position.inMilliseconds / 1000)} / '
          '${formatDuration(duration.inMilliseconds / 1000)}',
        ),
      ],
    );
  }
}
