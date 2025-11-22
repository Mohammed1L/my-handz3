import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/_SplashPage.dart';
import '../test_helpers.dart';

void main() {
  testWidgets('Start button disabled until language chosen', (tester) async {
    await pumpWithLocalization(tester, const SplashScreen());

    expect(find.text('Start'), findsNothing); // For EN
    expect(find.text('إبدأ'), findsNothing); // For AR

    await tester.tap(find.textContaining('English'));
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
  });
}
