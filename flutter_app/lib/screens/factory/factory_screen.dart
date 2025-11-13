import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class FactoryScreen extends StatelessWidget {
  const FactoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Factory / Production Control',
      subtitle: 'Track AHU serial numbers and production stages',
      child: const Placeholder(),
    );
  }
}
