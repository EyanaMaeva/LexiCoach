import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexicoach/main.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('shows landing page when no saved session exists', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Empowering Every Learner'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
