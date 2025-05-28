import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import '../../../core/models/goal_model.dart';
import '../../../core/services/goal_service.dart';
import 'dart:math'; // For random ID

class AddEditGoalScreen extends StatefulWidget {
  // final Goal? goalToEdit; // If you want to use this screen for editing later

  // AddEditGoalScreen({this.goalToEdit});

  @override
  _AddEditGoalScreenState createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final GoalService _goalService = GoalService();

  String _name = '';
  double _targetAmount = 0.0;
  String _paypalEmail = '';

  // @override
  // void initState() {
  //   super.initState();
  //   if (widget.goalToEdit != null) {
  //     _name = widget.goalToEdit!.name;
  //     _targetAmount = widget.goalToEdit!.targetAmount;
  //     _paypalEmail = widget.goalToEdit!.paypalEmail ?? '';
  //   }
  // }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // For now, only adding new goals.
      // ID generation is simplified here. In a real app, use UUID or backend-generated IDs.
      String id = DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(99999).toString();
      
      final newGoal = Goal(
        id: id,
        name: _name,
        targetAmount: _targetAmount,
        paypalEmail: _paypalEmail.isNotEmpty ? _paypalEmail : null,
        // currentAmount and isHighlighted will use default values from Goal model
      );
      
      _goalService.addGoal(newGoal);
      
      Navigator.pop(context, true); // Return true to indicate a goal was added/changed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Goal'), // Later: widget.goalToEdit == null ? 'Add New Goal' : 'Edit Goal'
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView to prevent overflow on smaller screens
            children: <Widget>[
              TextFormField(
                // initialValue: _name,
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
                // initialValue: _targetAmount.toString(),
                decoration: InputDecoration(
                  labelText: 'Target Amount (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
                onSaved: (value) => _targetAmount = double.parse(value!),
              ),
              SizedBox(height: 20),
              TextFormField(
                // initialValue: _paypalEmail,
                decoration: InputDecoration(
                  labelText: 'PayPal Email (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                // No validator needed for optional field, unless specific format is required when present
                onSaved: (value) => _paypalEmail = value ?? '',
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveGoal,
                child: Text('Save Goal', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
