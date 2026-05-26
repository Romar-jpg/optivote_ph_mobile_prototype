import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'app_colors.dart';
import 'senator_card.dart';
import 'optimizer_engine.dart';
import 'senator_profile.dart';

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
  List<Senator>? _allSenators;
  final Set<String> _selectedSectors = {};
  bool _isLoading = true;
  final GlobalKey<_OptimizerScreenState> _optimizerKey = GlobalKey<_OptimizerScreenState>();

  final List<Map<String, dynamic>> _sectorDefinitions = [
    {
      'key': 'Social Services',
      'label': 'Social Services & Human Development',
      'desc': 'Welfare, health & social protection',
      'icon': Icons.volunteer_activism_outlined,
    },
    {
      'key': 'Education',
      'label': 'Education, Science & Culture',
      'desc': 'Schools, research & cultural heritage',
      'icon': Icons.school_outlined,
    },
    {
      'key': 'Economy',
      'label': 'Economy, Finance & Labor',
      'desc': 'Jobs, trade & fiscal policy',
      'icon': Icons.payments_outlined,
    },
    {
      'key': 'Infrastructure',
      'label': 'Infrastructure & Public Services',
      'desc': 'Transport, utilities & public works',
      'icon': Icons.construction_outlined,
    },
    {
      'key': 'Agriculture',
      'label': 'Agriculture & Environment',
      'desc': 'Food security & natural resources',
      'icon': Icons.agriculture_outlined,
    },
    {
      'key': 'Justice',
      'label': 'Justice, Law & Security',
      'desc': 'Legal reform, safety & human rights',
      'icon': Icons.gavel_outlined,
    },
    {
      'key': 'Governance',
      'label': 'Governance & Internal Affairs',
      'desc': 'Public accountability & local govt',
      'icon': Icons.account_balance_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final String raw = await rootBundle.loadString('assets/senators_bill.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(raw);

    final senators = rows
        .skip(1)
        .where(
          (r) =>
              r.isNotEmpty && r[0] != null && r[0].toString().trim().isNotEmpty,
        )
        .map((r) {
          int authored = 0;
          int passed = 0;

          if (r.length > 4) {
            authored = _parseInt(r[3]);
            passed = _parseInt(r[4]);
          }

          final sectorPassed = <String, int>{};
          if (r.length > 11) {
            sectorPassed['Social Services'] = _parseInt(r[5]);
            sectorPassed['Education'] = _parseInt(r[6]);
            sectorPassed['Economy'] = _parseInt(r[7]);
            sectorPassed['Infrastructure'] = _parseInt(r[8]);
            sectorPassed['Agriculture'] = _parseInt(r[9]);
            sectorPassed['Justice'] = _parseInt(r[10]);
            sectorPassed['Governance'] = _parseInt(r[11]);
          }

          double w = 0.9;
          if (authored > 0) {
            w = 1.0 - (passed / authored);
            if (w < 0.1) w = 0.1;
          }

          return Senator(
            name: r[0].toString().trim(),
            party: '—',
            authored: authored,
            passed: passed,
            v: passed.toDouble(),
            w: double.parse(w.toStringAsFixed(2)),
            sectorPassed: sectorPassed,
          );
        })
        .toList();

    senators.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _allSenators = senators;
      _isLoading = false;
    });
  }

  int _parseInt(dynamic val) {
    if (val == null) return 0;
    String s = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s)?.toInt() ?? 0;
  }

  void _toggleSector(String sector) {
    setState(() {
      if (_selectedSectors.contains(sector)) {
        _selectedSectors.remove(sector);
      } else {
        _selectedSectors.add(sector);
      }
      _updateSenatorValues();
    });
  }

  void _updateSenatorValues() {
    if (_allSenators == null) return;
    for (var senator in _allSenators!) {
      if (_selectedSectors.isEmpty) {
        senator.v = senator.passed.toDouble();
      } else {
        int sum = 0;
        for (var s in _selectedSectors) {
          sum += senator.sectorPassed[s] ?? 0;
        }
        senator.v = sum.toDouble();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.phBlue),
            )
          : OptimizerScreen(
              key: _optimizerKey,
              senators: _allSenators ?? [],
              selectedSectors: _selectedSectors,
            ),
      BillSectorsScreen(
        selectedSectors: _selectedSectors,
        sectorDefinitions: _sectorDefinitions,
        onToggle: _toggleSector,
      ),
      const HowItWorksScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Row(
          children: [
            Image.asset(
              'assets/OVPH-transparent.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'Opti'),
                  TextSpan(
                    text: 'vote ',
                    style: TextStyle(
                      color: AppColors.phGold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextSpan(text: 'PH'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              tooltip: 'View Slate',
              icon: const Icon(Icons.format_list_numbered, color: AppColors.phGold),
              onPressed: () {
                _optimizerKey.currentState?.showSlate(context);
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: AppColors.phGold, height: 3.0),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
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
  final List<Senator> senators;
  final Set<String> selectedSectors;

  const OptimizerScreen({
    super.key,
    required this.senators,
    required this.selectedSectors,
  });

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  final Set<int> _selectedIndices = {};
  final Set<int> _excludedIndices = {};
  final Set<int> _yellowIndices = {};
  List<Senator>? _localSenatorList;

  // Tracker for the background thread calculation
  bool _isOptimizing = false;

  @override
  void didUpdateWidget(OptimizerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.senators != oldWidget.senators ||
        widget.selectedSectors != oldWidget.selectedSectors) {
      setState(() {
        _localSenatorList = null;
        _selectedIndices.clear();
        _excludedIndices.clear();
        _yellowIndices.clear();
      });
    }
  }

  List<Senator> get _senatorList {
    return _localSenatorList ?? widget.senators;
  }

  double get _currentWeight {
    return _selectedIndices.fold(
      0.0,
      (sum, index) => sum + _senatorList[index].w,
    );
  }

  void _toggleSelection(int index, Senator senator) {
    if (senator.authored == 0 || _excludedIndices.contains(index)) return;

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
        _yellowIndices.remove(index);
      }
    });
  }

  void _toggleExclusion(int index) {
    setState(() {
      if (_excludedIndices.contains(index)) {
        _excludedIndices.remove(index);
      } else {
        _selectedIndices.remove(index); // Remove from selection if excluded
        _yellowIndices.remove(index); // Remove from yellow recommendation if excluded
        _excludedIndices.add(index);
      }
    });
  }

  void _showSenatorActions(int index, Senator senator) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isExcluded = _excludedIndices.contains(index);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  senator.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  isExcluded ? Icons.add_circle_outline : Icons.block_flipped,
                  color: isExcluded ? AppColors.success : AppColors.phRed,
                ),
                title: Text(
                  isExcluded
                      ? "Include in Optimizer"
                      : "Exclude from Optimizer",
                  style: TextStyle(
                    color: isExcluded ? AppColors.success : AppColors.phRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleExclusion(index);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_search_outlined,
                  color: AppColors.phBlue,
                ),
                title: const Text(
                  "View Senator Profile",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SenatorProfileScreen(senator: senator),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void showSlate(BuildContext context) {
    final selected = _selectedIndices.toList()..sort();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No senators selected yet.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.how_to_vote, color: AppColors.phBlue, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Your Slate  (${selected.length} / 12)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const Spacer(),
                        if (_yellowIndices.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.phGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.phGold, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8,
                                  decoration: const BoxDecoration(color: AppColors.phGold, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Text('Recommended', style: TextStyle(fontSize: 10, color: AppColors.navy, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 20, indent: 20, endIndent: 20),
                  // List
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selected.length,
                      itemBuilder: (context, rank) {
                        final idx = selected[rank];
                        final senator = _senatorList[idx];
                        final isYellow = _yellowIndices.contains(idx);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isYellow ? AppColors.phGold : AppColors.phBlue,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isYellow ? AppColors.phGold : AppColors.phBlue).withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Rank badge
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isYellow
                                      ? AppColors.phGold.withValues(alpha: 0.15)
                                      : AppColors.phBlue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${rank + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isYellow ? AppColors.navy : AppColors.phBlue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                                      'V = ${senator.v}  ·  W = ${senator.w}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isYellow)
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.phGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _resetSelection() {
    setState(() {
      _selectedIndices.clear();
      _excludedIndices.clear();
      _yellowIndices.clear();
      _localSenatorList = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    double weightPct = (_currentWeight / 9.0).clamp(0.0, 1.0);
    bool isOverWeight = _currentWeight > 9.0;

    return Column(
      children: [
        if (widget.selectedSectors.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.phBlue.withValues(alpha: 0.05),
            width: double.infinity,
            child: Text(
              "Focus: ${widget.selectedSectors.join(', ')}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.phBlue,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade50,
          child: const Text(
            "Tap to select. Long-press to exclude from optimizer or view profile.",
            style: TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On mobile screens (width < 600), use a ListView to allow cards to
              // size themselves dynamically and avoid vertical layout overflows.
              if (constraints.maxWidth < 600) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _senatorList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final senator = _senatorList[index];
                    return SenatorCard(
                      senator: senator,
                      isSelected: _selectedIndices.contains(index),
                      isExcluded: _excludedIndices.contains(index),
                      isYellow: _yellowIndices.contains(index),
                      onTap: () => _toggleSelection(index, senator),
                      onLongPress: () => _showSenatorActions(index, senator),
                    );
                  },
                );
              } else {
                // On wider screens (tablets/desktops), display in a multi-column grid
                // with a slightly larger mainAxisExtent to accommodate wrapped pills.
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 145,
                  ),
                  itemCount: _senatorList.length,
                  itemBuilder: (context, index) {
                    final senator = _senatorList[index];
                    return SenatorCard(
                      senator: senator,
                      isSelected: _selectedIndices.contains(index),
                      isExcluded: _excludedIndices.contains(index),
                      isYellow: _yellowIndices.contains(index),
                      onTap: () => _toggleSelection(index, senator),
                      onLongPress: () => _showSenatorActions(index, senator),
                    );
                  },
                );
              }
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
                color: Colors.black.withValues(alpha: 0.05),
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
                        onPressed: _isOptimizing
                            ? null
                            : () async {
                                final eligible = _senatorList
                                    .asMap()
                                    .entries
                                    .where(
                                      (entry) =>
                                          entry.value.authored > 0 &&
                                          !_excludedIndices.contains(entry.key),
                                    )
                                    .map((entry) => entry.value)
                                    .toList();

                                if (eligible.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No eligible senators to optimize.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _isOptimizing = true;
                                });

                                final result = await compute(
                                  runOptimizerInBackground,
                                  {
                                    'eligible': eligible,
                                    'cap': 9.0,
                                    'maxCount': 12,
                                  },
                                );

                                setState(() {
                                  _isOptimizing = false;
                                  
                                  List<Senator> winners = result.optimalSlate;
                                  _yellowIndices.clear();

                                  // If the constrained search yields fewer than 12 candidates,
                                  // we run an unconstrained optimizer to get the best 12-senator slate
                                  // and highlight the candidates that caused the 9.0 cap to be exceeded.
                                  if (winners.length < 12) {
                                    final unconstrainedResult = OptimizerEngine.runOptimizer(
                                      eligible,
                                      999.0, // Effectively unconstrained by weight
                                      12,
                                    );
                                    winners = unconstrainedResult.optimalSlate;

                                    _selectedIndices.clear();
                                    double runningWeight = 0.0;
                                    for (int i = 0; i < winners.length; i++) {
                                      final senator = winners[i];
                                      if (runningWeight + senator.w <= 9.0) {
                                        runningWeight += senator.w;
                                        _selectedIndices.add(i);
                                      } else {
                                        _selectedIndices.add(i);
                                        _yellowIndices.add(i);
                                      }
                                    }
                                  } else {
                                    _selectedIndices.clear();
                                    for (int i = 0; i < winners.length; i++) {
                                      _selectedIndices.add(i);
                                    }
                                  }

                                  final excludedNames = _excludedIndices
                                      .map((i) => _senatorList[i].name)
                                      .toSet();

                                  final excludedSenators = _senatorList
                                      .where(
                                        (s) => excludedNames.contains(s.name),
                                      )
                                      .toList();

                                  final remainingEligible = _senatorList
                                      .where(
                                        (s) =>
                                            !winners.contains(s) &&
                                            !excludedNames.contains(s.name) &&
                                            s.authored > 0,
                                      )
                                      .toList();

                                  final remainingIneligible = _senatorList
                                      .where(
                                        (s) =>
                                            !winners.contains(s) &&
                                            !excludedNames.contains(s.name) &&
                                            s.authored == 0,
                                      )
                                      .toList();

                                  // Sort remaining eligible by value/weight ratio descending, then dynamic value (v) descending as tie-breaker
                                  remainingEligible.sort((a, b) {
                                    final ratioA = a.v / (a.w == 0 ? 0.001 : a.w);
                                    final ratioB = b.v / (b.w == 0 ? 0.001 : b.w);
                                    int cmp = ratioB.compareTo(ratioA);
                                    if (cmp != 0) return cmp;
                                    return b.v.compareTo(a.v);
                                  });

                                  final remainingSenators = [
                                    ...remainingEligible,
                                    ...remainingIneligible,
                                  ];

                                  _localSenatorList = [
                                    ...winners,
                                    ...remainingSenators,
                                    ...excludedSenators,
                                  ];

                                  _excludedIndices.clear();
                                  int startIndexForExclusion =
                                      winners.length + remainingSenators.length;
                                  for (
                                    int i = 0;
                                    i < excludedSenators.length;
                                    i++
                                  ) {
                                    _excludedIndices.add(
                                      startIndexForExclusion + i,
                                    );
                                  }

                                  final numWinners = result.optimalSlate.length;
                                  final numYellow = _yellowIndices.length;
                                  String msg = 'Optimal Slate Found! Value: ${result.totalValue} | W: ${result.totalWeight.toStringAsFixed(2)}';
                                  if (numWinners < 12 && numYellow > 0) {
                                    msg += ' (Completed 12-slate with $numYellow recommended candidate${numYellow > 1 ? "s" : ""})';
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                });
                              },
                        icon: _isOptimizing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow, size: 18),
                        label: Text(
                          _isOptimizing ? 'Calculating...' : 'Run Optimizer',
                        ),
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
                        side: const BorderSide(color: AppColors.borderStrong),
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
  }
}

// ── TAB 2: BILL SECTORS ───────────────────────────────────────
class BillSectorsScreen extends StatelessWidget {
  final Set<String> selectedSectors;
  final List<Map<String, dynamic>> sectorDefinitions;
  final Function(String) onToggle;

  const BillSectorsScreen({
    super.key,
    required this.selectedSectors,
    required this.sectorDefinitions,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                "Select Priorities",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose the sectors that matter most to you to tailor the productivity data and candidate alignment scores.",
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: sectorDefinitions.length,
                itemBuilder: (context, index) {
                  final def = sectorDefinitions[index];
                  final isSelected = selectedSectors.contains(def['key']);
                  return _buildSectorCard(def, isSelected);
                },
              ),
              const SizedBox(height: 32),
              _buildDataProfile(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectorCard(Map<String, dynamic> def, bool isSelected) {
    return GestureDetector(
      onTap: () => onToggle(def['key']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.phBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.phBlue : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.phBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                def['icon'],
                color: isSelected ? Colors.white : AppColors.phBlue,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              def['label'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              def['desc'],
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.phBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Data Profile",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  "Sectors selected: ${selectedSectors.length}",
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TAB 3: HOW IT WORKS (PLACEHOLDER) ──────────────────────────
// ── TAB 3: HOW IT WORKS ──────────────────────────
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/OVPH-transparent.png',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                const Text(
                  "About the Project",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Explore the story behind our goal of cutting through disinformation and the algorithmic process that powers this tool.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // NEW: Quick Start Guide right at the top
          _buildQuickStartCard(),

          // UPDATED: The Problem (Now with paragraph breaks!)
          _buildAboutCard(
            "The Problem",
            "The Philippines has been labeled \"Patient Zero\" for global disinformation as the 2016 elections first demonstrated how coordinated fake news and troll farms could be used to manipulate public opinion.\n\nThis crisis specifically targets voters who may have limited access to reliable news, leading many to choose candidates based on fame or emotional appeal rather than actual performance.\n\nTo combat this, Optivote PH was developed as a data-driven tool that uses mathematical algorithms to cut through the noise of propaganda. By analyzing official Senate records, this tool helps voters identify high-performing legislators, create objective, merit-based results, and restore the integrity of the democratic process.",
          ),

          _buildAboutCard(
            "The Process & Algorithm",
            "How does Optivote PH turn raw data into an optimized slate? There are five primary steps in calculating the best combination of senators based on their records and your chosen priorities.",
            extra: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildAlgorithmStep(
                  "1",
                  "The tool gathers official records and allows you to select specific bill categories (sectors). It filters the productivity data to focus only on the issues you care about most.",
                ),
                _buildAlgorithmStep(
                  "2",
                  "Using those filtered metrics, it applies the Branch and Bound Approach to the 0/1 Knapsack Problem. It finds the best possible group of twelve that stays under the inefficiency limit of 9.0.",
                ),
                _buildAlgorithmStep(
                  "3",
                  "If the strict weight cap prevents a full 12-person slate, the optimizer automatically runs a second unconstrained pass to identify the best remaining candidates needed to complete the 12 slots. These \"recommended\" picks are highlighted with a gold border to distinguish them from the purely optimal picks.",
                ),
                _buildAlgorithmStep(
                  "4",
                  "Once the slate is assembled, the tool applies Shaker Sort to rank the winners from highest to lowest legislative value in your chosen category.",
                ),
                _buildAlgorithmStep(
                  "5",
                  "The tool presents your ranked Top 12 list as a verifiable, merit-based cheat sheet. Tap the list icon in the top-right to open the Slate Viewer for a clean, scrollable summary of your chosen senators.",
                ),
              ],
            ),
          ),

          _buildAboutCard(
            "Scope & Limitations",
            "Optivote PH focuses on creating an optimized Top 12 senatorial list by looking strictly at how effective candidates are at passing laws. Each candidate is assigned a value based on their legislative efficiency ratio. By treating the twelve available ballot slots like a backpack with a limited capacity (the Knapsack Problem), the tool mathematically picks the group of senators that offers the highest combined success rate.\n\nWhen the strict 9.0 inefficiency weight cap prevents a fully optimal 12-person slate, the tool automatically completes the list using a secondary unconstrained optimization pass. Candidates added this way are clearly marked with a gold border, signaling they are strong recommendations who fall just outside the hard constraint — giving voters a complete, usable ballot every time.\n\nHowever, there are a few limitations to keep in mind. First, the tool only works for incumbent or returning senators as it requires historical data from the official Senate database. New candidates will not have a record. Second, it is strictly data-driven and ignores subjective factors like social media popularity, public approval ratings, or a candidate's celebrity status. Finally, the system focuses on legislative output and bill success rates rather than the quality or political ideology of the laws themselves.",
          ),

          _buildAboutCard(
            "The Development Team",
            "We are second-year Bachelor of Science in Computer Science students from PUP Sta. Mesa (SY 2025–2026), dedicated to creating data-driven solutions for modern challenges. This website serves as our final project for the Design and Analysis of Algorithms course, developed under the guidance of Professor Ria Sagum. By applying algorithm designs and techniques from our lectures to real-world legislative data, we aim to provide the electorate with a more objective perspective on governance.",
            extra: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  "Meet the team behind the project with their GitHub usernames:",
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      _buildTeamMember("Cilon, Rachel Anne", "@rachelannec"),
                      _buildTeamMember(
                        "Cusipag, Julian Lawrence M.",
                        "@JRenMC",
                      ),
                      _buildTeamMember("Gallaza, Romar M.", "@Romar-jpg"),
                      _buildTeamMember(
                        "Javines, Kathy Nicole E.",
                        "@kn24javines-dev",
                      ),
                      _buildTeamMember(
                        "Mendoza, Aaron Kerk P.",
                        "@lhadypirena",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // NEW HELPER WIDGET: The Quick Start Card
  Widget _buildQuickStartCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.phBlue.withValues(alpha: 0.05), // Subtle blue tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.phBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: AppColors.phBlue),
              SizedBox(width: 8),
              Text(
                "How to Use Optivote PH",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAlgorithmStep(
            "1",
            "Go to the Sectors tab and select the issues you care about most.",
          ),
          _buildAlgorithmStep(
            "2",
            "Review candidate records in the Optimizer tab.",
          ),
          _buildAlgorithmStep(
            "3",
            "Long-press any senator to exclude them or view their full profile.",
          ),
          _buildAlgorithmStep(
            "4",
            "Tap Run Optimizer to calculate your perfect 12-person slate.",
          ),
          _buildAlgorithmStep(
            "5",
            "Tap the list icon (⊟) in the top-right to open the Slate Viewer — a scrollable summary of your selected 12 senators ranked by productivity.",
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(String title, String content, {Widget? extra}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
          // ignore: use_null_aware_elements
          if (extra != null) extra,
        ],
      ),
    );
  }

  Widget _buildAlgorithmStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.phBlue,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String github) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Text(
            github,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.phBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} // <-- HowItWorksScreen ends correctly right here

// ── ISOLATE HELPER FUNCTION ───────────────────────────────────
// This MUST be a top-level function (outside any class) so Flutter
// can spawn it on a separate background thread.
OptimizerResult runOptimizerInBackground(Map<String, dynamic> args) {
  return OptimizerEngine.runOptimizer(
    args['eligible'] as List<Senator>,
    args['cap'] as double,
    args['maxCount'] as int,
  );
}
