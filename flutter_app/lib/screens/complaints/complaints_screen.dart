import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Complaints / Service Tickets',
      subtitle: 'Manage customer complaints and service tickets',
      child: const Placeholder(),
    );
  }
}
