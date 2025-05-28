import 'package:flutter_test/flutter_test.dart';
import 'package:spend_app/src/core/models/goal_model.dart';
import 'package:spend_app/src/core/services/goal_service.dart';
import 'dart:math'; // For ID generation in tests if needed
// Import Article model for tests involving articles
import 'package:spend_app/src/core/models/article_model.dart';

void main() {
  group('GoalService Unit Tests', () {
    late GoalService goalService;

    // Helper to create unique IDs for test goals
    String generateTestId() {
      return DateTime.now().millisecondsSinceEpoch.toString() +
          Random().nextInt(100000).toString();
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
      for (var goal in List.from(goals)) {
        // Iterate on a copy
        goalService.deleteGoal(goal.id);
      }
    });

    test(
      'Initial state has one default goal if constructor logic runs for the first time',
      () {
        // This test is a bit problematic due to the singleton nature and
        // how the default goal is added in the constructor.
        // After the first test run (or if other tests run before this and instantiate GoalService),
        // the 'default' goal might already be there or removed by setUp.
        // For a truly isolated test of initial state, a reset method on GoalService would be ideal.

        // Re-initialize to simulate first time (or ensure setUp clears everything then add one)
        goalService =
            GoalService(); // This will add the default if _goals was empty.
        // If setUp already ran and cleared, this adds it.

        // If setUp cleared it, and then GoalService() added the default, we expect 1.
        expect(goalService.getGoals().length, 1);
        final defaultGoal = goalService.getGoals().first;
        expect(defaultGoal.name, "Default Project Goal");
        expect(defaultGoal.isHighlighted, true);
        expect(
          defaultGoal.articles,
          isEmpty,
        ); // Check articles for default goal
        expect(goalService.getHighlightedGoal()?.id, defaultGoal.id);
      },
    );

    test('Add a new goal', () {
      final goalId = generateTestId();
      final newGoal = Goal(
        id: goalId,
        name: 'Test Goal 1',
        targetAmount: 100,
        articles: [],
      );
      goalService.addGoal(newGoal);

      expect(goalService.getGoals().length, 1); // After clearing in setUp
      expect(goalService.getGoalById(goalId), newGoal);
      expect(goalService.getGoalById(goalId)?.articles, isEmpty);
    });

    test('Add multiple goals', () {
      final goal1 = Goal(
        id: generateTestId(),
        name: 'Test Goal A',
        targetAmount: 100,
        articles: [],
      );
      final goal2 = Goal(
        id: generateTestId(),
        name: 'Test Goal B',
        targetAmount: 200,
        articles: [],
      );
      goalService.addGoal(goal1);
      goalService.addGoal(goal2);

      expect(goalService.getGoals().length, 2);
    });

    test('Deleting a goal', () {
      final goalId1 = generateTestId();
      final goal1 = Goal(
        id: goalId1,
        name: 'To Delete',
        targetAmount: 50,
        articles: [],
      );
      final goalId2 = generateTestId();
      final goal2 = Goal(
        id: goalId2,
        name: 'To Keep',
        targetAmount: 150,
        articles: [],
      );

      goalService.addGoal(goal1);
      goalService.addGoal(goal2);
      expect(goalService.getGoals().length, 2);

      goalService.deleteGoal(goalId1);
      expect(goalService.getGoals().length, 1);
      expect(goalService.getGoalById(goalId1), isNull);
      expect(goalService.getGoalById(goalId2), isNotNull);
    });

    test(
      'Highlighting a goal sets it as highlighted and unhighlights others',
      () {
        final goalId1 = generateTestId();
        final goalId2 = generateTestId();
        final goal1 = Goal(
          id: goalId1,
          name: 'Goal One',
          targetAmount: 100,
          articles: [],
        );
        final goal2 = Goal(
          id: goalId2,
          name: 'Goal Two',
          targetAmount: 200,
          articles: [],
        );

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
      },
    );

    test('Get highlighted goal', () {
      final goalId1 = generateTestId();
      final goal1 = Goal(
        id: goalId1,
        name: 'Highlight Me',
        targetAmount: 300,
        articles: [],
      );
      goalService.addGoal(goal1);

      if (goalService.getGoals().length == 1 &&
          goalService.getHighlightedGoal() == null) {
        goalService.highlightGoal(goalId1);
      }

      expect(goalService.getHighlightedGoal(), isNotNull);
      expect(goalService.getHighlightedGoal()?.id, goalId1);

      final goalId2 = generateTestId();
      final goal2 = Goal(
        id: goalId2,
        name: 'Highlight Me Instead',
        targetAmount: 400,
        articles: [],
      );
      goalService.addGoal(goal2);
      goalService.highlightGoal(goalId2);

      expect(goalService.getHighlightedGoal(), isNotNull);
      expect(goalService.getHighlightedGoal()?.id, goalId2);
    });

    test('Adding money to highlighted goal', () {
      final goalId = generateTestId();
      final goal = Goal(
        id: goalId,
        name: 'Funding Goal',
        targetAmount: 500,
        currentAmount: 50,
        articles: [],
      );
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId);

      goalService.addMoneyToHighlightedGoal(100);
      expect(goalService.getHighlightedGoal()?.currentAmount, 150);

      goalService.addMoneyToHighlightedGoal(0);
      expect(goalService.getHighlightedGoal()?.currentAmount, 150);

      goalService.addMoneyToHighlightedGoal(-50);
      expect(goalService.getHighlightedGoal()?.currentAmount, 150);
    });

    test('Resetting current amount of highlighted goal', () {
      final goalId = generateTestId();
      final goal = Goal(
        id: goalId,
        name: 'Reset Test',
        targetAmount: 1000,
        currentAmount: 250,
        articles: [],
      );
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId);

      goalService.resetHighlightedGoalCurrentAmount();
      expect(goalService.getHighlightedGoal()?.currentAmount, 0);
    });

    test('getGoals returns correct list after operations', () {
      final goal1 = Goal(
        id: generateTestId(),
        name: 'G1',
        targetAmount: 10,
        articles: [],
      );
      final goal2 = Goal(
        id: generateTestId(),
        name: 'G2',
        targetAmount: 20,
        articles: [],
      );
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
      final goal1 = Goal(
        id: goalId1,
        name: 'Highlight Then Delete',
        targetAmount: 100,
        articles: [],
      );
      final goalId2 = generateTestId();
      final goal2 = Goal(
        id: goalId2,
        name: 'Fallback Highlight',
        targetAmount: 200,
        articles: [],
      );

      goalService.addGoal(goal1);
      goalService.addGoal(goal2);

      goalService.highlightGoal(goalId1);
      expect(goalService.getHighlightedGoal()?.id, goalId1);

      goalService.deleteGoal(goalId1);
      expect(goalService.getGoalById(goalId1), isNull);
      expect(goalService.getHighlightedGoal()?.id, goalId2);
      expect(goalService.getGoalById(goalId2)?.isHighlighted, isTrue);
    });

    test('Deleting the only goal clears highlighted goal', () {
      final goalId = generateTestId();
      final goal = Goal(
        id: goalId,
        name: 'Only Goal',
        targetAmount: 100,
        articles: [],
      );
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId);

      goalService.deleteGoal(goalId);
      expect(goalService.getGoals().isEmpty, isTrue);
      expect(goalService.getHighlightedGoal(), isNull);
    });

    test('Highlighting a non-existent goal does nothing', () {
      final goalId = generateTestId();
      final goal = Goal(
        id: goalId,
        name: 'Existing Goal',
        targetAmount: 100,
        articles: [],
      );
      goalService.addGoal(goal);
      goalService.highlightGoal(goalId);

      goalService.highlightGoal("nonExistentId123");
      expect(goalService.getHighlightedGoal()?.id, goalId);
    });

    test('Updating a goal reflects changes including articles', () {
      final goalId = generateTestId();
      final article1 = Article(id: 'a1', name: 'Article 1', price: 10);
      Goal originalGoal = Goal(
        id: goalId,
        name: 'Original Name',
        targetAmount: 100,
        currentAmount: 10,
        paypalEmail: "original@test.com",
        articles: [article1],
      );
      goalService.addGoal(originalGoal);

      final article2 = Article(id: 'a2', name: 'Article 2', price: 20);
      Goal updatedGoal = Goal(
        id: goalId,
        name: 'Updated Name',
        targetAmount: 150,
        currentAmount: 20,
        paypalEmail: "updated@test.com",
        articles: [article1, article2],
      );
      goalService.updateGoal(updatedGoal);

      Goal? fetchedGoal = goalService.getGoalById(goalId);
      expect(fetchedGoal, isNotNull);
      expect(fetchedGoal!.name, 'Updated Name');
      expect(fetchedGoal.targetAmount, 150);
      expect(fetchedGoal.currentAmount, 20);
      expect(fetchedGoal.paypalEmail, "updated@test.com");
      expect(fetchedGoal.articles.length, 2);
      expect(fetchedGoal.articles.any((a) => a.id == 'a2'), isTrue);
    });

    // New tests for article-specific methods
    group('Article Management in GoalService', () {
      late Goal testGoal;
      late String testGoalId;

      setUp(() {
        testGoalId = generateTestId();
        testGoal = Goal(
          id: testGoalId,
          name: 'Goal for Articles',
          targetAmount: 500,
          articles: [],
        );
        goalService.addGoal(testGoal);
      });

      test('should add an article to a specific goal', () {
        final article = Article(id: 'art1', name: 'Test Article', price: 25);
        goalService.addArticleToGoal(testGoalId, article);

        final goal = goalService.getGoalById(testGoalId);
        expect(goal?.articles.length, 1);
        expect(goal?.articles.first.id, 'art1');
      });

      test(
        'should not add an article with a duplicate ID to the same goal',
        () {
          final article1 = Article(
            id: 'artDup',
            name: 'Article Original',
            price: 30,
          );
          final article2 = Article(
            id: 'artDup',
            name: 'Article Duplicate',
            price: 35,
          );
          goalService.addArticleToGoal(testGoalId, article1);
          goalService.addArticleToGoal(
            testGoalId,
            article2,
          ); // Attempt to add duplicate

          final goal = goalService.getGoalById(testGoalId);
          expect(goal?.articles.length, 1); // Should only contain the first one
          expect(goal?.articles.first.name, 'Article Original');
        },
      );

      test('should remove an article from a specific goal', () {
        final article1 = Article(
          id: 'artR1',
          name: 'Article To Remove',
          price: 10,
        );
        final article2 = Article(
          id: 'artR2',
          name: 'Article To Keep',
          price: 20,
        );
        goalService.addArticleToGoal(testGoalId, article1);
        goalService.addArticleToGoal(testGoalId, article2);

        goalService.removeArticleFromGoal(testGoalId, 'artR1');
        final goal = goalService.getGoalById(testGoalId);
        expect(goal?.articles.length, 1);
        expect(goal?.articles.first.id, 'artR2');
      });

      test('should update an article within a specific goal', () {
        final article = Article(id: 'artU1', name: 'Initial Name', price: 50);
        goalService.addArticleToGoal(testGoalId, article);

        final updatedArticle = Article(
          id: 'artU1',
          name: 'Updated Name',
          price: 55,
        );
        goalService.updateArticleInGoal(testGoalId, updatedArticle);

        final goal = goalService.getGoalById(testGoalId);
        expect(goal?.articles.length, 1);
        expect(goal?.articles.first.name, 'Updated Name');
        expect(goal?.articles.first.price, 55);
      });

      test(
        'should not affect other goals when modifying articles for one goal',
        () {
          final otherGoalId = generateTestId();
          final otherGoalArticle = Article(
            id: 'otherArt',
            name: 'Other Goal Article',
            price: 100,
          );
          final otherGoal = Goal(
            id: otherGoalId,
            name: 'Another Goal',
            targetAmount: 1000,
            articles: [otherGoalArticle],
          );
          goalService.addGoal(otherGoal);

          final articleForTestGoal = Article(
            id: 'artForTest',
            name: 'Article for Main Test Goal',
            price: 10,
          );
          goalService.addArticleToGoal(testGoalId, articleForTestGoal);

          final goal1 = goalService.getGoalById(testGoalId);
          final goal2 = goalService.getGoalById(otherGoalId);
          expect(goal1?.articles.length, 1);
          expect(goal2?.articles.length, 1);
          expect(goal2?.articles.first.id, 'otherArt');
        },
      );

      test(
        'should handle trying to remove/update a non-existent article gracefully',
        () {
          final article = Article(
            id: 'artE1',
            name: 'Existing Article',
            price: 10,
          );
          goalService.addArticleToGoal(testGoalId, article);

          goalService.removeArticleFromGoal(
            testGoalId,
            'nonExistentArtId',
          ); // Try removing non-existent
          final goalAfterRemove = goalService.getGoalById(testGoalId);
          expect(
            goalAfterRemove?.articles.length,
            1,
          ); // Should not have changed

          final nonExistentUpdateArticle = Article(
            id: 'nonExistentArtId',
            name: 'Wont Update',
            price: 1,
          );
          goalService.updateArticleInGoal(
            testGoalId,
            nonExistentUpdateArticle,
          ); // Try updating non-existent
          final goalAfterUpdate = goalService.getGoalById(testGoalId);
          expect(
            goalAfterUpdate?.articles.first.name,
            'Existing Article',
          ); // Should not have changed
        },
      );
    });
  });
}
