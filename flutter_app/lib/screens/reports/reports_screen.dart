import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Reports',
      subtitle: 'View and export company reports',
      child: const Placeholder(),
    );
  }
}
