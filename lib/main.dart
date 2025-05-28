import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Goal Tracker',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: MoneyGoalTracker(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DeviceSelectionDialog extends StatefulWidget {
  final Future<void> Function() onStartServer;
  final String? serverUrl;
  final VoidCallback onLocalDisplay;

  DeviceSelectionDialog({
    required this.onStartServer,
    required this.serverUrl,
    required this.onLocalDisplay,
  });

  @override
  _DeviceSelectionDialogState createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<DeviceSelectionDialog> {
  bool isServerStarted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cast, color: Colors.deepPurple),
          SizedBox(width: 12),
          Text('Display Options'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Local Display Option
            Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.phone_android, color: Colors.blue),
                ),
                title: Text('This Device'),
                subtitle: Text('Show fullscreen on this device'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  widget.onLocalDisplay();
                },
              ),
            ),
            SizedBox(height: 16),
            // WiFi Display Option
            Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.wifi, color: Colors.green),
                ),
                title: Text('WiFi Display'),
                subtitle: Text('Cast to other devices on your network'),
                trailing: isServerStarted
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.arrow_forward_ios),
                onTap: isServerStarted
                    ? null
                    : () async {
                        setState(() {
                          isServerStarted = true;
                        });
                        await widget.onStartServer();
                        setState(() {});
                      },
              ),
            ),
            if (widget.serverUrl != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Server Started!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Open this URL on any device connected to the same WiFi:',
                      style: TextStyle(color: Colors.green.shade600),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.serverUrl!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.serverUrl!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('URL copied to clipboard!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Works on phones, tablets, computers, smart TVs\n'
                      '• Updates in real-time\n'
                      '• Perfect for presentations and events',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

class FullscreenDisplay extends StatefulWidget {
  final double currentAmount;
  final double goalAmount;
  final bool goalReached;

  FullscreenDisplay({
    required this.currentAmount,
    required this.goalAmount,
    required this.goalReached,
  });

  @override
  _FullscreenDisplayState createState() => _FullscreenDisplayState();
}

class _FullscreenDisplayState extends State<FullscreenDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    if (widget.goalReached) {
      _pulseController.repeat(reverse: true);
      _sparkleController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.currentAmount / widget.goalAmount;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: widget.goalReached
                  ? [Colors.green.shade900, Colors.green.shade800, Colors.black]
                  : [
                      Colors.deepPurple.shade900,
                      Colors.deepPurple.shade800,
                      Colors.black,
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Sparkle effects for goal reached
                if (widget.goalReached)
                  ...List.generate(20, (index) {
                    return AnimatedBuilder(
                      animation: _sparkleAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left:
                              MediaQuery.of(context).size.width *
                              (0.1 + (index * 0.04) % 0.8),
                          top:
                              MediaQuery.of(context).size.height *
                              (0.1 + (index * 0.07) % 0.8),
                          child: Transform.rotate(
                            angle: _sparkleAnimation.value * 6.28 * 2,
                            child: Opacity(
                              opacity: (1.0 - _sparkleAnimation.value).abs(),
                              child: Icon(
                                Icons.star,
                                color: Colors.yellow.shade300,
                                size: 20 + (index % 3) * 10,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                // Main content
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: widget.goalReached ? _pulseAnimation.value : 1.0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Title
                            Text(
                              'GOAL PROGRESS',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                            ),
                            SizedBox(height: 60),
                            // Large Progress Circle
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 400,
                                  height: 400,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 20,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.goalReached
                                          ? Colors.greenAccent
                                          : Colors.purpleAccent,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '\$${widget.currentAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 80,
                                        fontWeight: FontWeight.bold,
                                        color: widget.goalReached
                                            ? Colors.greenAccent
                                            : Colors.purpleAccent,
                                      ),
                                    ),
                                    Text(
                                      'of \$${widget.goalAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w600,
                                        color: widget.goalReached
                                            ? Colors.greenAccent
                                            : Colors.purpleAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 60),
                            // Goal Status
                            if (widget.goalReached)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.greenAccent,
                                    width: 3,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.celebration,
                                      color: Colors.greenAccent,
                                      size: 48,
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'GOAL ACHIEVED!',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Exit hint
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tap anywhere to exit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoneyGoalTracker extends StatefulWidget {
  @override
  _MoneyGoalTrackerState createState() => _MoneyGoalTrackerState();
}

class _MoneyGoalTrackerState extends State<MoneyGoalTracker>
    with TickerProviderStateMixin {
  double currentAmount = 0.0;
  double goalAmount = 500.0;
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  bool goalReached = false;
  HttpServer? _server;
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
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    _server?.close();
    super.dispose();
  }

  void addMoney(double amount) {
    setState(() {
      currentAmount += amount;
      if (currentAmount >= goalAmount && !goalReached) {
        goalReached = true;
        _celebrationController.forward();
      }
    });
    _progressController.forward();
    _updateWebClients();
  }

  void resetGoal() {
    setState(() {
      currentAmount = 0.0;
      goalReached = false;
    });
    _progressController.reset();
    _celebrationController.reset();
    _updateWebClients();
  }

  Future<void> _startWebServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _serverUrl = 'http://${await _getLocalIP()}:8080';

      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/') {
          _serveDisplayPage(request);
        } else if (request.uri.path == '/api/data') {
          _serveApiData(request);
        } else {
          request.response.statusCode = 404;
          request.response.close();
        }
      });

      print('Server started at $_serverUrl');
    } catch (e) {
      print('Failed to start server: $e');
    }
  }

  void _serveDisplayPage(HttpRequest request) {
    final html = _generateDisplayHTML();
    request.response.headers.contentType = ContentType.html;
    request.response.write(html);
    request.response.close();
  }

  void _serveApiData(HttpRequest request) {
    final data = {
      'currentAmount': currentAmount,
      'goalAmount': goalAmount,
      'goalReached': goalReached,
      'progress': currentAmount / goalAmount,
    };
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    request.response.close();
  }

  void _updateWebClients() {
    // In a full implementation, you'd use WebSockets for real-time updates.
    // For simplicity, clients will poll the API endpoint.
  }

  Future<String> _getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting IP: $e');
    }
    return 'localhost';
  }

  String _generateDisplayHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Money Goal Display</title>
  <style>
    /* ...styles omitted for brevity... */
  </style>
</head>
<body id="body">
  <div class="title">GOAL PROGRESS</div>
  <div class="progress-container">
    <svg class="progress-circle" viewBox="0 0 200 200">
      <circle class="progress-bg" cx="100" cy="100" r="85"></circle>
      <circle class="progress-fill" id="progressFill" cx="100" cy="100" r="85" stroke-dasharray="0 534.07" stroke-dashoffset="0"></circle>
    </svg>
    <div class="progress-text">
      <div class="amount" id="amount">\$0</div>
      <div class="goal-text">of <span id="goalAmount">\$500</span></div>
      <div class="percentage" id="percentage">0.0%</div>
    </div>
  </div>
  <div class="celebration" id="celebration" style="display: none;">
    🎉 GOAL ACHIEVED! 🎉
  </div>
  <script>
    async function updateDisplay() {
      try {
        const response = await fetch('/api/data');
        const data = await response.json();
        document.getElementById('amount').textContent = '\$' + Math.floor(data.currentAmount);
        document.getElementById('goalAmount').textContent = '\$' + Math.floor(data.goalAmount);
        document.getElementById('percentage').textContent = (data.progress * 100).toFixed(1) + '%';
        const circumference = 2 * Math.PI * 85;
        const dashArray = (data.progress * circumference) + ' ' + circumference;
        document.getElementById('progressFill').style.strokeDasharray = dashArray;
        
        const body = document.getElementById('body');
        const celebration = document.getElementById('celebration');
        
        if (data.goalReached) {
          body.classList.add('goal-achieved');
          celebration.style.display = 'block';
        } else {
          body.classList.remove('goal-achieved');
          celebration.style.display = 'none';
        }
      } catch (error) {
        console.error('Failed to update display:', error);
      }
    }
    setInterval(updateDisplay, 1000);
    updateDisplay();
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    double progress = currentAmount / goalAmount;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Money Goal Tracker',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
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
                // Goal Card
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: goalReached ? _scaleAnimation.value : 1.0,
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
                            // Progress Circle
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
                                        value:
                                            progress * _progressAnimation.value,
                                        strokeWidth: 12,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              goalReached
                                                  ? Colors.green
                                                  : Colors.deepPurple,
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
                                        color: goalReached
                                            ? Colors.green
                                            : Colors.deepPurple,
                                      ),
                                    ),
                                    Text(
                                      'of \$${goalAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: goalReached
                                            ? Colors.green
                                            : Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            // Goal Status
                            if (goalReached)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.celebration,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Goal Achieved! 🎉',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
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
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => addMoney(10),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add, size: 24),
                            SizedBox(height: 4),
                            Text(
                              '+\$10',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => addMoney(20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add, size: 24),
                            SizedBox(height: 4),
                            Text(
                              '+\$20',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Reset and Display Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: resetGoal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: BorderSide(color: Colors.deepPurple),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text(
                            'Reset Goal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
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
                                      goalAmount: goalAmount,
                                      goalReached: goalReached,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen),
                          SizedBox(width: 8),
                          Text(
                            'Display Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
