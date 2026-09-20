import 'dart:js_interop';
import 'dart:typed_data';

/// Raw `dart:js_interop` bindings for `window.shortMixFFmpeg`
/// (`web/ffmpeg_bridge.js`). Kept separate from [WebVideoProcessingService]
/// so the JS-shape details (JSPromise/JSUint8Array/JSFunction conversions)
/// don't leak into the command-building logic.
@JS('shortMixFFmpeg.load')
external JSPromise<JSBoolean> _load();

@JS('shortMixFFmpeg.setProgressCallback')
external void _setProgressCallback(JSFunction callback);

@JS('shortMixFFmpeg.setLogCallback')
external void _setLogCallback(JSFunction callback);

@JS('shortMixFFmpeg.writeFile')
external JSPromise<JSAny?> _writeFile(JSString name, JSUint8Array bytes);

@JS('shortMixFFmpeg.exec')
external JSPromise<JSNumber> _exec(JSArray<JSString> args);

@JS('shortMixFFmpeg.readFile')
external JSPromise<JSUint8Array> _readFile(JSString name);

@JS('shortMixFFmpeg.deleteFile')
external JSPromise<JSAny?> _deleteFile(JSString name);

@JS('shortMixFFmpeg.terminate')
external void _terminate();

typedef FfmpegProgress = void Function(double progress, double timeMicros);
typedef FfmpegLog = void Function(String type, String message);

/// Dart-friendly wrapper around the ffmpeg.wasm bridge.
class FfmpegClient {
  Future<void> load() => _load().toDart;

  void onProgress(FfmpegProgress callback) {
    _setProgressCallback(
      ((JSNumber progress, JSNumber time) {
        callback(progress.toDartDouble, time.toDartDouble);
      }).toJS,
    );
  }

  void onLog(FfmpegLog callback) {
    _setLogCallback(
      ((JSString type, JSString message) {
        callback(type.toDart, message.toDart);
      }).toJS,
    );
  }

  Future<void> writeFile(String name, Uint8List bytes) =>
      _writeFile(name.toJS, bytes.toJS).toDart;

  /// Runs an ffmpeg command line. Returns ffmpeg's exit code (`0` = success).
  Future<int> exec(List<String> args) async {
    final ret = await _exec(args.map((a) => a.toJS).toList().toJS).toDart;
    return ret.toDartInt;
  }

  Future<Uint8List> readFile(String name) async {
    final data = await _readFile(name.toJS).toDart;
    return data.toDart;
  }

  Future<void> deleteFile(String name) async {
    await _deleteFile(name.toJS).toDart;
  }

  /// Kills the underlying Worker outright. There is no cooperative way to
  /// stop a running ffmpeg `exec()` call (it's a synchronous WASM loop on
  /// the worker thread), so cancellation always tears the instance down;
  /// the next call transparently spins up a fresh one.
  void terminate() => _terminate();
}
