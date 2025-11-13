import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class HRScreen extends StatelessWidget {
  const HRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'HR / Employees',
      subtitle: 'Manage employee profiles and permissions',
      child: const Placeholder(),
    );
  }
}
