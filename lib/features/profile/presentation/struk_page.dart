import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_back_button.dart';

class StrukPage extends StatelessWidget {
  const StrukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(
          color: Colors.black,
          size: 20,
        ),
        title: const Text(
          'Struk',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Riwayat struk akan ditampilkan di sini.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
