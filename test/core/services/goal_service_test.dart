import 'package:flutter_test/flutter_test.dart';
import 'package:money_goal_tracker/src/core/models/goal_model.dart';
import 'package:money_goal_tracker/src/core/services/goal_service.dart';
import 'dart:math'; // For ID generation in tests if needed

void main() {
  group('GoalService Unit Tests', () {
    late GoalService goalService;

    // Helper to create unique IDs for test goals
    String generateTestId() {
      return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(100000).toString();
    }

    setUp(() {
      // Reset GoalService before each test to ensure a clean state.
      // This is tricky with singletons that have internal state initialized at construction.
      // For a truly clean state, the singleton needs a reset method, or we avoid
      // testing the default initial state directly after the first test run without a full app restart.
      // However, for this exercise, we'll re-instantiate it, knowing that the
      // default goal from the constructor will be re-added if the internal list was cleared.
      // A better approach for testability would be dependency injection or a service locator.
      goalService = GoalService(); 
      
      // Clear any existing goals to start fresh for most tests,
      // especially after the first test runs and the default goal is added.
      // This is a workaround for the singleton's persistent state.
      var goals = goalService.getGoals();
      for (var goal in List.from(goals)) { // Iterate on a copy
          goalService.deleteGoal(goal.id);
      }
    });

    test('Initial state has one default goal if constructor logic runs for the first time', () {
      // This test is a bit problematic due to the singleton nature and
      // how the default goal is added in the constructor.
      // After the first test run (or if other tests run before this and instantiate GoalService),
      // the 'default' goal might already be there or removed by setUp.
      // For a truly isolated test of initial state, a reset method on GoalService would be ideal.
      
      // Re-initialize to simulate first time (or ensure setUp clears everything then add one)
      goalService = GoalService(); // This will add the default if _goals was empty.
                                  // If setUp already ran and cleared, this adds it.
      
      // If setUp cleared it, and then GoalService() added the default, we expect 1.
      expect(goalService.getGoals().length, 1);
      final defaultGoal = goalService.getGoals().first;
      expect(defaultGoal.name, "Default Project Goal");
      expect(defaultGoal.isHighlighted, true);
      expect(goalService.getHighlightedGoal()?.id, defaultGoal.id);
    });

    test('Add a new goal', () {
      final goalId = generateTestId();
      final newGoal = Goal(id: goalId, name: 'Test Goal 1', targetAmount: 100);
      goalService.addGoal(newGoal);

      expect(goalService.getGoals().length, 1); // After clearing in setUp
      expect(goalService.getGoalById(goalId), newGoal);
    });

    test('Add multiple goals', () {
      final goal1 = Goal(id: generateTestId(), name: 'Test Goal A', targetAmount: 100);
      final goal2 = Goal(id: generateTestId(), name: 'Test Goal B', targetAmount: 200);
      goalService.addGoal(goal1);
      goalService.addGoal(goal2);

      expect(goalService.getGoals().length, 2);
    });
    
    test('Deleting a goal', () {
      final goalId1 = generateTestId();
      final goal1 = Goal(id: goalId1, name: 'To Delete', targetAmount: 50);
      final goalId2 = generateTestId();
      final goal2 = Goal(id: goalId2, name: 'To Keep', targetAmount: 150);
      
      goalService.addGoal(goal1);
      goalService.addGoal(goal2);
      expect(goalService.getGoals().length, 2);

      goalService.deleteGoal(goalId1);
      expect(goalService.getGoals().length, 1);
      expect(goalService.getGoalById(goalId1), isNull);
      expect(goalService.getGoalById(goalId2), isNotNull);
    });

    test('Highlighting a goal sets it as highlighted and unhighlights others', () {
      final goalId1 = generateTestId();
      final goalId2 = generateTestId();
      final goal1 = Goal(id: goalId1, name: 'Goal One', targetAmount: 100);
      final goal2 = Goal(id: goalId2, name: 'Goal Two', targetAmount: 200);

      goalService.addGoal(goal1);
      goalService.addGoal(goal2);
      
      // Initially, the first goal added might become highlighted by default if no other was.
      // Let's explicitly highlight goal2.
      goalService.highlightGoal(goalId2);
      expect(goalService.getHighlightedGoal()?.id, goalId2);
      expect(goalService.getGoalById(goalId2)?.isHighlighted, isTrue);
      expect(goalService.getGoalById(goalId1)?.isHighlighted, isFalse);

      goalService.highlightGoal(goalId1);
      expect(goalService.getHighlightedGoal()?.id, goalId1);
      expect(goalService.getGoalById(goalId1)?.isHighlighted, isTrue);
      expect(goalService.getGoalById(goalId2)?.isHighlighted, isFalse);
    });

    test('Get highlighted goal', () {
      final goalId1 = generateTestId();
      final goal1 = Goal(id: goalId1, name: 'Highlight Me', targetAmount: 300);
      goalService.addGoal(goal1);
      
      // Test case where the first added goal becomes highlighted by default
      // (assuming setUp cleared previous highlighted goal state from the singleton)
      if (goalService.getGoals().length == 1 && goalService.getHighlightedGoal() == null) {
         goalService.highlightGoal(goalId1); // Explicitly highlight if needed
      }
      
      expect(goalService.getHighlightedGoal(), isNotNull);
      expect(goalService.getHighlightedGoal()?.id, goalId1);

      final goalId2 = generateTestId();
      final goal2 = Goal(id: goalId2, name: 'Highlight Me Instead', targetAmount: 400);
      goalService.addGoal(goal2);
      goalService.highlightGoal(goalId2);
      
      expect(goalService.getHighlightedGoal(), isNotNull);
      expect(goalService.getHighlightedGoal()?.id, goalId2);
    });

    test('Adding money to highlighted goal', () {
      final goalId = generateTestId();
      final goal = Goal(id: goalId, name: 'Funding Goal', targetAmount: 500, currentAmount: 50);
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId);

      goalService.addMoneyToHighlightedGoal(100);
      expect(goalService.getHighlightedGoal()?.currentAmount, 150);

      goalService.addMoneyToHighlightedGoal(0); // Adding 0 should not change
      expect(goalService.getHighlightedGoal()?.currentAmount, 150);
      
      goalService.addMoneyToHighlightedGoal(-50); // Adding negative should not change (or be disallowed)
      expect(goalService.getHighlightedGoal()?.currentAmount, 150); // Assuming service disallows negative adds
    });

    test('Resetting current amount of highlighted goal', () {
      final goalId = generateTestId();
      final goal = Goal(id: goalId, name: 'Reset Test', targetAmount: 1000, currentAmount: 250);
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId);

      goalService.resetHighlightedGoalCurrentAmount();
      expect(goalService.getHighlightedGoal()?.currentAmount, 0);
    });
    
    test('getGoals returns correct list after operations', () {
      final goal1 = Goal(id: generateTestId(), name: 'G1', targetAmount: 10);
      final goal2 = Goal(id: generateTestId(), name: 'G2', targetAmount: 20);
      goalService.addGoal(goal1);
      goalService.addGoal(goal2);
      
      List<Goal> goals = goalService.getGoals();
      expect(goals.length, 2);
      expect(goals.any((g) => g.id == goal1.id), isTrue);
      expect(goals.any((g) => g.id == goal2.id), isTrue);

      goalService.deleteGoal(goal1.id);
      goals = goalService.getGoals();
      expect(goals.length, 1);
      expect(goals.first.id, goal2.id);
    });

    test('Deleting highlighted goal correctly updates highlighted state', () {
      final goalId1 = generateTestId();
      final goal1 = Goal(id: goalId1, name: 'Highlight Then Delete', targetAmount: 100);
      final goalId2 = generateTestId();
      final goal2 = Goal(id: goalId2, name: 'Fallback Highlight', targetAmount: 200);

      goalService.addGoal(goal1);
      goalService.addGoal(goal2);
      
      goalService.highlightGoal(goalId1);
      expect(goalService.getHighlightedGoal()?.id, goalId1);

      goalService.deleteGoal(goalId1);
      expect(goalService.getGoalById(goalId1), isNull);
      // Test if the service automatically highlights another goal (e.g., the first one)
      expect(goalService.getHighlightedGoal()?.id, goalId2); 
      expect(goalService.getGoalById(goalId2)?.isHighlighted, isTrue);
    });

     test('Deleting the only goal clears highlighted goal', () {
      final goalId = generateTestId();
      final goal = Goal(id: goalId, name: 'Only Goal', targetAmount: 100);
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId);

      goalService.deleteGoal(goalId);
      expect(goalService.getGoals().isEmpty, isTrue);
      expect(goalService.getHighlightedGoal(), isNull);
    });

    test('Highlighting a non-existent goal does nothing', () {
      final goalId = generateTestId();
      final goal = Goal(id: goalId, name: 'Existing Goal', targetAmount: 100);
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId); // Highlight existing

      goalService.highlightGoal("nonExistentId123");
      expect(goalService.getHighlightedGoal()?.id, goalId); // Should remain the same
    });
    
    test('Updating a goal reflects changes', () {
        final goalId = generateTestId();
        Goal originalGoal = Goal(id: goalId, name: 'Original Name', targetAmount: 100, currentAmount: 10, paypalEmail: "original@test.com");
        goalService.addGoal(originalGoal);

        Goal updatedGoal = Goal(id: goalId, name: 'Updated Name', targetAmount: 150, currentAmount: 20, paypalEmail: "updated@test.com");
        goalService.updateGoal(updatedGoal);

        Goal? fetchedGoal = goalService.getGoalById(goalId);
        expect(fetchedGoal, isNotNull);
        expect(fetchedGoal!.name, 'Updated Name');
        expect(fetchedGoal.targetAmount, 150);
        expect(fetchedGoal.currentAmount, 20);
        expect(fetchedGoal.paypalEmail, "updated@test.com");
    });

  });
}
