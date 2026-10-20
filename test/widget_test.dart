import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/main.dart';

void main() {
  testWidgets('StudyPlanApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyPlanApp());
    expect(find.text('StudyPlan'), findsWidgets);
  });
}
