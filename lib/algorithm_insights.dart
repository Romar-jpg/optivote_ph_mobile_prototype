import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'optimizer_engine.dart';

class AlgorithmInsightsScreen extends StatelessWidget {
  final OptimizerResult? result;
  final int eligibleCount;

  const AlgorithmInsightsScreen({
    super.key,
    required this.result,
    required this.eligibleCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Algorithm Diagnostics'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveDiagnosticsCard(context),
            const SizedBox(height: 24),
            _buildDAATheorySection(),
            const SizedBox(height: 24),
            _buildSortingTheorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDiagnosticsCard(BuildContext context) {
    final liveResult = result;

    if (liveResult == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.faint,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Live Stats Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to the Optimizer tab and tap "Run Optimizer" to solve the knapsack problem and see real-time performance analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate Search Space Saved: Brute force is 2^N states.
    final int n = eligibleCount;
    String searchSpaceSaved = '99.9%';
    if (n < 62) {
      final double totalStates = n > 0 ? (1.0 * (1 << n.clamp(0, 30))) : 1.0;
      if (totalStates > 0) {
        final double ratio = liveResult.nodesExplored / totalStates;
        final double saved = (1.0 - ratio) * 100;
        searchSpaceSaved = saved > 99.999 ? '99.999%' : '${saved.toStringAsFixed(3)}%';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.phGold, size: 24),
              const SizedBox(width: 8),
              const Text(
                'LIVE EXECUTION STATS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Branch & Bound',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatDetail(
                'Time Elapsed',
                '${liveResult.executionTimeUs.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} μs',
                'Microseconds',
              ),
              _buildStatDetail(
                'Nodes Explored',
                '${liveResult.nodesExplored}',
                'States visited',
              ),
              _buildStatDetail(
                'Space Pruned',
                searchSpaceSaved,
                'Tree skipped',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Solver evaluated $n candidates and pruned ${liveResult.branchesPruned} sub-optimal branches using the Fractional Knapsack bounding function.',
                  style: const TextStyle(fontSize: 11, color: Colors.white60, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: const TextStyle(fontSize: 9, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildDAATheorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: AppColors.phBlue, size: 24),
              SizedBox(width: 8),
              Text(
                '0/1 Knapsack & Branch & Bound',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'The Optimization Problem',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'We model ballot selection as a 0/1 Knapsack Problem. The 12 ballot slots represent a knapsack with an inefficiency weight limit (W ≤ 9.0). Our goal is to select a subset of candidates to maximize the cumulative legislative value (V) without exceeding the weight limit.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Branch & Bound Paradigm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Brute force takes O(2^N) exponential time. Branch & Bound searches the state-space tree but prunes subtrees by calculating an upper bound at each node using the Fractional Knapsack algorithm (which runs in greedy O(N log N) time). If a subtree\'s best theoretical value is less than our current best solution, we discard (prune) the entire branch immediately.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingTheorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sort_by_alpha, color: AppColors.phBlue, size: 24),
              SizedBox(width: 8),
              Text(
                'Shaker Sort (Bidirectional Bubble)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Ranking the Winners',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Once the optimal slate is found, we rank the candidates in descending order of performance using Shaker Sort.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Algorithm Mechanics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Shaker Sort is a variation of Bubble Sort that sorts in both directions in each pass: first moving left-to-right (bubbling the smallest values to the end), and then right-to-left (bubbling the largest values to the front). While it shares a worst-case O(N^2) time complexity, it minimizes passes and handles "turtles" (small values near the end of the array) much faster than standard Bubble Sort.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
