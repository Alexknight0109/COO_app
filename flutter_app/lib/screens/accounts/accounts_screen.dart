import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Accounts & Payments',
      subtitle: 'Track PO values and payment stages',
      child: const Placeholder(),
    );
  }
}
