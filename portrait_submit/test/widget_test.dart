import 'package:flutter_test/flutter_test.dart';
import 'package:portrait_submit/main.dart';

void main() {
  testWidgets('Submit screen shows brand and form fields', (tester) async {
    await tester.pumpWidget(const PortraitSubmitApp());
    await tester.pumpAndSettle();

    expect(find.text('Portrait'), findsOneWidget);
    expect(find.text('Овог'), findsOneWidget);
    expect(find.text('Нэр'), findsOneWidget);
    expect(find.text('Илгээх'), findsOneWidget);
    expect(find.text('Цээж зураг оруулах'), findsOneWidget);
  });
}
