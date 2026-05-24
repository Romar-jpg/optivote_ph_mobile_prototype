import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'optimizer_engine.dart'; // To access the Senator class

class SenatorCard extends StatelessWidget {
  final Senator senator;
  final bool isSelected;
  final bool isExcluded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SenatorCard({
    super.key,
    required this.senator,
    required this.isSelected,
    this.isExcluded = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExcluded ? onLongPress : onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isExcluded ? AppColors.surface : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExcluded
                ? AppColors.phRed
                : isSelected
                    ? AppColors.phBlue
                    : AppColors.border,
            width: (isSelected || isExcluded) ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.phBlue.withValues(alpha: 0.12),
                    spreadRadius: 2,
                  ),
                ]
              : isExcluded
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
        ),
        child: Opacity(
          opacity: isExcluded ? 0.6 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senator.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isExcluded ? AppColors.muted : AppColors.ink,
                            decoration: isExcluded
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (senator.party.isNotEmpty && senator.party != '—') ...[
                          const SizedBox(height: 2),
                          Text(
                            senator.party,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.faint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status Icon
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isExcluded
                          ? AppColors.phRed
                          : isSelected
                              ? AppColors.phBlue
                              : Colors.transparent,
                      border: Border.all(
                        color: isExcluded
                            ? AppColors.phRed
                            : isSelected
                                ? AppColors.phBlue
                                : AppColors.borderStrong,
                        width: 1.5,
                      ),
                    ),
                    child: isExcluded
                        ? const Icon(Icons.block, size: 12, color: Colors.white)
                        : isSelected
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  if (senator.authored > 0 && !isExcluded) ...[
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
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
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
