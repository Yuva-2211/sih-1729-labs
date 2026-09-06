import 'package:flutter_test/flutter_test.dart';
import 'package:yuva_sih/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeuroVoiceApp());

    // Verify that the title is present
    expect(find.text('NeuroVoice'), findsWidgets);
  });
}
