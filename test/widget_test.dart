import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ona/main.dart';

void main() {
  testWidgets('renders the Supabase setup screen when unconfigured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: OnaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Supabase is not configured'), findsOneWidget);
  });
}
