import '../models/goal_model.dart';
import 'dart:math'; // For random ID generation

class GoalService {
  // Singleton pattern setup
  static final GoalService _instance = GoalService._internal();
  factory GoalService() {
    return _instance;
  }
  GoalService._internal() {
    // Initialize with a default goal for easier testing
    // In a real app, this would be loaded from persistence or an API
    if (_goals.isEmpty) {
        String defaultId = _generateId();
        _goals.add(Goal(
            id: defaultId,
            name: "Default Project Goal",
            targetAmount: 1000,
            currentAmount: 150,
            isHighlighted: true, // Make the default goal highlighted initially
            paypalEmail: "default@example.com",
            articles: [] // Explicitly empty for the default goal
        ));
        _highlightedGoalId = defaultId;
    }
  }

  final List<Goal> _goals = [];
  String? _highlightedGoalId;

  String _generateId() {
    // Simple random ID generator for this example
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(99999).toString();
  }

  List<Goal> getGoals() {
    return List.unmodifiable(_goals); // Return a copy to prevent external modification
  }

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null; // Not found
    }
  }

  void addGoal(Goal newGoal) {
    // Ensure the new goal has a unique ID if not already set (though constructor requires it)
    // For simplicity, we assume newGoal comes with a valid, unique ID or we could generate one here
    // if the Goal model allowed for ID to be null initially.
    _goals.add(newGoal);
    // If no goal is currently highlighted, and this is the first goal, highlight it.
    if (_highlightedGoalId == null && _goals.length == 1) {
      highlightGoal(newGoal.id);
    }
  }

  void updateGoal(Goal updatedGoal) {
    int index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      _goals[index] = updatedGoal;
    }
  }

  void deleteGoal(String id) {
    _goals.removeWhere((goal) => goal.id == id);
    if (_highlightedGoalId == id) {
      _highlightedGoalId = null;
      // Optionally, highlight another goal if one exists
      if (_goals.isNotEmpty) {
        highlightGoal(_goals.first.id);
      }
    }
  }

  void highlightGoal(String id) {
    Goal? goalToHighlight = getGoalById(id);
    if (goalToHighlight == null) return; // Goal not found

    for (var goal in _goals) {
      goal.isHighlighted = (goal.id == id);
    }
    _highlightedGoalId = id;
  }

  Goal? getHighlightedGoal() {
    if (_highlightedGoalId == null) {
      // If no specific goal is highlighted, but there are goals,
      // we can default to highlighting the first one.
      // This ensures there's usually a highlighted goal if any goals exist.
      if (_goals.isNotEmpty && _highlightedGoalId == null) {
          highlightGoal(_goals.first.id);
          return _goals.first;
      }
      return null;
    }
    return getGoalById(_highlightedGoalId!);
  }

  // Specific methods for modifying the highlighted goal's amounts
  void addMoneyToHighlightedGoal(double amount) {
    Goal? highlighted = getHighlightedGoal();
    if (highlighted != null && amount > 0) {
      highlighted.currentAmount += amount;
      if (highlighted.currentAmount > highlighted.targetAmount) {
        // Optionally cap at targetAmount, or allow exceeding.
        // For now, let's allow exceeding.
      }
      updateGoal(highlighted); // Persist change within the list
    }
  }

  void resetHighlightedGoalCurrentAmount() {
    Goal? highlighted = getHighlightedGoal();
    if (highlighted != null) {
      highlighted.currentAmount = 0.0;
      updateGoal(highlighted); // Persist change
    }
  }

  // Methods for managing articles within a specific goal
  void addArticleToGoal(String goalId, Article article) {
    Goal? goal = getGoalById(goalId);
    if (goal != null) {
      // Ensure no duplicate article IDs if that's a constraint
      if (goal.articles.any((a) => a.id == article.id)) {
        print('Article with ID ${article.id} already exists in goal $goalId.');
        return;
      }
      goal.articles.add(article);
      updateGoal(goal); // Save changes to the goal
    }
  }

  void removeArticleFromGoal(String goalId, String articleId) {
    Goal? goal = getGoalById(goalId);
    if (goal != null) {
      goal.articles.removeWhere((article) => article.id == articleId);
      updateGoal(goal);
    }
  }

  void updateArticleInGoal(String goalId, Article updatedArticle) {
    Goal? goal = getGoalById(goalId);
    if (goal != null) {
      int articleIndex = goal.articles.indexWhere((a) => a.id == updatedArticle.id);
      if (articleIndex != -1) {
        goal.articles[articleIndex] = updatedArticle;
        updateGoal(goal);
      } else {
        print('Article with ID ${updatedArticle.id} not found in goal $goalId for update.');
      }
    }
  }
}

// Import Article model for the new methods
import '../models/article_model.dart';
