import 'package:flutter_test/flutter_test.dart';

import 'package:shortmix/main.dart';

void main() {
  testWidgets('Home screen shows the video selection entry point', (tester) async {
    await tester.pumpWidget(const ShortMixApp());

    expect(find.text('ShortMix'), findsOneWidget);
    expect(find.text('動画を選択'), findsOneWidget);
  });
}
