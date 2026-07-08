// This is a basic Flutter widget test for Scan-Go.
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scan_go/main.dart';
import 'package:scan_go/state/loan_session_state.dart';

void main() {
  testWidgets('Scan-Go smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LoanSessionState(),
        child: const ScanGoApp(),
      ),
    );

    // Verify that our app header 'Scan-Go' is found on screen.
    expect(find.text('Scan-Go'), findsOneWidget);
  });
}
