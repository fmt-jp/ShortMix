import 'dart:js_interop';
import 'dart:typed_data';

/// Raw `dart:js_interop` bindings for `window.shortMixMediabunny`
/// (`web/mediabunny_bridge.js`).
@JS('shortMixMediabunny.isSupported')
external JSPromise<JSBoolean> _isSupported();

@JS('shortMixMediabunny.setProgressCallback')
external void _setProgressCallback(JSFunction callback);

@JS('shortMixMediabunny.render')
external JSPromise<JSUint8Array> _render(_RenderConfig config);

@JS('shortMixMediabunny.cancel')
external void _cancel();

extension type _RenderConfig._(JSObject _) implements JSObject {
  external factory _RenderConfig({
    JSArray<_ClipConfig> clips,
    JSString transitionType,
    JSNumber transitionDuration,
    JSNumber outputWidth,
    JSNumber outputHeight,
    JSNumber fps,
  });
}

extension type _ClipConfig._(JSObject _) implements JSObject {
  external factory _ClipConfig({
    JSString url,
    JSNumber startTime,
    JSNumber outputDuration,
  });
}

class MediabunnyClip {
  const MediabunnyClip({
    required this.url,
    required this.startTime,
    required this.outputDuration,
  });

  final String url;
  final double startTime;
  final double outputDuration;
}

/// Dart-friendly wrapper around the mediabunny (WebCodecs) render bridge.
///
/// This is the hardware-accelerated rendering path (spec Phase 3 speed
/// follow-up): [isSupported] gates whether it should be used at all, and
/// callers should fall back to [FfmpegClient]-based rendering — the only
/// path that works everywhere — for anything this throws on.
class MediabunnyClient {
  Future<bool> isSupported() async => (await _isSupported().toDart).toDart;

  void onProgress(void Function(double fraction) callback) {
    _setProgressCallback(((JSNumber fraction) => callback(fraction.toDartDouble)).toJS);
  }

  void cancel() => _cancel();

  Future<Uint8List> render({
    required List<MediabunnyClip> clips,
    required String transitionType,
    required double transitionDuration,
    required int outputWidth,
    required int outputHeight,
    required int fps,
  }) async {
    final config = _RenderConfig(
      clips: clips
          .map((c) => _ClipConfig(
                url: c.url.toJS,
                startTime: c.startTime.toJS,
                outputDuration: c.outputDuration.toJS,
              ))
          .toList()
          .toJS,
      transitionType: transitionType.toJS,
      transitionDuration: transitionDuration.toJS,
      outputWidth: outputWidth.toJS,
      outputHeight: outputHeight.toJS,
      fps: fps.toJS,
    );
    final result = await _render(config).toDart;
    return result.toDart;
  }
}
