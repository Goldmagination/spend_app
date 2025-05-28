import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:money_goal_tracker/src/core/models/goal_model.dart';
import 'package:money_goal_tracker/src/core/services/goal_service.dart';
import 'package:money_goal_tracker/src/features/admin_panel/screens/admin_panel_screen.dart';
import 'package:money_goal_tracker/src/features/admin_panel/screens/add_edit_goal_screen.dart';

// Generate a MockGoalService using the build_runner
// Command to run: flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([GoalService])
import 'admin_panel_screen_test.mocks.dart'; //This will be generated

// A helper function to wrap widgets for testing
Widget createTestableWidget({required Widget child}) {
  return MaterialApp(
    home: child,
    // Mock navigator observers if testing navigation, or use a mock navigator
    navigatorObservers: [], 
  );
}

void main() {
  // Mocks
  late MockGoalService mockGoalService;

  // Test Goals
  final goal1 = Goal(id: '1', name: 'Goal 1', targetAmount: 100, currentAmount: 50, isHighlighted: true);
  final goal2 = Goal(id: '2', name: 'Goal 2', targetAmount: 200, currentAmount: 75);

  setUp(() {
    mockGoalService = MockGoalService();
    
    // Provide a default behavior for getGoals to avoid null issues if not overridden in a test
    when(mockGoalService.getGoals()).thenReturn([]); 
    // Provide default for getHighlightedGoal as AdminPanelScreen might indirectly cause its call via _loadGoals -> highlight logic.
    when(mockGoalService.getHighlightedGoal()).thenReturn(null); 
  });

  group('AdminPanelScreen Widget Tests', () {
    testWidgets('Renders correctly with a list of mock goals', (WidgetTester tester) async {
      when(mockGoalService.getGoals()).thenReturn([goal1, goal2]);
      when(mockGoalService.getHighlightedGoal()).thenReturn(goal1); // Assume goal1 is highlighted

      // Inject the mock service. This is the tricky part without a proper DI framework.
      // For this test, we assume AdminPanelScreen uses a global/singleton GoalService.
      // The tests for GoalService already test its internal logic.
      // Here, we're testing UI based on what GoalService *would* provide.
      // A common approach is to make the service injectable, e.g., via constructor or InheritedWidget.
      // Since GoalService is a singleton, AdminPanelScreen will use the instance.
      // We need to ensure our mock is the one used. This often means using a library like `get_it`
      // and registering the mock for the test environment.
      // For this test, we'll rely on the fact that GoalService() will be called
      // and we've mocked the methods it calls. This isn't true mocking of the service *instance*
      // but rather mocking the *behavior* that the real service instance would exhibit
      // if its methods were called. This works if AdminPanelScreen calls methods on the *actual*
      // GoalService singleton, and we've stubbed those method calls on our mockGoalService.
      // This is a conceptual simplification for this exercise.
      // A better way is to have GoalService as a parameter to AdminPanelScreen or use get_it.

      // To make this testable, we assume we can somehow make AdminPanelScreen use our mock.
      // The simplest way without refactoring the app for testability is to trust the singleton
      // behavior and simply stub the methods on the mock instance.
      // Let's assume GoalService() in AdminPanelScreen gets our stubbed responses.
      // This is a common pitfall when testing singletons directly.
      
      // The GoalService uses a singleton pattern. The AdminPanelScreen will create its own instance.
      // To test this properly, the GoalService should be injectable.
      // For now, we cannot truly inject the mock into AdminPanelScreen as it's written.
      // The test will interact with the *actual* GoalService.
      // We will clear goals in the actual service and add our test goals.
      
      final realGoalService = GoalService();
      // Clear existing goals from real service
      var currentGoals = realGoalService.getGoals();
      for(var g in List.from(currentGoals)) { realGoalService.deleteGoal(g.id); }
      
      // Add our mock goals to the real service for this test
      realGoalService.addGoal(goal1);
      realGoalService.addGoal(goal2);
      realGoalService.highlightGoal(goal1.id); // ensure goal1 is highlighted

      await tester.pumpWidget(createTestableWidget(child: AdminPanelScreen()));
      await tester.pumpAndSettle(); // Wait for UI to update

      expect(find.text('Goal 1'), findsOneWidget);
      expect(find.text('Goal 2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget); // Highlighted goal1
    });

    testWidgets('Displays empty state message if there are no goals', (WidgetTester tester) async {
      // Ensure the real GoalService is empty for this test
      final realGoalService = GoalService();
      var currentGoals = realGoalService.getGoals();
      for(var g in List.from(currentGoals)) { realGoalService.deleteGoal(g.id); }

      await tester.pumpWidget(createTestableWidget(child: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No goals yet.'), findsOneWidget);
      expect(find.text('Tap the "+" button to add your first goal.'), findsOneWidget);
    });

    testWidgets('Tapping FAB navigates to AddEditGoalScreen', (WidgetTester tester) async {
      // As before, this will use the real GoalService.
      // Navigation testing needs a bit more setup.
      
      // Create a mock navigator observer
      final mockObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPanelScreen(),
          navigatorObservers: [mockObserver],
          // Define a route for AddEditGoalScreen for the navigator to use
          routes: {
            '/addEditGoal': (context) => AddEditGoalScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); // Allow navigation to complete

      // Verify that a push transition happened to AddEditGoalScreen
      // This requires AddEditGoalScreen to be defined or use named routes.
      // For simplicity, we check if AddEditGoalScreen is now present.
      expect(find.byType(AddEditGoalScreen), findsOneWidget);
    });
    
    // The following tests for delete/highlight are challenging without proper DI
    // for GoalService. They would currently operate on the *real* GoalService.
    // To truly test the interaction (i.e., that AdminPanelScreen *calls* the service methods),
    // GoalService needs to be injected and mocked.

    // For the purpose of this exercise, we'll write them as if we *could* mock,
    // acknowledging this limitation in the current app structure.
    // If we run these, they will modify the actual singleton GoalService state.

    testWidgets('Tapping "Delete" calls deleteGoal on GoalService', (WidgetTester tester) async {
      // This test requires GoalService to be truly mockable and injected.
      // We will simulate by checking the side-effect on the real service.
      final realGoalService = GoalService();
      var currentGoals = realGoalService.getGoals();
      for(var g in List.from(currentGoals)) { realGoalService.deleteGoal(g.id); }
      
      final tempGoal = Goal(id: 'temp_del', name: 'Delete Me', targetAmount: 10);
      realGoalService.addGoal(tempGoal);
      
      await tester.pumpWidget(createTestableWidget(child: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsOneWidget);
      // Find the delete icon for 'Delete Me' goal. This can be tricky.
      // Assuming it's the first (and only) goal for simplicity here.
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle(); // For the dialog
      
      // Confirm deletion dialog
      expect(find.text('Confirm Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle(); // For state update after deletion

      // Verify the goal is no longer in the service
      expect(realGoalService.getGoalById('temp_del'), isNull);
      // And no longer in the UI
      expect(find.text('Delete Me'), findsNothing);
    });

    testWidgets('Tapping "Highlight" calls highlightGoal on GoalService', (WidgetTester tester) async {
      // Similar to delete, this tests side-effects on the real service.
      final realGoalService = GoalService();
      var currentGoals = realGoalService.getGoals();
      for(var g in List.from(currentGoals)) { realGoalService.deleteGoal(g.id); }

      final goalToHighlight = Goal(id: 'highlight_me', name: 'Highlight Test', targetAmount: 100, isHighlighted: false);
      final otherGoal = Goal(id: 'other', name: 'Other Goal', targetAmount: 50, isHighlighted: true);
      realGoalService.addGoal(otherGoal); // Add an already highlighted goal
      realGoalService.addGoal(goalToHighlight);
      realGoalService.highlightGoal(otherGoal.id); // Ensure otherGoal is initially highlighted

      await tester.pumpWidget(createTestableWidget(child: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Highlight Test'), findsOneWidget);
      // Find the star_border icon for 'Highlight Test'
      final highlightButtonFinder = find.byWidgetPredicate(
        (Widget widget) => widget is IconButton && widget.tooltip == 'Highlight' && widget.icon is Icon && (widget.icon as Icon).icon == Icons.star_border,
      );
      expect(highlightButtonFinder, findsOneWidget);
      
      await tester.tap(highlightButtonFinder);
      await tester.pumpAndSettle();

      // Verify goalToHighlight is now highlighted in the service
      expect(realGoalService.getHighlightedGoal()?.id, 'highlight_me');
      expect(realGoalService.getGoalById('highlight_me')?.isHighlighted, isTrue);
      expect(realGoalService.getGoalById('other')?.isHighlighted, isFalse);

      // Verify UI update (icon changes to star)
       final highlightedIconFinder = find.byWidgetPredicate(
        (Widget widget) => widget is IconButton && widget.tooltip == 'Unhighlight' && widget.icon is Icon && (widget.icon as Icon).icon == Icons.star,
      );
      // This check needs to be specific to the 'Highlight Test' list tile.
      // For simplicity, if only one star icon is present, it's likely the one.
      expect(highlightedIconFinder, findsOneWidget); 
    });
  });
}

// MockNavigatorObserver for navigation tests
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
