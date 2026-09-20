/// Resolves to the right [VideoProcessingService] factory for the current
/// compile target (spec section 41: Flutter common code never imports
/// ffmpeg.wasm / AVFoundation / MediaCodec bindings directly).
library;

export 'unsupported_video_processing_service.dart'
    if (dart.library.io) 'native_video_processing_service.dart'
    if (dart.library.html) 'web/web_video_processing_service.dart'
    show createVideoProcessingService;
