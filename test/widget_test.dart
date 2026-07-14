// Simple widget test placeholder
import 'package:flutter_test/flutter_test.dart';
import 'package:drag_map/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CaseEditorApp());
    expect(find.byType(CaseEditorApp), findsOneWidget);
  });
}
