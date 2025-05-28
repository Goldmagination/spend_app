import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/app.dart'; // Adjusted import path
import 'src/core/models/article_model.dart'; // Import Article model
import 'src/core/models/goal_model.dart';   // Import Goal model
// Import generated adapters
import 'src/core/models/article_model.g.dart';
import 'src/core/models/goal_model.g.dart';

void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Hive.initFlutter(); // Initialize Hive

  // Register adapters
  Hive.registerAdapter(ArticleAdapter());
  Hive.registerAdapter(GoalAdapter());

  await GoalService.init(); // Initialize GoalService

  runApp(MyApp());
}
