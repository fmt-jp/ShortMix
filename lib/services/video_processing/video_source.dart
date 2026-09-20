/// Builds a [VideoPlayerController] for a [PickedVideo]/[VideoClip]'s URI,
/// without any screen or widget importing `dart:io` directly (which is
/// unavailable when compiling for Web).
library;

export 'video_source_stub.dart' if (dart.library.io) 'video_source_io.dart'
    show openVideoController;
