import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../../../core/services/goal_service.dart'; // Import GoalService
import '../../../core/models/goal_model.dart'; // Import Goal model

class GoalDisplayServer {
  HttpServer? _server;
  String? _serverUrl;
  final GoalService _goalService = GoalService(); // Use GoalService

  // Removed local state for currentAmount, goalAmount, goalReached
  // as this will now be fetched from the highlightedGoal via GoalService.

  String? get serverUrl => _serverUrl;

  Future<String?> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      final ip = await _getLocalIP();
      if (ip == null) {
        print('Failed to get local IP address.');
        await _server?.close();
        _server = null;
        return null;
      }
      _serverUrl = 'http://$ip:8080';

      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/') {
          _serveDisplayPage(request);
        } else if (request.uri.path == '/api/data') {
          _serveApiData(request);
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.headers.contentType = ContentType.text;
          request.response.write('Not Found');
          request.response.close();
        }
      });
      print('Server started at $_serverUrl');
      return _serverUrl;
    } catch (e) {
      print('Failed to start server: $e');
      _serverUrl = null;
      await _server?.close();
      _server = null;
      return null;
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _serverUrl = null;
    print('Server stopped.');
  }

  // This method is no longer strictly needed here if MoneyGoalTracker calls it on GoalService.
  // However, if the server needs to react to data changes independently, it might.
  // For now, data is pulled when client requests /api/data or /
  // void updateGoalData(double currentAmount, double goalAmount, bool goalReached) {
  //   // Data is now sourced from GoalService's highlighted goal
  // }

  void _serveDisplayPage(HttpRequest request) {
    Goal? highlightedGoal = _goalService.getHighlightedGoal();
    double current = highlightedGoal?.currentAmount ?? 0;
    double target = highlightedGoal?.targetAmount ?? 0;
    bool reached = highlightedGoal != null && target > 0 && current >= target;

    final html = _generateDisplayHTML(
      current,
      target,
      reached,
      highlightedGoal?.name,
    );
    request.response.headers.contentType = ContentType.html;
    request.response.write(html);
    request.response.close();
  }

  void _serveApiData(HttpRequest request) {
    Goal? highlightedGoal = _goalService.getHighlightedGoal();
    double current = highlightedGoal?.currentAmount ?? 0;
    double target =
        highlightedGoal?.targetAmount ?? 0; // Ensure target is not null
    bool reached = highlightedGoal != null && target > 0 && current >= target;
    double progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;

    final data = {
      'goalName': highlightedGoal?.name ?? 'No Goal Selected',
      'currentAmount': current,
      'goalAmount': target,
      'goalReached': reached,
      'progress': progress,
    };
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    request.response.close();
  }

  Future<String?> _getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      if (interfaces.isNotEmpty) {
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.isLinkLocal) {
              // Prioritize non-link-local
              return addr.address;
            }
          }
        }
        // Fallback: if only link-local are found, return the first one of those.
        for (var interface in interfaces) {
          if (interface.addresses.isNotEmpty) {
            print(
              'Warning: No non-link-local IP found. Falling back to the first available IP which might be link-local: ${interface.addresses.first.address}',
            );
            return interface.addresses.first.address;
          }
        }
      }
    } catch (e) {
      print('Error getting IP: $e');
    }
    print('Could not find a suitable local IP address.');
    return null;
  }

  String _generateDisplayHTML(
    double current,
    double goal,
    bool reached,
    String? goalName,
  ) {
    goalName = goalName ?? "No Goal Selected";
    double progress = (goal > 0) ? (current / goal).clamp(0.0, 1.0) : 0.0;
    String serverStatusMessage = _serverUrl == null
        ? "<p style='color:red;'>Server not running or IP not found.</p>"
        : "";

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$goalName - Goal Display</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background-color: #f4f6f8; transition: background-color 0.5s ease; color: #333; }
    body.goal-achieved { background-color: #e8f5e9; /* Softer green */ }
    .container { text-align: center; padding: 20px; background-color: white; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); max-width: 90%; width: 400px; }
    .goal-title { font-size: 20px; font-weight: 500; color: #555; margin-bottom: 8px; }
    .title { font-size: 28px; font-weight: 600; color: #2c3e50; margin-bottom: 25px; text-transform: uppercase; letter-spacing: 1.5px; }
    .progress-container { position: relative; width: 220px; height: 220px; margin: 20px auto; }
    .progress-circle { width: 100%; height: 100%; }
    .progress-bg { fill: none; stroke: #e3e8ed; stroke-width: 20; }
    .progress-fill { fill: none; stroke: #3498db; stroke-width: 20; stroke-linecap: round; transform-origin: 50% 50%; transform: rotate(-90deg); transition: stroke-dasharray 0.3s ease-in-out; }
    body.goal-achieved .progress-fill { stroke: #2ecc71; /* Vibrant green */ }
    .progress-text { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }
    .amount { font-size: 42px; font-weight: bold; color: #3498db; }
    body.goal-achieved .amount { color: #27ae60; }
    .goal-text { font-size: 15px; color: #7f8c8d; margin-top: -5px; }
    .percentage { font-size: 20px; font-weight: 600; color: #34495e; margin-top: 8px; }
    .celebration { display: none; font-size: 32px; color: #f1c40f; /* Yellow gold */ text-shadow: 0 0 8px rgba(241, 196, 15, 0.7); animation: sparkle 1.2s infinite alternate; margin-top: 20px; }
    body.goal-achieved .celebration { display: block; }
    @keyframes sparkle { 
      0% { transform: scale(1); opacity: 0.9; } 
      100% { transform: scale(1.05); opacity: 1; } 
    }
    .server-status { margin-top: 20px; font-size: 12px; color: #95a5a6; }
  </style>
</head>
<body id="body" class="${reached ? 'goal-achieved' : ''}">
  <div class="container">
    <div class="goal-title" id="goalNameDisplay">$goalName</div>
    <div class="title">Goal Progress</div>
    <div class="progress-container">
      <svg class="progress-circle" viewBox="0 0 100 100">
        <circle class="progress-bg" cx="50" cy="50" r="40"></circle>
        <circle class="progress-fill" id="progressFill" cx="50" cy="50" r="40" stroke-dasharray="${progress * 2 * 3.14159265 * 40} ${2 * 3.14159265 * 40}"></circle>
      </svg>
      <div class="progress-text">
        <div class="amount" id="amount">€${current.toStringAsFixed(0)}</div>
        <div class="goal-text">of <span id="goalAmount">€${goal.toStringAsFixed(0)}</span></div>
        <div class="percentage" id="percentage">${(progress * 100).toStringAsFixed(1)}%</div>
      </div>
    </div>
    <div class="celebration" id="celebration" style="${reached ? 'display: block;' : 'display: none;'}">
      🎉 Goal Achieved! 🎉
    </div>
    <div class="server-status" id="serverStatus">$serverStatusMessage</div>
  </div>

  <script>
    function updateData(data) {
      document.getElementById('goalNameDisplay').textContent = data.goalName || 'No Goal Selected';
      document.title = (data.goalName || 'No Goal') + ' - Goal Display';
      document.getElementById('amount').textContent = '€' + Math.floor(data.currentAmount);
      document.getElementById('goalAmount').textContent = '€' + Math.floor(data.goalAmount);
      const percentage = (data.progress * 100).toFixed(1) + '%';
      document.getElementById('percentage').textContent = percentage;

      const progressFill = document.getElementById('progressFill');
      const circumference = 2 * Math.PI * 40; // Radius is 40
      const clampedProgress = Math.max(0, Math.min(1, data.progress)); 
      const dashArray = (clampedProgress * circumference) + ' ' + circumference;
      progressFill.style.strokeDasharray = dashArray;

      const body = document.getElementById('body');
      const celebration = document.getElementById('celebration');
      if (data.goalReached) {
        body.classList.add('goal-achieved');
        celebration.style.display = 'block';
      } else {
        body.classList.remove('goal-achieved');
        celebration.style.display = 'none';
      }
    }

    async function fetchData() {
      try {
        const response = await fetch('/api/data');
        if (!response.ok) {
          console.error('Network response was not ok: ' + response.statusText);
          document.getElementById('serverStatus').innerHTML = "<p style='color:red;'>Error fetching data: " + response.statusText + "</p>";
          return;
        }
        const data = await response.json();
        updateData(data);
        const serverStatusElement = document.getElementById('serverStatus');
        if (serverStatusElement.innerHTML.includes('Error')) {
            serverStatusElement.innerHTML = ''; 
        }
      } catch (error) {
        console.error('Failed to fetch or parse data:', error);
        document.getElementById('serverStatus').innerHTML = "<p style='color:red;'>Failed to connect or parse data. " + error + "</p>";
      }
    }
    fetchData(); 
    setInterval(fetchData, 1500); 
  </script>
</body>
</html>
''';
  }
}
