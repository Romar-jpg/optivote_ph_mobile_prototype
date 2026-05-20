import 'dart:math';

// 1. The Senator Data Model
class Senator {
  final String name;
  final String party;
  final int authored;
  final int passed;
  double v; // Productivity Value (can be weighted by sectors)
  final double w; // Inefficiency Weight
  final Map<String, int> sectorPassed;

  Senator({
    required this.name,
    required this.party,
    required this.authored,
    required this.passed,
    required this.v,
    required this.w,
    required this.sectorPassed,
  });
}

// 2. A helper class to return the results
class OptimizerResult {
  final List<Senator> optimalSlate;
  final double totalValue;
  final double totalWeight;

  OptimizerResult(this.optimalSlate, this.totalValue, this.totalWeight);
}

// 3. The Algorithm Engine (Make sure it is capitalized exactly like this!)
class OptimizerEngine {
  // The Branch & Bound upper bound estimator
  static double _upperBound(
    List<Senator> items,
    int idx,
    int count,
    double curW,
    double curV,
    double cap,
    int maxCount,
  ) {
    if (curW > cap || count > maxCount) return 0.0;

    double bound = curV;
    double w = curW;
    int c = count;

    for (int i = idx; i < items.length; i++) {
      if (c >= maxCount) break;
      if (w + items[i].w <= cap) {
        w += items[i].w;
        bound += items[i].v;
        c++;
      } else {
        double rem = min(cap - w, (maxCount - c) * 9.0);
        bound += items[i].v * (rem / max(items[i].w, 0.001));
        break;
      }
    }
    return bound;
  }

  // The main 0/1 Knapsack Branch & Bound runner
  static OptimizerResult runOptimizer(
    List<Senator> eligible,
    double cap,
    int maxCount,
  ) {
    // Sort by value/weight ratio descending to optimize pruning
    List<Senator> sorted = List.from(eligible);
    sorted.sort((a, b) => (b.v / b.w).compareTo(a.v / a.w));

    double bestV = 0;
    List<int> bestChosen = [];

    // Recursive Branch & Bound function
    void bb(int idx, int count, double curW, double curV, List<int> chosen) {
      if (count == maxCount && curW <= cap) {
        if (curV > bestV) {
          bestV = curV;
          bestChosen = List.from(chosen);
        }
        return;
      }
      if (idx >= sorted.length) {
        if (curW <= cap && curV > bestV) {
          bestV = curV;
          bestChosen = List.from(chosen);
        }
        return;
      }

      double bound = _upperBound(sorted, idx, count, curW, curV, cap, maxCount);
      if (bound <= bestV) return; // Prune branch

      Senator item = sorted[idx];

      // Path 1: Include item
      if (count < maxCount && (curW + item.w) <= cap) {
        chosen.add(idx);
        bb(idx + 1, count + 1, curW + item.w, curV + item.v, chosen);
        chosen.removeLast();
      }

      // Path 2: Exclude item
      bb(idx + 1, count, curW, curV, chosen);
    }

    bb(0, 0, 0.0, 0.0, []);

    // Retrieve the best senators from the indices
    List<Senator> optimalSlate = bestChosen.map((i) => sorted[i]).toList();

    // Apply Shaker Sort (Bidirectional Bubble Sort) by Value descending
    _shakerSort(optimalSlate);

    double totalW = optimalSlate.fold(0.0, (sum, s) => sum + s.w);
    return OptimizerResult(optimalSlate, bestV, totalW);
  }

  // Sorts the final slate highest to lowest
  static void _shakerSort(List<Senator> arr) {
    bool swapped = true;
    int left = 0;
    int right = arr.length - 1;

    while (swapped) {
      swapped = false;
      for (int i = left; i < right; i++) {
        if (arr[i].v < arr[i + 1].v) {
          final temp = arr[i];
          arr[i] = arr[i + 1];
          arr[i + 1] = temp;
          swapped = true;
        }
      }
      right--;
      for (int i = right; i > left; i--) {
        if (arr[i].v > arr[i - 1].v) {
          final temp = arr[i];
          arr[i] = arr[i - 1];
          arr[i - 1] = temp;
          swapped = true;
        }
      }
      left++;
    }
  }
}
