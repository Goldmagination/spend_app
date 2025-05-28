import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard

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
                        // No need to call setState here as the parent widget's state (serverUrl)
                        // will trigger a rebuild of this dialog if it's still visible.
                        // If the dialog is rebuilt due to parent changes, isServerStarted will be re-evaluated.
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
