import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/or_phone_provider.dart';

class OrPhoneDialerDialog extends StatelessWidget {
  const OrPhoneDialerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<OrPhoneProvider>();
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Hospital line')),
          IconButton(
            tooltip: 'SIP / gateway',
            onPressed: () => _editSip(context),
            icon: const Icon(Icons.settings_rounded, size: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                phone.dialBuffer.isEmpty ? ' ' : phone.dialBuffer,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              phone.status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _PresetChip(index: i)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['*', '0', '#'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    for (var c = 0; c < 3; c++) ...[
                      if (c > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _Key(
                          label: row[c],
                          onTap: () => phone.appendDigit(row[c]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: phone.backspace,
                    child: const Icon(Icons.backspace_outlined, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: phone.canHangup
                      ? FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                          onPressed: phone.hangup,
                          icon: const Icon(Icons.call_end_rounded),
                          label: const Text('End'),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                          ),
                          onPressed: phone.callTypedNumber,
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('Call'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSip(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _SipSettingsDialog(),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int index;

  const _PresetChip({required this.index});

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<OrPhoneProvider>();
    final p = phone.presets[index];
    final empty = p.number.isEmpty;
    return Material(
      color: const Color(0xFF6366F1).withOpacity(empty ? 0.08 : 0.16),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: empty ? () => _edit(context, phone) : () => phone.dialPreset(index),
        onLongPress: () => _edit(context, phone),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            empty ? 'Set ${index + 1}' : p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF6366F1),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, OrPhoneProvider phone) async {
    final name = TextEditingController(text: phone.presets[index].name);
    final number = TextEditingController(text: phone.presets[index].number);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Preset ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: number,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long-press a preset later to change it.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await phone.setPreset(
                index,
                name: name.text,
                number: number.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    number.dispose();
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _SipSettingsDialog extends StatefulWidget {
  const _SipSettingsDialog();

  @override
  State<_SipSettingsDialog> createState() => _SipSettingsDialogState();
}

class _SipSettingsDialogState extends State<_SipSettingsDialog> {
  late final TextEditingController _host;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _prefix;

  @override
  void initState() {
    super.initState();
    final phone = context.read<OrPhoneProvider>();
    _host = TextEditingController(text: phone.sipHost);
    _user = TextEditingController(text: phone.sipUser);
    _pass = TextEditingController();
    _prefix = TextEditingController(text: phone.sipPrefix);
  }

  @override
  void dispose() {
    _host.dispose();
    _user.dispose();
    _pass.dispose();
    _prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<OrPhoneProvider>();
    return AlertDialog(
      title: const Text('USB FXO'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hospital RJ11 into the USB FXO stick. Leave Ethernet for LAN. SIP host is usually 127.0.0.1 if Asterisk is on this Radxa.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _host,
              decoration: const InputDecoration(
                labelText: 'SIP host',
                hintText: '127.0.0.1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _user,
              decoration: const InputDecoration(
                labelText: 'SIP user',
                hintText: '100',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'SIP password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _prefix,
              decoration: const InputDecoration(
                labelText: 'Outside prefix (0 or 9, optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await phone.setSip(
              host: _host.text,
              user: _user.text,
              password: _pass.text.isEmpty ? null : _pass.text,
              prefix: _prefix.text,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
