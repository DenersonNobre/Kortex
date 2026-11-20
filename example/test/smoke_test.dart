import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('minimal example: counter increments and saving notifies', (
    tester,
  ) async {
    await tester.pumpWidget(createApp());

    expect(find.text('Clicks: 0'), findsOneWidget);

    await tester.tap(find.byTooltip('increment'));
    await tester.pump();
    expect(find.text('Clicks: 1'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Saved'), findsOneWidget);
  });
}
