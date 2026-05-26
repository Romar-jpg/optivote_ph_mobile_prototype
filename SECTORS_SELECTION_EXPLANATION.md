# Optivote-PH: Multi-Sector Selection Mechanics

This document explains the step-by-step logic, calculations, and code workflow when a user selects **more than one bill sector** (e.g., choosing both **Social Services** and **Education**) in the Optivote-PH application.

---

## 1. High-Level Flow Chart

```mermaid
graph TD
    A[User selects multiple sectors on UI grid] --> B[State updates: _selectedSectors Set populated]
    B --> C[Call _updateSenatorValues]
    C --> D[Loop through each Senator]
    D --> E{Are selectedSectors empty?}
    E -- No --> F[V = sum of bills passed in selected sectors]
    E -- Yes --> G[V = total bills passed overall]
    F --> H[Update Senator Card UI dynamically]
    G --> H
    H --> I[User taps Run Optimizer]
    I --> J[Pass 1: B&B with cap=9.0 and maxCount=12]
    J --> K{Slate has 12 senators?}
    K -- Yes --> M[Apply Shaker Sort by V descending]
    K -- No --> L[Pass 2: B&B unconstrained cap=999.0]
    L --> N[Simulate running weight to flag recommended picks]
    N --> M
    M --> O[Display slate: optimal picks in blue, recommended picks in gold border]
```

---

## 2. Dynamic Value Recalculation ($V$)

A senator's productivity value ($V$) is dynamic. When a user selects multiple sectors, the value $V$ is calculated by summing the bill counts passed by that senator **only** in the selected sectors. 

### The Formula:
$$V = \sum_{s \in S} \text{SectorPassed}[s]$$

Where:
* $S$ is the set of user-selected sectors.
* $\text{SectorPassed}[s]$ is the number of bills the senator has passed in sector $s$.

---

## 3. Concrete Numerical Example

Let's trace what happens to **Senator Pia S. Cayetano**'s data when multiple sectors are selected.

### Historical Record in the Database:
* **Social Services & Human Development**: `103` bills passed
* **Education, Science & Culture**: `32` bills passed
* **Economy, Finance & Labor**: `39` bills passed
* **Total Bills Passed (All Sectors)**: `97` *(Note: database entries for sector breakdowns can exceed overall main bills passed counts due to cross-category indexing or co-sponsorship counting)*

---

### Scenario A: No Sectors Selected (Default)
The value $V$ defaults to the total bills passed:
$$V = \text{Passed} = 97$$

---

### Scenario B: "Social Services" Selected
The value $V$ becomes:
$$V = \text{Social Services Passed} = 103$$

---

### Scenario C: "Social Services" AND "Education" Selected
The value $V$ is aggregated:
$$V = \text{Social Services Passed} + \text{Education Passed}$$
$$V = 103 + 32 = 135$$

*Any bills passed in the unselected "Economy" category (39 bills) are ignored ($0$ value).*

---

## 4. Code Implementation

This mechanism is handled by the `_updateSenatorValues()` function in [main.dart](file:///c:/Users/lenovo/StudioProjects/optivote_ph_mobile_prototype/lib/main.dart):

```dart
void _updateSenatorValues() {
  if (_allSenators == null) return;
  for (var senator in _allSenators!) {
    if (_selectedSectors.isEmpty) {
      // Default: Use total passed bills
      senator.v = senator.passed.toDouble();
    } else {
      // Multi-sector: Sum only the selected sectors
      int sum = 0;
      for (var s in _selectedSectors) {
        sum += senator.sectorPassed[s] ?? 0;
      }
      senator.v = sum.toDouble();
    }
  }
}
```

---

## 5. Impact on the Optimization Engine

When multiple sectors are selected, the Senator's value ($V$) increases, which directly alters their **Value-to-Weight ratio** ($\frac{V}{W}$):

1. **Increased Priority**: A candidate who performs exceptionally well in *both* of the selected sectors will receive a high accumulated $V$, boosting their $\frac{V}{W}$ ratio.
2. **Greedy Sorting Order**: The optimizer sorts candidates by $\frac{V}{W}$ in descending order at the beginning of the algorithm:
   ```dart
   sorted.sort((a, b) => (b.v / b.w).compareTo(a.v / a.w));
   ```
   This ensures that candidates who align strongly with the user's multiple priorities are evaluated first, setting a higher bound and ensuring they are more likely to make it into the final recommended slate.

---

## 6. Sector Selection & the Two-Pass Slate Completion

Sector selection can also influence **which candidates are marked as recommended** (gold border) in the two-pass slate completion introduced in v1.1.0.

### Why This Happens
The dynamic $V$ value shifts the **Value-to-Weight ratio** ($\frac{V}{W}$) of each senator. When a user chooses a highly specific sector (e.g., only **Agriculture**), many senators with strong overall records but weak agricultural output will see their $V$ drop significantly. This can push more candidates below the 9.0 weight cap feasibility threshold, making it more likely that Pass 2 (unconstrained) is needed to complete the 12-person slate.

### Practical Effect

| Scenario | Effect on Slate Completion |
|---|---|
| **No sectors selected** | Full dataset $V$ values. Unlikely to need Pass 2. |
| **1–2 broad sectors selected** | Moderate $V$ redistribution. Pass 2 may occasionally activate. |
| **Narrow or single niche sector** | Many senators score near $V = 0$. Pass 2 more likely to activate to complete slate. |

### What the User Sees
Optimal senators (whose cumulative $W$ fits within 9.0) are shown with a **blue border**. Candidates that complete the 12-slate but would exceed the cap are shown with a **gold border**, clearly marking them as the best available picks given the constraint.

The **Slate Viewer** (accessible via the list icon ⊟ in the top-right AppBar) shows the full ranked list, with gold dots marking recommended picks and a "Recommended" pill badge in the header when any such candidates are present.
