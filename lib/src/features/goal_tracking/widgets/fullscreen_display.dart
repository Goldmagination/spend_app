import 'package:flutter/material.dart';

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
    if (progress < 0.0) progress = 0.0; // Ensure progress is not negative

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
                    final random = Random(); // Ensure Random is available or pass it
                    return AnimatedBuilder(
                      animation: _sparkleAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left:
                              MediaQuery.of(context).size.width *
                              (random.nextDouble() * 0.8 + 0.1), // More random distribution
                          top:
                              MediaQuery.of(context).size.height *
                              (random.nextDouble() * 0.8 + 0.1), // More random distribution
                          child: Transform.rotate(
                            angle: _sparkleAnimation.value * 6.28 * (random.nextBool() ? 1 : -1) * (random.nextDouble() * 0.5 + 0.5), // Random direction and speed
                            child: Opacity(
                              opacity: (1.0 - _sparkleAnimation.value).abs().clamp(0.0, 1.0),
                              child: Icon(
                                Icons.star,
                                color: Colors.yellow.shade300.withOpacity(random.nextDouble() * 0.5 + 0.5), // Random opacity
                                size: 20 + (random.nextDouble() * 20), // Random size
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
                                shadows: [ // Add shadow for better readability
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ],
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
                                         shadows: [
                                          Shadow(
                                            blurRadius: 8.0,
                                            color: Colors.black.withOpacity(0.7),
                                            offset: Offset(1.0, 1.0),
                                          ),
                                        ],
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
                                        shadows: [
                                          Shadow(
                                            blurRadius: 6.0,
                                            color: Colors.black.withOpacity(0.7),
                                            offset: Offset(1.0, 1.0),
                                          ),
                                        ],
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
                                  boxShadow: [ // Add glow effect
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.5),
                                      blurRadius: 20.0,
                                      spreadRadius: 5.0,
                                    ),
                                  ],
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

// Need to import Random for sparkle effect
import 'dart:math';
