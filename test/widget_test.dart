import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/main.dart';

class _TestFirebaseAuthPlatform extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser => null;
}

void main() {
  testWidgets('StudyPlanApp smoke test', (WidgetTester tester) async {
    setupFirebaseCoreMocks();
    FirebaseAuthPlatform.instance = _TestFirebaseAuthPlatform();
    await Firebase.initializeApp();

    await tester.pumpWidget(const StudyPlanApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Masuk ke StudyPlan'), findsOneWidget);
  });
}
