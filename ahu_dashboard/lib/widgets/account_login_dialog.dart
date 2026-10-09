import 'package:flutter/material.dart';

import '../services/account_auth_service.dart';
import '../services/dashboard_update_service.dart';

/// ID and password popup. Enter uses the phone login API.
/// The icon button checks this Radxa for a dashboard update.
class AccountLoginDialog extends StatefulWidget {
  const AccountLoginDialog({super.key});

  @override
  State<AccountLoginDialog> createState() => _AccountLoginDialogState();
}

class _AccountLoginDialogState extends State<AccountLoginDialog> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AccountAuthService();
  final _updates = DashboardUpdateService();

  bool _obscurePassword = true;
  bool _signingIn = false;
  bool _updating = false;
  String? _error;
  String? _updateMessage;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_signingIn) return;
    setState(() {
      _signingIn = true;
      _error = null;
    });
    final result = await _auth.login(
      _idController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (result.session == null) {
      setState(() {
        _signingIn = false;
        _error = result.error ?? 'Invalid ID or password';
      });
      return;
    }
    Navigator.of(context).pop(result.session);
  }

  Future<void> _checkUpdate() async {
    if (_updating) return;
    setState(() {
      _updating = true;
      _updateMessage = null;
      _error = null;
    });
    final message = await _updates.checkAndUpdate();
    if (!mounted) return;
    setState(() {
      _updating = false;
      _updateMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.height < 650;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 24 : 40,
        vertical: isSmall ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Login',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmall ? 12 : 20),
              TextField(
                controller: _idController,
                enabled: !_signingIn,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onSubmitted: (_) => _enter(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                enabled: !_signingIn,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onSubmitted: (_) => _enter(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (_updateMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _updateMessage!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              SizedBox(height: isSmall ? 14 : 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _signingIn ? null : _enter,
                      child: _signingIn
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _updating ? null : _checkUpdate,
                    icon: _updating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.system_update_alt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
