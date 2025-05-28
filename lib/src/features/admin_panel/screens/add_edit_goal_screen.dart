import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import '../../../core/models/goal_model.dart';
import '../../../core/services/goal_service.dart';
import 'dart:math'; // For random ID
import '../../../core/models/article_model.dart'; // Import Article model

class AddEditGoalScreen extends StatefulWidget {
  final Goal? goalToEdit;

  const AddEditGoalScreen({super.key, this.goalToEdit});

  @override
  _AddEditGoalScreenState createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final GoalService _goalService = GoalService();

  String _name = '';
  double _targetAmount = 0.0;
  String _paypalEmail = '';
  List<Article> _articles = []; // State for managing articles

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _name = widget.goalToEdit!.name;
      _targetAmount = widget.goalToEdit!.targetAmount;
      _paypalEmail = widget.goalToEdit!.paypalEmail ?? '';
      _articles = List<Article>.from(
        widget.goalToEdit!.articles,
      ); // Initialize articles
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (widget.goalToEdit != null) {
        // Update existing goal
        final updatedGoal = widget.goalToEdit!.copyWith(
          name: _name,
          targetAmount: _targetAmount,
          paypalEmail: _paypalEmail.isNotEmpty ? _paypalEmail : null,
          articles: _articles,
        );
        _goalService.updateGoal(updatedGoal);
      } else {
        // Add new goal
        String id =
            DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(99999).toString();
        final newGoal = Goal(
          id: id,
          name: _name,
          targetAmount: _targetAmount,
          paypalEmail: _paypalEmail.isNotEmpty ? _paypalEmail : null,
          articles: _articles,
        );
        _goalService.addGoal(newGoal);
      }

      Navigator.pop(
        context,
        true,
      ); // Return true to indicate a goal was added/changed
    }
  }

  void _addOrEditArticleDialog({Article? articleToEdit, int? articleIndex}) {
    final articleFormKey = GlobalKey<FormState>();
    String articleName = articleToEdit?.name ?? '';
    double articlePrice = articleToEdit?.price ?? 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(articleToEdit == null ? 'Add Article' : 'Edit Article'),
          content: Form(
            key: articleFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  initialValue: articleName,
                  decoration: InputDecoration(labelText: 'Article Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter article name';
                    }
                    return null;
                  },
                  onSaved: (value) => articleName = value!,
                ),
                TextFormField(
                  initialValue: articlePrice.toStringAsFixed(2),
                  decoration: InputDecoration(labelText: 'Price (€)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid positive price';
                    }
                    return null;
                  },
                  onSaved: (value) => articlePrice = double.parse(value!),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(articleToEdit == null ? 'Add' : 'Save'),
              onPressed: () {
                if (articleFormKey.currentState!.validate()) {
                  articleFormKey.currentState!.save();
                  setState(() {
                    if (articleToEdit == null) {
                      // Add new
                      _articles.add(
                        Article(
                          id:
                              DateTime.now().millisecondsSinceEpoch.toString() +
                              Random()
                                  .nextInt(1000)
                                  .toString(), // Simple unique ID for client-side list
                          name: articleName,
                          price: articlePrice,
                        ),
                      );
                    } else {
                      // Edit existing
                      if (articleIndex != null) {
                        _articles[articleIndex] = articleToEdit.copyWith(
                          name: articleName,
                          price: articlePrice,
                        );
                      }
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalToEdit == null ? 'Add New Goal' : 'Edit Goal'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Use ListView to prevent overflow on smaller screens
            children: <Widget>[
              TextFormField(
                initialValue: _name, // Set initial value
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              SizedBox(height: 20),
              TextFormField(
                initialValue: _targetAmount > 0
                    ? _targetAmount.toStringAsFixed(2)
                    : '', // Set initial value
                decoration: InputDecoration(
                  labelText: 'Target Amount (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro_symbol), // Changed icon
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
                onSaved: (value) => _targetAmount = double.parse(value!),
              ),
              SizedBox(height: 20),
              TextFormField(
                initialValue: _paypalEmail, // Set initial value
                decoration: InputDecoration(
                  labelText: 'PayPal Email (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                // No validator needed for optional field, unless specific format is required when present
                onSaved: (value) => _paypalEmail = value ?? '',
              ),
              SizedBox(height: 20),
              Divider(thickness: 1.5),
              SizedBox(height: 10),
              Text(
                'Articles / Items for this Goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 10),
              _articles.isEmpty
                  ? Center(
                      child: Text(
                        'No articles added yet. Click "Add Article" to start.',
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics:
                          NeverScrollableScrollPhysics(), // To use inside another ListView
                      itemCount: _articles.length,
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(article.name),
                            subtitle: Text(
                              'Price: €${article.price.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blueGrey,
                                  ),
                                  onPressed: () => _addOrEditArticleDialog(
                                    articleToEdit: article,
                                    articleIndex: index,
                                  ),
                                  tooltip: 'Edit Article',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _articles.removeAt(index);
                                    });
                                  },
                                  tooltip: 'Remove Article',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              SizedBox(height: 10),
              OutlinedButton.icon(
                icon: Icon(Icons.add_shopping_cart_outlined),
                label: Text('Add Article'),
                onPressed: () => _addOrEditArticleDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurpleAccent,
                  side: BorderSide(color: Colors.deepPurpleAccent),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  widget.goalToEdit == null ? 'Save New Goal' : 'Update Goal',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
