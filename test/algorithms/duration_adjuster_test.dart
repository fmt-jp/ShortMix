import 'package:flutter_test/flutter_test.dart';
import 'package:shortmix/algorithms/duration_adjuster.dart';
import 'package:shortmix/models/project.dart';
import 'package:shortmix/models/video_clip.dart';

VideoClip _clip(double duration, int order) => VideoClip(
      id: 'c$order',
      path: 'file:///c$order.mp4',
      fileName: 'c$order.mp4',
      duration: duration,
      order: order,
    );

void main() {
  const adjuster = DurationAdjuster();

  test('scales proportionally when source exceeds target (spec section 18)', () {
    final project = ShortMixProject(
      clips: [_clip(30, 0), _clip(20, 1), _clip(10, 2), _clip(40, 3)],
      targetDuration: 60,
    );

    final adjusted = adjuster.adjust(project);

    expect(adjusted.map((c) => c.outputDuration), [18, 12, 6, 24]);
    expect(adjusted.fold<double>(0, (s, c) => s + c.outputDuration), 60);
  });

  test('keeps full length when under target, no looping (spec section 19)', () {
    final project = ShortMixProject(
      clips: [_clip(20, 0), _clip(25, 1)],
      targetDuration: 60,
    );

    final adjusted = adjuster.adjust(project);

    expect(adjusted.map((c) => c.outputDuration), [20, 25]);
  });
}
