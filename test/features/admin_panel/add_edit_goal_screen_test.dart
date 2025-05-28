import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:money_goal_tracker/src/core/models/goal_model.dart';
import 'package:money_goal_tracker/src/core/services/goal_service.dart';
import 'package:money_goal_tracker/src/features/admin_panel/screens/add_edit_goal_screen.dart';

import 'package:money_goal_tracker/src/core/models/article_model.dart';

// Use the existing mocks from admin_panel_screen_test.dart
import 'admin_panel_screen_test.mocks.dart';

// Helper function to wrap widgets for testing
Widget createTestableAddEditScreen({required Widget child, MockGoalService? mockGoalService}) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  late MockGoalService mockGoalService;
  late GoalService realGoalService; // Use real service for stateful interactions

  setUp(() {
    mockGoalService = MockGoalService();
    realGoalService = GoalService();
    // Clear goals from real service before each test
    var currentGoals = realGoalService.getGoals();
    for (var g in List.from(currentGoals)) {
      realGoalService.deleteGoal(g.id);
    }
  });

  group('AddEditGoalScreen Basic Fields and Validation', () {
    testWidgets('Renders form fields correctly with Euro symbol', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Goal Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Target Amount (€)'), findsOneWidget); // Check for Euro
      expect(find.widgetWithText(TextFormField, 'PayPal Email (Optional)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save New Goal'), findsOneWidget); // Default for add mode
    });

    testWidgets('Entering text updates form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Name'), 'Holiday Fund');
      expect(find.text('Holiday Fund'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (€)'), '1500');
      expect(find.text('1500'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'PayPal Email (Optional)'), 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Validation errors show for empty required fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save New Goal'));
      await tester.pumpAndSettle(); 

      expect(find.text('Please enter a goal name'), findsOneWidget);
      expect(find.text('Please enter a target amount'), findsOneWidget);
    });

    testWidgets('Validation error for invalid target amount', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Name'), 'Valid Name');
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (€)'), 'abc');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save New Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid positive amount'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (€)'), '0');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save New Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid positive amount'), findsOneWidget);
    });
  });

  group('AddEditGoalScreen Article Management', () {
    testWidgets('displays empty articles list and "Add Article" button in add mode', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Articles / Items for this Goal'), findsOneWidget);
      expect(find.text('No articles added yet. Click "Add Article" to start.'), findsOneWidget);
      expect(find.widgetWithIcon(OutlinedButton, Icons.add_shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('tapping "Add Article" shows add article dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.add_shopping_cart_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Add Article'), findsOneWidget); // Dialog title
      expect(find.widgetWithText(TextFormField, 'Article Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Price (€)'), findsOneWidget);
    });

    testWidgets('add article dialog validates and saves new article to UI list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen()));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.add_shopping_cart_outlined));
      await tester.pumpAndSettle();

      // Test validation
      await tester.tap(find.widgetWithText(TextButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter article name'), findsOneWidget);
      expect(find.text('Please enter a price'), findsOneWidget);

      // Enter valid data
      await tester.enterText(find.widgetWithText(TextFormField, 'Article Name'), 'Coffee Mug');
      await tester.enterText(find.widgetWithText(TextFormField, 'Price (€)'), '12.50');
      await tester.tap(find.widgetWithText(TextButton, 'Add'));
      await tester.pumpAndSettle(); // Dialog closes, main screen rebuilds

      // Check if article is in the UI list
      expect(find.text('Coffee Mug'), findsOneWidget);
      expect(find.text('Price: €12.50'), findsOneWidget);
      expect(find.text('No articles added yet. Click "Add Article" to start.'), findsNothing);
    });

    testWidgets('displays articles from goalToEdit in edit mode', (WidgetTester tester) async {
      final existingGoal = Goal(
        id: 'g1', name: 'Edit Goal', targetAmount: 300,
        articles: [Article(id: 'a1', name: 'Book', price: 20)],
      );
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen(goalToEdit: existingGoal)));
      await tester.pumpAndSettle();

      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Price: €20.00'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Update Goal'), findsOneWidget);
    });

    testWidgets('tapping edit on an article shows dialog with pre-filled data', (WidgetTester tester) async {
      final articleToEdit = Article(id: 'a1', name: 'Old Book Name', price: 15);
      final existingGoal = Goal(
        id: 'g1', name: 'Goal With Article', targetAmount: 100,
        articles: [articleToEdit],
      );
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen(goalToEdit: existingGoal)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Article'), findsOneWidget); // Dialog title
      expect(find.widgetWithText(TextFormField, 'Old Book Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '15.00'), findsOneWidget); // Price
    });
    
    testWidgets('editing an article updates it in the UI list', (WidgetTester tester) async {
      final articleToEdit = Article(id: 'a1', name: 'Old Book Name', price: 15);
      final existingGoal = Goal(
        id: 'g1', name: 'Goal With Article', targetAmount: 100,
        articles: [articleToEdit],
      );
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen(goalToEdit: existingGoal)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined)); // Tap edit on the first article
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Old Book Name'), 'New Book Name');
      await tester.enterText(find.widgetWithText(TextFormField, '15.00'), '18.50');
      await tester.tap(find.widgetWithText(TextButton, 'Save')); // Dialog Save
      await tester.pumpAndSettle(); // Close dialog & rebuild screen

      expect(find.text('New Book Name'), findsOneWidget);
      expect(find.text('Price: €18.50'), findsOneWidget);
      expect(find.text('Old Book Name'), findsNothing);
    });

    testWidgets('tapping remove on an article removes it from the UI list', (WidgetTester tester) async {
      final article1 = Article(id: 'a1', name: 'To Remove', price: 10);
      final article2 = Article(id: 'a2', name: 'To Keep', price: 20);
      final existingGoal = Goal(
        id: 'g1', name: 'Goal With Articles', targetAmount: 100,
        articles: [article1, article2],
      );
      await tester.pumpWidget(createTestableAddEditScreen(child: AddEditGoalScreen(goalToEdit: existingGoal)));
      await tester.pumpAndSettle();

      expect(find.text('To Remove'), findsOneWidget);
      // Find the delete icon associated with 'To Remove'. This assumes order or unique properties.
      await tester.tap(find.byTooltip('Remove Article').first); // Tap remove on the first article
      await tester.pumpAndSettle();

      expect(find.text('To Remove'), findsNothing);
      expect(find.text('To Keep'), findsOneWidget);
    });
  });

  group('AddEditGoalScreen Saving Logic', () {
    final mockObserver = MockNavigatorObserver(); // For testing navigation pop

    testWidgets('Tapping "Save New Goal" with valid data (and articles) saves to service and pops route', (WidgetTester tester) async {
      final initialGoalCount = realGoalService.getGoals().length;
      
      await tester.pumpWidget(MaterialApp(home: AddEditGoalScreen(), navigatorObservers: [mockObserver]));
      await tester.pumpAndSettle();
      
      verify(mockObserver.didPush(any, any)).called(1); // Initial push

      // Fill main goal form
      await tester.enterText(find.widgetWithText(TextFormField, 'Goal Name'), 'Goal With Articles');
      await tester.enterText(find.widgetWithText(TextFormField, 'Target Amount (€)'), '100');

      // Add an article
      await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.add_shopping_cart_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Article Name'), 'Saved Article');
      await tester.enterText(find.widgetWithText(TextFormField, 'Price (€)'), '22.50');
      await tester.tap(find.widgetWithText(TextButton, 'Add'));
      await tester.pumpAndSettle();

      // Save Goal
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save New Goal'));
      await tester.pumpAndSettle();

      // Verify goal was added to the real service
      final goals = realGoalService.getGoals();
      expect(goals.length, initialGoalCount + 1);
      final savedGoal = goals.firstWhere((g) => g.name == 'Goal With Articles');
      expect(savedGoal.targetAmount, 100);
      expect(savedGoal.articles.length, 1);
      expect(savedGoal.articles.first.name, 'Saved Article');
      expect(savedGoal.articles.first.price, 22.50);

      // Verify navigation pop
      verify(mockObserver.didPop(any, any)).called(1);
      
      // Cleanup
      realGoalService.deleteGoal(savedGoal.id);
    });

    testWidgets('Tapping "Update Goal" with changes (including articles) saves to service and pops route', (WidgetTester tester) async {
      final article1 = Article(id: 'a1', name: 'Original Article', price: 10);
      final goalToEdit = Goal(
        id: 'edit_g1', name: 'Original Goal Name', targetAmount: 50, 
        articles: [article1]
      );
      realGoalService.addGoal(goalToEdit); // Add to service so it can be "updated"
      
      await tester.pumpWidget(MaterialApp(home: AddEditGoalScreen(goalToEdit: goalToEdit), navigatorObservers: [mockObserver]));
      await tester.pumpAndSettle();
      verify(mockObserver.didPush(any, any)).called(1);

      // Edit main goal form
      await tester.enterText(find.widgetWithText(TextFormField, 'Original Goal Name'), 'Updated Goal Name');
      await tester.enterText(find.widgetWithText(TextFormField, '50.00'), '75.00');

      // Remove original article
      await tester.tap(find.byTooltip('Remove Article').first);
      await tester.pumpAndSettle();

      // Add a new article
      await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.add_shopping_cart_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Article Name'), 'New Article For Update');
      await tester.enterText(find.widgetWithText(TextFormField, 'Price (€)'), '30.00');
      await tester.tap(find.widgetWithText(TextButton, 'Add'));
      await tester.pumpAndSettle();
      
      // Save (Update) Goal
      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Goal'));
      await tester.pumpAndSettle();

      // Verify goal was updated in the real service
      final updatedGoal = realGoalService.getGoalById(goalToEdit.id);
      expect(updatedGoal, isNotNull);
      expect(updatedGoal!.name, 'Updated Goal Name');
      expect(updatedGoal.targetAmount, 75.00);
      expect(updatedGoal.articles.length, 1);
      expect(updatedGoal.articles.first.name, 'New Article For Update');
      expect(updatedGoal.articles.first.price, 30.00);

      // Verify navigation pop
      verify(mockObserver.didPop(any, any)).called(1);

      // Cleanup
      realGoalService.deleteGoal(updatedGoal.id);
    });
  });
}
