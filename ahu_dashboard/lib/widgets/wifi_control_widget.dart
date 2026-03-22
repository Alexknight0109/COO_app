import 'package:flutter/material.dart';
import '../services/wifi_service.dart';

/// WiFi control widget for admin pages
class WiFiControlWidget extends StatefulWidget {
  const WiFiControlWidget({super.key});

  @override
  State<WiFiControlWidget> createState() => _WiFiControlWidgetState();
}

class _WiFiControlWidgetState extends State<WiFiControlWidget> {
  final WiFiService _wifiService = WiFiService();
  List<WiFiNetwork> _networks = [];
  WiFiNetwork? _currentConnection;
  bool _isLoading = false;
  bool _isAvailable = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _wifiService.isAvailable();
    setState(() {
      _isAvailable = available;
    });
    if (available) {
      _refreshNetworks();
    }
  }

  Future<void> _refreshNetworks() async {
    if (!_isAvailable) return;

    setState(() {
      _isLoading = true;
      _isScanning = true;
    });

    try {
      final current = await _wifiService.getCurrentConnection();
      final networks = await _wifiService.scanNetworks();
      
      setState(() {
        _currentConnection = current;
        _networks = networks;
        _isLoading = false;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning WiFi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectToNetwork(WiFiNetwork network) async {
    // If it's an open network
    if (network.security == null || network.security!.isEmpty || network.security == '--') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connect to Open Network'),
          content: Text('Connect to "${network.ssid}"? This network has no password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Connect'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        _connectWithPassword(network.ssid, null);
      }
      return;
    }

    // Show password dialog for secured networks
    final password = await showDialog<String>(
      context: context,
      builder: (context) => _PasswordDialog(ssid: network.ssid),
    );

    if (password != null) {
      _connectWithPassword(network.ssid, password);
    }
  }

  Future<void> _connectWithPassword(String ssid, String? password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = password != null && password.isNotEmpty
          ? await _wifiService.connect(ssid, password)
          : await _wifiService.connectOpen(ssid);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh networks after connection
          await Future.delayed(const Duration(seconds: 2));
          _refreshNetworks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection failed. Check password and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect WiFi'),
        content: const Text('Are you sure you want to disconnect from the current network?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _wifiService.disconnect();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disconnected successfully'),
                backgroundColor: Colors.orange,
              ),
            );
            _refreshNetworks();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to disconnect'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.grey),
            const SizedBox(width: 12),
            const Text('WiFi control not available on this platform'),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.wifi, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WiFi Networks',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_currentConnection != null)
                        Text(
                          'Connected: ${_currentConnection!.ssid}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                        ),
                    ],
                  ),
                ),
                if (_currentConnection != null)
                  IconButton(
                    icon: const Icon(Icons.wifi_off, color: Colors.red),
                    onPressed: _isLoading ? null : _disconnect,
                    tooltip: 'Disconnect',
                  ),
                IconButton(
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _refreshNetworks,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Networks list
          if (_isLoading && _networks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_networks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No networks found'),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _networks.length,
                itemBuilder: (context, index) {
                  final network = _networks[index];
                  return _WiFiNetworkTile(
                    network: network,
                    onTap: () => _connectToNetwork(network),
                    isConnected: network.isConnected,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WiFiNetworkTile extends StatelessWidget {
  final WiFiNetwork network;
  final VoidCallback onTap;
  final bool isConnected;

  const _WiFiNetworkTile({
    required this.network,
    required this.onTap,
    required this.isConnected,
  });

  IconData _getSignalIcon(int signal) {
    if (signal >= 75) return Icons.wifi;
    if (signal >= 50) return Icons.wifi_2_bar;
    if (signal >= 25) return Icons.wifi_1_bar;
    return Icons.wifi_off;
  }

  Color _getSignalColor(int signal) {
    if (signal >= 50) return Colors.green;
    if (signal >= 25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isConnected ? Icons.check_circle : _getSignalIcon(network.signal),
        color: isConnected ? Colors.green : _getSignalColor(network.signal),
      ),
      title: Text(
        network.ssid,
        style: TextStyle(
          fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
          color: isConnected ? Colors.green : null,
        ),
      ),
      subtitle: Row(
        children: [
          if (network.security != null && network.security!.isNotEmpty && network.security != '--')
            Chip(
              label: Text(network.security!),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: 8),
          Text('${network.signal}%'),
        ],
      ),
      trailing: isConnected
          ? const Icon(Icons.check, color: Colors.green)
          : const Icon(Icons.chevron_right),
      onTap: isConnected ? null : onTap,
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  final String ssid;

  const _PasswordDialog({required this.ssid});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Connect to ${widget.ssid}'),
      content: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Enter WiFi password',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.pop(context, value);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _passwordController.text.isEmpty
              ? null
              : () => Navigator.pop(context, _passwordController.text),
          child: const Text('Connect'),
        ),
      ],
    );
  }
}

