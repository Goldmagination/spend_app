import 'package:flutter/material.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/goal_service.dart';
import 'add_edit_goal_screen.dart'; // We'll create this next

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final GoalService _goalService = GoalService();
  late List<Goal> _goals;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    setState(() {
      _goals = _goalService.getGoals();
    });
  }

  void _deleteGoal(String id) {
    _goalService.deleteGoal(id);
    _loadGoals(); // Refresh the list
  }

  void _highlightGoal(String id) {
    _goalService.highlightGoal(id);
    _loadGoals(); // Refresh the list to show highlight changes
  }

  void _navigateToAddGoalScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditGoalScreen()),
    );
    if (result == true) {
      _loadGoals(); // Refresh if a goal was added
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel - Goals'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No goals yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap the "+" button to add your first goal.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return Card(
                  elevation: 3.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: goal.isHighlighted
                        ? BorderSide(color: Colors.amber, width: 2.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    title: Text(
                      goal.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: goal.isHighlighted
                            ? Colors.deepPurpleAccent
                            : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5.0),
                        Text(
                          'Target: €${goal.targetAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15.0,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Current: €${goal.currentAmount.toStringAsFixed(0)} (${(goal.currentAmount / (goal.targetAmount > 0 ? goal.targetAmount : 1) * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 15.0,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (goal.paypalEmail != null &&
                            goal.paypalEmail!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'PayPal: ${goal.paypalEmail}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            goal.isHighlighted ? Icons.star : Icons.star_border,
                            color: goal.isHighlighted
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          onPressed: () => _highlightGoal(goal.id),
                          tooltip: goal.isHighlighted
                              ? 'Unhighlight'
                              : 'Highlight',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext ctx) {
                                return AlertDialog(
                                  title: Text('Confirm Delete'),
                                  content: Text(
                                    'Are you sure you want to delete "${goal.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                    TextButton(
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed: () {
                                        _deleteGoal(goal.id);
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddGoalScreen,
        tooltip: 'Add New Goal',
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.add),
      ),
    );
  }
}
