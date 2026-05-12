import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'app_colors.dart';
import 'senator_card.dart';
import 'optimizer_engine.dart'; // Make sure this file exists with the algorithm!

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: MainScreen()),
  );
}

// ── NAVIGATION SHELL ──────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OptimizerScreen(),
    const BillSectorsScreen(),
    const HowItWorksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'Opti'),
              TextSpan(
                text: 'Vote ',
                style: TextStyle(
                  color: AppColors.phGold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(text: 'PH'),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: AppColors.phGold, height: 3.0),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.phBlue,
        unselectedItemColor: AppColors.faint,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Optimizer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Sectors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

// ── TAB 1: OPTIMIZER SCREEN ───────────────────────────────────
class OptimizerScreen extends StatefulWidget {
  const OptimizerScreen({super.key});

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  late Future<List<Senator>> _senatorDataFuture;
  List<Senator>? _senatorList;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _senatorDataFuture = loadData();
  }

  Future<List<Senator>> loadData() async {
    final String raw = await rootBundle.loadString('assets/senators_bill.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(raw);

    return rows
        .skip(1)
        // 👇 THIS IS THE MAGIC LINE: It filters out Excel's empty rows!
        .where(
          (r) =>
              r.isNotEmpty && r[0] != null && r[0].toString().trim().isNotEmpty,
        )
        .map((r) {
          int authored = 0;
          int passed = 0;

          if (r.length > 4) {
            String aStr = r[3].toString().replaceAll(RegExp(r'[^0-9.]'), '');
            String pStr = r[4].toString().replaceAll(RegExp(r'[^0-9.]'), '');

            authored = double.tryParse(aStr)?.toInt() ?? 0;
            passed = double.tryParse(pStr)?.toInt() ?? 0;
          }

          double v = passed.toDouble();
          double w = 0.9;

          if (authored > 0) {
            w = 1.0 - (passed / authored);
            if (w < 0.1) w = 0.1;
          }

          return Senator(
            name: r[0].toString().trim(), // Trim added here just to be safe!
            party: '—',
            authored: authored,
            passed: passed,
            v: v,
            w: double.parse(w.toStringAsFixed(2)),
            sectors: ['Governance'],
          );
        })
        .toList();
  }

  // 👇 THIS IS THE MISSING PIECE YOU NEEDED! 👇
  double get _currentWeight {
    if (_senatorList == null) return 0.0;
    return _selectedIndices.fold(
      0.0,
      (sum, index) => sum + _senatorList![index].w,
    );
  }

  void _toggleSelection(int index, Senator senator) {
    if (senator.authored == 0) return;

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (_selectedIndices.length >= 12) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 12 senators per ballot.')),
          );
          return;
        }
        if (_currentWeight + senator.w > 9.0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Adding this senator exceeds the inefficiency weight cap (9.0).',
              ),
            ),
          );
          return;
        }
        _selectedIndices.add(index);
      }
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedIndices.clear();
      // Put the list back into alphabetical order by name!
      _senatorList?.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Senator>>(
      future: _senatorDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.phBlue),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No data found."));
        }

        _senatorList = snapshot.data!;
        double weightPct = (_currentWeight / 9.0).clamp(0.0, 1.0);
        bool isOverWeight = _currentWeight > 9.0;

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 135,
                ),
                itemCount: _senatorList!.length,
                itemBuilder: (context, index) {
                  final senator = _senatorList![index];
                  return SenatorCard(
                    senator: senator,
                    isSelected: _selectedIndices.contains(index),
                    onTap: () => _toggleSelection(index, senator),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'W: ${_currentWeight.toStringAsFixed(2)} / 9.00',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: weightPct,
                              backgroundColor: AppColors.border,
                              color: isOverWeight
                                  ? AppColors.phRed
                                  : AppColors.phBlue,
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedIndices.length} / 12',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            // 👇 ALGORITHM WIRED UP HERE 👇
                            onPressed: _senatorList == null
                                ? null
                                : () {
                                    final eligible = _senatorList!
                                        .where((s) => s.authored > 0)
                                        .toList();

                                    if (eligible.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No eligible senators to optimize.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Run the Branch & Bound Engine
                                    final result = OptimizerEngine.runOptimizer(
                                      eligible,
                                      9.0,
                                      12,
                                    );

                                    // Update the UI
                                    setState(() {
                                      // 1. Separate the winning slate from the rest of the senators
                                      final winners = result.optimalSlate;
                                      final theRest = _senatorList!
                                          .where((s) => !winners.contains(s))
                                          .toList();

                                      // 2. Rebuild the list: Ranked Winners at the top, everyone else below
                                      _senatorList = [...winners, ...theRest];

                                      // 3. Because the winners are now exactly at the top of the list,
                                      // we just highlight the first X items!
                                      _selectedIndices.clear();
                                      for (int i = 0; i < winners.length; i++) {
                                        _selectedIndices.add(i);
                                      }
                                    });

                                    // Show success banner
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Optimal Slate Found! Value: ${result.totalValue} | W: ${result.totalWeight.toStringAsFixed(2)}',
                                        ),
                                        backgroundColor: AppColors.success,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Run Optimizer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.phRed,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.borderStrong,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _resetSelection,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.muted,
                            side: const BorderSide(
                              color: AppColors.borderStrong,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── TAB 2: BILL SECTORS (PLACEHOLDER) ──────────────────────────
class BillSectorsScreen extends StatelessWidget {
  const BillSectorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Bill Sectors Content Goes Here",
        style: TextStyle(color: AppColors.muted, fontSize: 16),
      ),
    );
  }
}

// ── TAB 3: HOW IT WORKS (PLACEHOLDER) ──────────────────────────
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "How It Works Content Goes Here",
        style: TextStyle(color: AppColors.muted, fontSize: 16),
      ),
    );
  }
}
