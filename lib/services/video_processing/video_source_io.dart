import 'dart:io';

import 'package:video_player/video_player.dart';

/// `dart:io` branch of [video_source.dart]'s conditional export, used on
/// iOS/Android (and desktop): local files are opened by path, anything else
/// (a remote/preview URL) falls back to network playback.
VideoPlayerController openVideoController(Uri uri) {
  if (uri.scheme == 'file') {
    return VideoPlayerController.file(File.fromUri(uri));
  }
  return VideoPlayerController.networkUrl(uri);
}
