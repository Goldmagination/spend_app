import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard

class DeviceSelectionDialog extends StatefulWidget {
  final Future<void> Function() onStartServer;
  final String? serverUrl;
  final VoidCallback onLocalDisplay;

  const DeviceSelectionDialog({
    super.key,
    required this.onStartServer,
    required this.serverUrl,
    required this.onLocalDisplay,
  });

  @override
  _DeviceSelectionDialogState createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<DeviceSelectionDialog> {
  late bool isServerStarted;

  @override
  void initState() {
    super.initState();
    // Initialize the server state based on the serverUrl
    isServerStarted = widget.serverUrl != null;
  }

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
      content: SizedBox(
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
                        // Fetch the updated serverUrl and refresh the UI
                        setState(() {});
                      },
              ),
            ),
            if (isServerStarted) ...[
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.serverUrl ?? '',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                color: Colors.green.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: Colors.green.shade800,
                            ),
                            onPressed: () {
                              final serverUrl = widget.serverUrl;
                              if (serverUrl != null) {
                                Clipboard.setData(
                                  ClipboardData(text: serverUrl),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'IP address copied to clipboard!',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
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
