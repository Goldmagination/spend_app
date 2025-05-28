import 'package:flutter/material.dart';
import 'dart:async'; // For TickerProviderStateMixin

import 'features/goal_tracking/widgets/device_selection_dialog.dart';
import 'features/goal_tracking/widgets/fullscreen_display.dart';
import 'features/goal_tracking/services/server_service.dart';
import 'core/services/goal_service.dart'; // Import GoalService
import 'core/models/goal_model.dart';    // Import Goal model
import 'features/admin_panel/screens/admin_panel_screen.dart'; // Import AdminPanelScreen

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Goal Tracker',
      theme: ThemeData(primarySwatch: Colors.deepPurple, fontFamily: 'Roboto'), // Changed to deepPurple
      home: MoneyGoalTracker(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MoneyGoalTracker extends StatefulWidget {
  @override
  _MoneyGoalTrackerState createState() => _MoneyGoalTrackerState();
}

class _MoneyGoalTrackerState extends State<MoneyGoalTracker>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  final GoalService _goalService = GoalService();
  final GoalDisplayServer _serverService = GoalDisplayServer();
  
  Goal? _highlightedGoal;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _loadHighlightedGoal();
    _updateServerData(); // Initial update for the server
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    _serverService.stop();
    super.dispose();
  }

  void _loadHighlightedGoal() {
    setState(() {
      _highlightedGoal = _goalService.getHighlightedGoal();
      // Reset celebration if the highlighted goal changed or no goal is highlighted
      if (_highlightedGoal == null || (_highlightedGoal!.currentAmount < _highlightedGoal!.targetAmount)) {
        _celebrationController.reset();
      }
    });
    _updateServerData();
  }

  void _updateServerData() {
    if (_highlightedGoal != null) {
      _serverService.updateGoalData(
        _highlightedGoal!.currentAmount,
        _highlightedGoal!.targetAmount,
        _highlightedGoal!.currentAmount >= _highlightedGoal!.targetAmount && _highlightedGoal!.targetAmount > 0,
      );
    } else {
      // Send default/empty data if no goal is highlighted
      _serverService.updateGoalData(0, 0, false);
    }
  }

  void addMoney(double amount) {
    if (_highlightedGoal == null) return;

    setState(() {
      _highlightedGoal!.currentAmount += amount;
      // Cap current amount at target amount if you prefer, for now, it can exceed.
      // _highlightedGoal!.currentAmount = _highlightedGoal!.currentAmount.clamp(0, _highlightedGoal!.targetAmount);
      
      bool goalWasReached = _highlightedGoal!.currentAmount - amount >= _highlightedGoal!.targetAmount;
      bool goalIsNowReached = _highlightedGoal!.currentAmount >= _highlightedGoal!.targetAmount && _highlightedGoal!.targetAmount > 0;

      if (goalIsNowReached && !goalWasReached) {
        _celebrationController.forward();
      }
    });
    _goalService.updateGoal(_highlightedGoal!); // Update in service
    _progressController.forward(from:0.0);
    _updateServerData();
  }

  void resetGoal() {
    if (_highlightedGoal == null) return;

    setState(() {
      _highlightedGoal!.currentAmount = 0.0;
    });
    _goalService.updateGoal(_highlightedGoal!); // Update in service
    _progressController.reset();
    _celebrationController.reset();
    _updateServerData();
  }

  Future<void> _startWebServer() async {
    final url = await _serverService.start();
    if (!mounted) return;
    setState(() {
      _serverUrl = url;
    });
    if (url != null) {
      _updateServerData(); 
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting server. IP could not be determined or server failed.')),
        );
      }
    }
  }

  void _navigateToAdminPanel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminPanelScreen()),
    );
    _loadHighlightedGoal(); // Refresh highlighted goal when returning from admin panel
  }

  @override
  Widget build(BuildContext context) {
    final currentAmount = _highlightedGoal?.currentAmount ?? 0.0;
    final targetAmount = _highlightedGoal?.targetAmount ?? 0.0; // Default to 0 if no goal, prevents NaN
    final goalName = _highlightedGoal?.name ?? "No Goal Selected";
    final bool isGoalAchieved = targetAmount > 0 && currentAmount >= targetAmount;

    double progress = 0.0;
    if (targetAmount > 0) {
      progress = (currentAmount / targetAmount).clamp(0.0, 1.0);
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          goalName, // Display current goal name or default
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _navigateToAdminPanel,
            tooltip: 'Admin Panel',
          ),
        ],
      ),
      body: _highlightedGoal == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.highlight_off_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 20),
                  Text(
                    'No Goal Highlighted',
                    style: TextStyle(fontSize: 22, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Go to Admin Panel to create or highlight a goal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.settings),
                    label: Text('Open Admin Panel'),
                    onPressed: _navigateToAdminPanel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  )
                ],
              ),
            )
          : Container( // Main content when a goal is highlighted
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.deepPurple.shade50, Colors.white],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isGoalAchieved ? _scaleAnimation.value : 1.0,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Goal Progress',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: AnimatedBuilder(
                                          animation: _progressAnimation,
                                          builder: (context, child) {
                                            return CircularProgressIndicator(
                                              value: progress * _progressAnimation.value,
                                              strokeWidth: 12,
                                              backgroundColor: Colors.grey[300],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isGoalAchieved ? Colors.green : Colors.deepPurple,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '\$${currentAmount.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: isGoalAchieved ? Colors.green : Colors.deepPurple,
                                            ),
                                          ),
                                          Text(
                                            'of \$${targetAmount.toStringAsFixed(0)}',
                                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${(progress * 100).toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: isGoalAchieved ? Colors.green : Colors.deepPurple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  if (isGoalAchieved)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.celebration, color: Colors.green, size: 24),
                                          SizedBox(width: 8),
                                          Text('Goal Achieved! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => addMoney(10),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              child: Column(children: [Icon(Icons.add, size: 24), SizedBox(height: 4), Text('+\$10', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => addMoney(20),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              child: Column(children: [Icon(Icons.add, size: 24), SizedBox(height: 4), Text('+\$20', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text('Reset Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            onPressed: resetGoal,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: BorderSide(color: Colors.deepPurple),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.display_settings_outlined), // Changed Icon
                            label: Text('Display Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return DeviceSelectionDialog(
                                    onStartServer: _startWebServer,
                                    serverUrl: _serverUrl,
                                    onLocalDisplay: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullscreenDisplay(
                                            currentAmount: currentAmount,
                                            goalAmount: targetAmount, // Use targetAmount from highlighted goal
                                            goalReached: isGoalAchieved,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
