// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:filmeals_app/main.dart';
import 'package:filmeals_app/core/services/local_storage_service.dart';
import 'package:filmeals_app/data/repository/user_repository.dart';
import 'package:filmeals_app/data/repository/meal_repository.dart';

void main() {
  testWidgets('App launches and shows Welcome screen', (WidgetTester tester) async {
    // Initialiser les services pour le test
    final storageService = LocalStorageService();
    await storageService.init();

    final userRepository = UserRepository(storageService);
    final mealRepository = MealRepository(storageService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      userRepository: userRepository,
      mealRepository: mealRepository,
    ));

    // Verify that the Welcome screen shows up
    expect(find.text('FitMeals'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });
}
