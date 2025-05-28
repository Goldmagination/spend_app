import 'dart:async';
import 'package:hive/hive.dart';
import '../models/goal_model.dart';
import 'dart:math'; // For random ID generation
import '../models/article_model.dart';

const String goalsBoxName = 'goalsBox';

class GoalService {
  static final GoalService _instance = GoalService._internal();
  static bool _isInitialized = false;
  late Box<Goal> _goalsBox;

  final List<Goal> _goals = []; // In-memory cache of goals
  String? _highlightedGoalId;

  factory GoalService() {
    if (!_isInitialized) {
      // Consider throwing an exception if not initialized,
      // or ensure init() is called and completed in main.dart before any usage.
      print(
          "Warning: GoalService accessed before async initialization is complete. Ensure GoalService.init() is called and awaited in main.dart.");
    }
    return _instance;
  }

  GoalService._internal(); // Private constructor, stays synchronous

  static Future<void> init() async {
    if (_isInitialized) return;
    // Adapters ArticleAdapter and GoalAdapter should be registered in main.dart before this.
    _instance._goalsBox = await Hive.openBox<Goal>(goalsBoxName);
    _instance._loadInitialData();
    _isInitialized = true;
  }

  void _loadInitialData() {
    _goals.clear();
    _goals.addAll(_goalsBox.values.toList());

    if (_goals.isEmpty) {
      String defaultId = _generateId();
      final defaultGoal = Goal(
        id: defaultId,
        name: "Default Project Goal",
        targetAmount: 1000,
        currentAmount: 150,
        isHighlighted: true,
        paypalEmail: "default@example.com",
        articles: [],
      );
      _goals.add(defaultGoal);
      _goalsBox.put(defaultId, defaultGoal); // Persist default goal
      _highlightedGoalId = defaultId;
    } else {
      // Find highlighted goal from loaded data or highlight the first one
      Goal? highlighted =
          _goals.firstWhere((g) => g.isHighlighted, orElse: () => _goals.first);
      if (highlighted != null) {
        _highlightedGoalId = highlighted.id;
        // Ensure only one is highlighted if multiple were somehow saved as highlighted
        if (_goals.where((g) => g.isHighlighted).length > 1) {
          for (var goal in _goals) {
            goal.isHighlighted = (goal.id == _highlightedGoalId);
          }
          // No direct box update needed here as highlightGoal will handle it if called
        }
      } else {
        _highlightedGoalId = null;
      }
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(99999).toString();
  }

  List<Goal> getGoals() {
    // Data is now sourced from _goals, which is populated from Hive at init
    return List.unmodifiable(_goals);
  }

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addGoal(Goal newGoal) async {
    _goals.add(newGoal);
    await _goalsBox.put(newGoal.id, newGoal);
    if (_highlightedGoalId == null && _goals.length == 1) {
      await highlightGoal(newGoal.id); // highlightGoal is now async
    }
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    int index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      await _goalsBox.put(updatedGoal.id, updatedGoal);
    }
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((goal) => goal.id == id);
    await _goalsBox.delete(id);
    if (_highlightedGoalId == id) {
      _highlightedGoalId = null;
      if (_goals.isNotEmpty) {
        await highlightGoal(_goals.first.id); // highlightGoal is now async
      }
    }
  }

  Future<void> highlightGoal(String id) async {
    Goal? goalToHighlight = getGoalById(id);
    if (goalToHighlight == null) return;

    bool needsUpdate = false;
    for (var goal in _goals) {
      bool newHighlightState = (goal.id == id);
      if (goal.isHighlighted != newHighlightState) {
        goal.isHighlighted = newHighlightState;
        await updateGoal(goal); // Persist change for this goal
        needsUpdate = true; // Mark that an update occurred
      }
    }
    _highlightedGoalId = id;
    // If no individual goal's highlight status changed but _highlightedGoalId did,
    // this implies a logic error or that the goal to highlight was already highlighted.
    // No further action needed if only _highlightedGoalId is updated without changing any goal's state.
  }


  Goal? getHighlightedGoal() {
    if (_highlightedGoalId == null) {
      if (_goals.isNotEmpty) {
        // No need to await highlightGoal here as this is a getter.
        // The first goal becomes the implicit highlighted one if no ID is set.
        // Proper highlighting with persistence should be handled by calling `highlightGoal`.
        return _goals.first;
      }
      return null;
    }
    return getGoalById(_highlightedGoalId!);
  }

  Future<void> addMoneyToHighlightedGoal(double amount) async {
    Goal? highlighted = getHighlightedGoal();
    if (highlighted != null && amount > 0) {
      highlighted.currentAmount += amount;
      await updateGoal(highlighted);
    }
  }

  Future<void> resetHighlightedGoalCurrentAmount() async {
    Goal? highlighted = getHighlightedGoal();
    if (highlighted != null) {
      highlighted.currentAmount = 0.0;
      await updateGoal(highlighted);
    }
  }

  Future<void> addArticleToGoal(String goalId, Article article) async {
    Goal? goal = getGoalById(goalId);
    if (goal != null) {
      if (goal.articles.any((a) => a.id == article.id)) {
        print('Article with ID ${article.id} already exists in goal $goalId.');
        return;
      }
      goal.articles.add(article);
      await updateGoal(goal);
    }
  }

  Future<void> removeArticleFromGoal(String goalId, String articleId) async {
    Goal? goal = getGoalById(goalId);
    if (goal != null) {
      goal.articles.removeWhere((article) => article.id == articleId);
      await updateGoal(goal);
    }
  }

  Future<void> updateArticleInGoal(String goalId, Article updatedArticle) async {
    Goal? goal = getGoalById(goalId);
    if (goal != null) {
      int articleIndex = goal.articles.indexWhere(
        (a) => a.id == updatedArticle.id,
      );
      if (articleIndex != -1) {
        goal.articles[articleIndex] = updatedArticle;
        await updateGoal(goal);
      } else {
        print(
          'Article with ID ${updatedArticle.id} not found in goal $goalId for update.',
        );
      }
    }
  }
}
