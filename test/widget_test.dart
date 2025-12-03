// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_scientific_app/main.dart';
import 'package:gym_scientific_app/models/user_model.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_db');
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(TrainingGoalAdapter());
    Hive.registerAdapter(TrainingLocationAdapter());
    Hive.registerAdapter(SomatotypeAdapter());
    Hive.registerAdapter(ExperienceAdapter());
    await Hive.openBox<UserProfile>('userBox');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GymApp());

    // Verify that we are either at Onboarding or Home
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
