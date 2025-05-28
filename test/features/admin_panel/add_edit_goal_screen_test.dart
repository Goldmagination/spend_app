import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:money_goal_tracker/src/core/models/goal_model.dart';
import 'package:money_goal_tracker/src/core/services/goal_service.dart';
import 'package:money_goal_tracker/src/features/admin_panel/screens/add_edit_goal_screen.dart';

// Use the existing mocks from admin_panel_screen_test.dart
import 'admin_panel_screen_test.mocks.dart';

// Helper function to wrap widgets for testing
Widget createTestableAddEditScreen({required Widget child, MockGoalService? mockGoalService}) {
  // If a mockGoalService is provided, we'd ideally inject it.
  // Since GoalService is a singleton and AddEditGoalScreen instantiates it directly,
  // tests will interact with the real GoalService unless we adapt the app for DI.
  // For this exercise, we'll operate on the real GoalService for some tests,
  // and for testing interactions with GoalService methods (like addGoal),
  // we'd ideally use a mock that the screen can be configured to use.
  return MaterialApp(
    home: child,
  );
}


void main() {
  late MockGoalService mockGoalService; // Used for verifying calls

  setUp(() {
    mockGoalService = MockGoalService();
    // As GoalService is a singleton, AddEditGoalScreen will use the real one.
    // We're setting up a mock instance if we were to verify interactions,
    // but the screen itself won't use this mock instance without DI.
  });

  group('AddEditGoalScreen Widget Tests', () {
    testWidgets('Renders form fields correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Goal Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Target Amount (\$)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'PayPal Email (Optional)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save Goal'), findsOneWidget);
    });

    testWidgets('Entering text updates form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Name'), 'Holiday Fund');
      expect(find.text('Holiday Fund'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (\$)'), '1500');
      expect(find.text('1500'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'PayPal Email (Optional)'), 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Validation errors show for empty required fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Goal'));
      await tester.pumpAndSettle(); // Allow time for validation messages to appear

      expect(find.text('Please enter a goal name'), findsOneWidget);
      expect(find.text('Please enter a target amount'), findsOneWidget);
      // PayPal is optional, so no error for it being empty.
    });

    testWidgets('Validation error for invalid target amount', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Name'), 'Valid Name');
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (\$)'), 'abc');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid positive amount'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (\$)'), '0');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid positive amount'), findsOneWidget);
    });

    testWidgets('Tapping "Save Goal" with valid data calls addGoal and pops route', (WidgetTester tester) async {
      // This test will interact with the *real* GoalService due to the singleton pattern
      // in AddEditGoalScreen. We'll verify by checking the contents of the real GoalService.
      final realGoalService = GoalService();
      final initialGoalCount = realGoalService.getGoals().length;
      
      // Mock navigator
      final mockObserver = MockNavigatorObserver();

      await tester.pumpWidget(
         MaterialApp(
          home: AddEditGoalScreen(),
          navigatorObservers: [mockObserver],
        )
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Name'), 'New Test Goal');
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (\$)'), '250');
      await tester.enterText(find.widgetWithText(TextFormField, 'PayPal Email (Optional)'), 'new_paypal@example.com');
      
      // Stub the navigator's pop method
      verify(mockObserver.didPush(any, any)).called(1); // Initial push

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Goal'));
      await tester.pumpAndSettle(); // Process save and navigation

      // Verify that GoalService's addGoal was called (indirectly, by checking its state)
      final goalsAfterAdd = realGoalService.getGoals();
      expect(goalsAfterAdd.length, initialGoalCount + 1);
      final addedGoal = goalsAfterAdd.firstWhere(
          (g) => g.name == 'New Test Goal' && g.targetAmount == 250,
          orElse: () => throw StateError("Goal not found in service after save") // Provide a default for orElse
      );
      expect(addedGoal.paypalEmail, 'new_paypal@example.com');

      // Verify that Navigator.pop was called
      verify(mockObserver.didPop(any, any)).called(1);
      
      // Clean up the added goal from the real service if necessary for other tests
      realGoalService.deleteGoal(addedGoal.id);
    });
  });
}

// MockNavigatorObserver might be needed if not already in another test file
// class MockNavigatorObserver extends Mock implements NavigatorObserver {}
// It's in admin_panel_screen_test.dart, so it can be used if that file is imported.
// For standalone, it would need to be defined here too.
// Since admin_panel_screen_test.mocks.dart is generated from that, it should be available.
