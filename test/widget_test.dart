import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:money_goal_tracker/main.dart'; // Assuming MyApp is in main.dart
import 'package:money_goal_tracker/src/app.dart'; // MoneyGoalTracker
import 'package:money_goal_tracker/src/core/models/goal_model.dart';
import 'package:money_goal_tracker/src/core/models/article_model.dart';
import 'package:money_goal_tracker/src/core/services/goal_service.dart';

// Use mocks from admin_panel_screen_test.dart (assuming it's generated)
// If not, you'd need a separate @GenerateMocks for GoalService here.
import 'features/admin_panel/admin_panel_screen_test.mocks.dart';


Widget createTestableMoneyGoalTrackerScreen() {
  // This helper should ideally allow injecting a mock GoalService if DI was used.
  // For now, it relies on the GoalService singleton.
  return MyApp(); // MyApp initializes MoneyGoalTracker
}

void main() {
  late GoalService realGoalService;

  setUp(() {
    // Using the real GoalService for state manipulation in tests,
    // as true DI and mocking of the singleton is not straightforward without app changes.
    realGoalService = GoalService();
    // Clear any goals from previous tests to ensure a predictable state.
    var goals = realGoalService.getGoals();
    for (var goal in List.from(goals)) {
      realGoalService.deleteGoal(goal.id);
    }
    // Add a default goal that can be highlighted for most tests
    final defaultGoal = Goal(
        id: 'default_test_goal',
        name: 'Default Test Goal',
        targetAmount: 1000,
        currentAmount: 100,
        articles: [
          Article(id: 'art1', name: 'Coffee', price: 5),
          Article(id: 'art2', name: 'Book', price: 20),
        ]);
    realGoalService.addGoal(defaultGoal);
    realGoalService.highlightGoal(defaultGoal.id); // Ensure a goal is highlighted
  });

  tearDown(() {
    // Clean up goals after each test
    var goals = realGoalService.getGoals();
    for (var goal in List.from(goals)) {
      realGoalService.deleteGoal(goal.id);
    }
  });

  group('MoneyGoalTracker Widget Tests', () {
    testWidgets('Displays "No Goal Highlighted" when no goal is highlighted', (WidgetTester tester) async {
      // Unhighlight all goals
      final highlighted = realGoalService.getHighlightedGoal();
      if (highlighted != null) {
        // Create a temporary goal to highlight, then delete it, effectively unhighlighting.
        // This is a workaround because GoalService auto-highlights if list is not empty.
        // A direct unhighlightAll() method in GoalService would be better.
        final tempGoal = Goal(id: 'temp_unhighlight', name: 'Temp', targetAmount: 1);
        realGoalService.addGoal(tempGoal);
        realGoalService.highlightGoal(tempGoal.id);
        realGoalService.deleteGoal(tempGoal.id); //This might highlight another, need better unhighlight
      }
      // A more robust way: delete all goals to ensure no goal is highlighted.
      var goals = realGoalService.getGoals();
      for (var goal in List.from(goals)) { realGoalService.deleteGoal(goal.id); }


      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle(); // Allow state to update

      expect(find.text('No Goal Highlighted'), findsOneWidget);
      expect(find.text('Go to Admin Panel to create or highlight a goal.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Open Admin Panel'), findsOneWidget);
    });

    testWidgets('Displays highlighted goal details with Euro symbol', (WidgetTester tester) async {
      // setUp already adds and highlights 'Default Test Goal'
      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle();

      expect(find.text('Default Test Goal'), findsOneWidget); // AppBar title
      expect(find.text('€100'), findsOneWidget); // Current amount
      expect(find.text('of €1000'), findsOneWidget); // Target amount
      expect(find.text('10.0%'), findsOneWidget); // Progress
    });

    testWidgets('"Add Custom Amount" button shows dialog and adds amount', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle();

      // Tap "Add Custom Amount"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Custom Amount'));
      await tester.pumpAndSettle(); // Show dialog

      // Dialog appears
      expect(find.text('Add Custom Amount'), findsNWidgets(2)); // Title of dialog and button
      expect(find.widgetWithText(TextFormField, 'Amount (€)'), findsOneWidget);

      // Enter amount and submit
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount (€)'), '50.50');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle(); // Close dialog and update UI

      // Check updated amount (100 initial + 50.50)
      expect(find.text('€151'), findsOneWidget); // 150.50 rounded to 0 decimal places for display
      expect(realGoalService.getHighlightedGoal()?.currentAmount, 150.50);
    });
    
    testWidgets('"Add Custom Amount" dialog validates input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Custom Amount'));
      await tester.pumpAndSettle();

      // Empty input
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter an amount'), findsOneWidget);

      // Invalid input
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount (€)'), 'abc');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid number'), findsOneWidget);
      
      // Negative input
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount (€)'), '-10');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Amount must be positive'), findsOneWidget);

      // Close dialog
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('"Add from Items" button shows bottom sheet and adds article price', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle();

      // Tap "Add from Items"
      expect(find.widgetWithText(ElevatedButton, 'Add from Items'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add from Items'));
      await tester.pumpAndSettle(); // Show bottom sheet

      // Bottom sheet appears with articles
      expect(find.text('Select an Item to Add'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('€5.00'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('€20.00'), findsOneWidget);

      // Tap an article (e.g., Coffee)
      await tester.tap(find.text('Coffee'));
      await tester.pumpAndSettle(); // Close bottom sheet and update UI

      // Check updated amount (100 initial + 5 for Coffee)
      expect(find.text('€105'), findsOneWidget);
      expect(realGoalService.getHighlightedGoal()?.currentAmount, 105);
    });
    
    testWidgets('"Add from Items" button is disabled if no articles or no goal', (WidgetTester tester) async {
      // Case 1: No articles in the highlighted goal
      realGoalService.updateGoal(realGoalService.getHighlightedGoal()!.copyWith(articles: []));
      
      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle();
      
      final addFromItemsButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Add from Items'));
      expect(addFromItemsButton.onPressed, isNull); // Check if disabled

      // Case 2: No highlighted goal (requires clearing all goals)
      var goals = realGoalService.getGoals();
      for (var goal in List.from(goals)) { realGoalService.deleteGoal(goal.id); }
      
      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle();
      // The button itself might not be found if the whole section is hidden, or it's found but disabled
      // Depending on how the UI is built for "no highlighted goal" state.
      // Current app shows a different UI, so the button won't be there.
      expect(find.widgetWithText(ElevatedButton, 'Add from Items'), findsNothing);
    });

    testWidgets('"Reset Goal" button works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableMoneyGoalTrackerScreen());
      await tester.pumpAndSettle();

      // Initial current amount is €100
      expect(find.text('€100'), findsOneWidget);
      expect(realGoalService.getHighlightedGoal()?.currentAmount, 100);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reset Goal'));
      await tester.pumpAndSettle();

      expect(find.text('€0'), findsOneWidget);
      expect(realGoalService.getHighlightedGoal()?.currentAmount, 0);
    });
  });
}
