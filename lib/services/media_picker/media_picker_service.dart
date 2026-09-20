import 'package:file_picker/file_picker.dart';

import 'picked_video.dart';

/// Selects video files from the platform's native picker:
/// the browser file dialog on Web, Photo Library on iOS, the Media/Photo
/// Picker on Android. `file_picker` already provides a single cross-platform
/// API for all three, so no per-platform implementation is needed here.
///
/// This does not ask for storage/media permissions itself — the OS pickers
/// underlying `file_picker` (browser `<input>`, iOS `PHPicker`, Android
/// Photo Picker) are designed not to require any (spec section 13: "不要な
/// 権限を要求しない").
class MediaPickerService {
  const MediaPickerService();

  Future<List<PickedVideo>> pickVideos() async {
    final files = await FilePicker.pickFiles(
      type: FileType.video,
    );
    return files
        .map((file) => PickedVideo(
              name: file.name,
              uri: file.uri,
              path: file.path,
            ))
        .toList();
  }
}
