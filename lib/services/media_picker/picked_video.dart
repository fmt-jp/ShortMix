/// Platform-agnostic result of a single video selection, returned by
/// [MediaPickerService]. Screens/widgets never touch `file_picker` types
/// directly, only this.
class PickedVideo {
  const PickedVideo({
    required this.name,
    required this.uri,
    this.path,
  });

  final String name;

  /// Location of the underlying file: a `blob:`/`data:` URI on Web, a
  /// `file:` URI on iOS/Android.
  final Uri uri;

  /// Local filesystem path, when the platform exposes one (iOS/Android).
  /// Always `null` on Web.
  final String? path;
}
