import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Inventory / Store',
      subtitle: 'Manage stock levels and material issues',
      child: const Placeholder(),
    );
  }
}
