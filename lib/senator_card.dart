import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'optimizer_engine.dart'; // To access the Senator class

class SenatorCard extends StatelessWidget {
  final Senator senator;
  final bool isSelected;
  final VoidCallback onTap;

  const SenatorCard({
    super.key,
    required this.senator,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // We use GestureDetector to make the whole card tappable
    return GestureDetector(
      onTap: onTap,
      // AnimatedContainer gives us that smooth CSS transition effect
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12), // --radius: 12px
          border: Border.all(
            color: isSelected ? AppColors.phBlue : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.phBlue.withOpacity(0.12),
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW: Name, Party, and Check Circle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senator.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        senator.party,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.faint,
                          // You can add GoogleFonts package later for 'DM Mono'
                        ),
                      ),
                    ],
                  ),
                ),
                // Check Circle
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.phBlue : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.phBlue
                          : AppColors.borderStrong,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // METRICS ROW
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildMetricPill(
                  'Authored: ${senator.authored}',
                  AppColors.surface,
                  AppColors.muted,
                ),
                _buildMetricPill(
                  'Passed: ${senator.passed}',
                  AppColors.surface,
                  AppColors.muted,
                ),
                if (senator.authored > 0) ...[
                  _buildMetricPill(
                    'V = ${senator.v}',
                    const Color(0xFFEFF4FF),
                    const Color(0xFF2155B8),
                  ),
                  _buildMetricPill(
                    'W = ${senator.w}',
                    const Color(0xFFFFF1F1),
                    AppColors.phRed,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for the .mpill CSS class
  Widget _buildMetricPill(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
