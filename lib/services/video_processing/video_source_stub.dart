import 'package:video_player/video_player.dart';

/// Default branch of [video_source.dart]'s conditional export, used on Web
/// (no `dart:io`): every source is a `blob:`/`data:` URI, playable directly.
VideoPlayerController openVideoController(Uri uri) =>
    VideoPlayerController.networkUrl(uri);
