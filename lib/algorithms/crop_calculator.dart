/// Computes the crop rectangle used to fit a source video into the
/// project's output aspect ratio.
///
/// MVP (spec section 24): landscape (and any non-matching aspect) sources
/// are center-cropped to fill a 9:16 frame. Kept independent of the video
/// engine so Web/iOS/Android backends and future modes (fit, blurred
/// background, AI auto-crop) can reuse the same math.
class CropRect {
  const CropRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Top-left origin and size of the crop window, in source-pixel units.
  final double x;
  final double y;
  final double width;
  final double height;
}

class CropCalculator {
  const CropCalculator();

  /// Returns the largest center-anchored region of a [sourceWidth] x
  /// [sourceHeight] frame whose aspect ratio matches [outputWidth]:[outputHeight].
  CropRect centerCrop({
    required double sourceWidth,
    required double sourceHeight,
    required int outputWidth,
    required int outputHeight,
  }) {
    final targetRatio = outputWidth / outputHeight;
    final sourceRatio = sourceWidth / sourceHeight;

    double cropWidth = sourceWidth;
    double cropHeight = sourceHeight;

    if (sourceRatio > targetRatio) {
      // Source is relatively wider than the target: crop the sides.
      cropWidth = sourceHeight * targetRatio;
    } else if (sourceRatio < targetRatio) {
      // Source is relatively taller than the target: crop top/bottom.
      cropHeight = sourceWidth / targetRatio;
    }

    final x = (sourceWidth - cropWidth) / 2;
    final y = (sourceHeight - cropHeight) / 2;
    return CropRect(x: x, y: y, width: cropWidth, height: cropHeight);
  }
}
