import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class SiteLogsScreen extends StatelessWidget {
  const SiteLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Daily Site Logs',
      subtitle: 'Track daily work done at sites',
      child: const Placeholder(),
    );
  }
}
