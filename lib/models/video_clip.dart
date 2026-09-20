/// A single video source added to a [ShortMixProject].
///
/// [path] is a platform file path on iOS/Android and a Blob object URL
/// (or File handle reference) on Web — resolution of that value is owned by
/// the media picker / video processing services, never by the UI layer.
class VideoClip {
  VideoClip({
    required this.id,
    required this.path,
    required this.fileName,
    required this.duration,
    double? startTime,
    double? endTime,
    double? outputDuration,
    required this.order,
  })  : startTime = startTime ?? 0,
        endTime = endTime ?? duration,
        outputDuration = outputDuration ?? duration;

  final String id;
  final String path;
  final String fileName;

  /// Original duration of the source video, in seconds.
  final double duration;

  /// In/out points (seconds) within the original video that will be used.
  final double startTime;
  final double endTime;

  /// Duration (seconds) this clip will occupy in the final output, after the
  /// 60-second adjustment algorithm has run. Defaults to the full clip.
  final double outputDuration;

  /// Position of this clip within the project's clip list.
  final int order;

  double get trimmedDuration => endTime - startTime;

  VideoClip copyWith({
    String? id,
    String? path,
    String? fileName,
    double? duration,
    double? startTime,
    double? endTime,
    double? outputDuration,
    int? order,
  }) {
    return VideoClip(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      outputDuration: outputDuration ?? this.outputDuration,
      order: order ?? this.order,
    );
  }
}
