import 'dart:io' show Platform;

import 'android/android_video_processing_service.dart';
import 'ios/ios_video_processing_service.dart';
import 'video_processing_service.dart';

/// Dispatches to the iOS or Android implementation at runtime. Both compile
/// against `dart:io`, so the Web/native split is resolved at build time via
/// conditional import in `platform_video_processing_service.dart`, while the
/// iOS/Android split — both `dart:io` platforms — is resolved here at
/// runtime via [Platform].
VideoProcessingService createVideoProcessingService() {
  if (Platform.isIOS) return IosVideoProcessingService();
  if (Platform.isAndroid) return AndroidVideoProcessingService();
  throw UnsupportedError(
    'ShortMix targets Web, iOS and Android only (spec section 2).',
  );
}
