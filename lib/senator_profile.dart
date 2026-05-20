import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'optimizer_engine.dart';

/// TODO:  Implement the detailed profile view for the senators.
/// You can use the `senator` object to display their legislative record, 
/// biography, and other relevant data.
/// PWEDE RIN ung kung ano itsura rito: https://senate.gov.ph/senator/Alan-Peter-S.-Cayetano
/// hanggang sa contact (or biography also ?), then a button? to that link (para mapunta user don)
class SenatorProfileScreen extends StatelessWidget {
  final Senator senator;

  const SenatorProfileScreen({super.key, required this.senator});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(senator.name),
        backgroundColor: AppColors.navy,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              "Profile for ${senator.name}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Content to be implemented by the team.",
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
