import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';
import 'optimizer_engine.dart';

class SenatorProfileScreen extends StatelessWidget {
  final Senator senator;

  const SenatorProfileScreen({super.key, required this.senator});

  // This formats "Alan Peter S. Cayetano" into "Alan-Peter-S.-Cayetano"
  Future<void> _launchSenateProfile() async {
    final String urlSlug = senator.name.replaceAll(' ', '-');
    final Uri url = Uri.parse('https://senate.gov.ph/senator/$urlSlug');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(senator.name),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.phBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance,
                size: 80,
                color: AppColors.phBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              senator.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Legislative Record Value: ${senator.v}",
              style: const TextStyle(fontSize: 16, color: AppColors.muted),
            ),
            const Spacer(),
            const Text(
              "Detailed biographies, co-authored resolutions, and contact information are hosted on the official Senate database.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchSenateProfile,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('View Full Senate Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.phBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
