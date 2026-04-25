'use strict';

const BASE = 'https://open-congress-api.bettergov.ph/api';

// ── Sector keyword map ──────────────────────────────────────────────
const SECTOR_RULES = [
  { sector: 'Education',      kw: ['education','school','tuition','student','curriculum','teacher','learning','literacy','academ','scholarship'] },
  { sector: 'Health',         kw: ['health','medical','hospital','medicine','disease','mental health','pandemic','vaccine','pharmaceu','nutrition','sanit'] },
  { sector: 'Agriculture',    kw: ['agri','farm','fisher','crop','livestock','rice','coconut','rural','food secur','irrigat'] },
  { sector: 'Infrastructure', kw: ['infrastructure','road','bridge','transport','highway','construct','urban','housing','water supply','sewage','electrif'] },
  { sector: 'Economy',        kw: ['econom','trade','tax','tariff','invest','fiscal','budget','finance','bank','business','industry','enterprise','market'] },
  { sector: 'Justice',        kw: ['justice','court','crime','anti-corruption','punish','penal','law enforce','illegal','drug','human right','civil right','legal'] },
  { sector: 'Environment',    kw: ['environment','climate','ecolog','forest','biodiversit','waste','pollution','water resource','natural resource','green'] },
  { sector: 'Social',         kw: ['social welfare','senior','child','women','family','poverty','disability','indigenous','OFW','overseas worker','barangay','community'] },
  { sector: 'Labor',          kw: ['labor','worker','employ','wage','OFW','livelihood','manpower','tesda','skill','occupat'] },
  { sector: 'Science',        kw: ['science','technolog','innovat','digital','information and communications','ICT','research','AI','cyber','space','DOST'] },
  { sector: 'Defense',        kw: ['defense','military','armed','security','police','coast guard','AFP','PNP','disaster','emergency','terrorism'] },
  { sector: 'Governance',     kw: ['government','governance','transparency','accountability','election','suffrage','autonomy','local government','congress','senate','constitution','bureaucra'] },
];

const SECTOR_CLASS = {
  Education:'st-edu', Health:'st-health', Agriculture:'st-agri', Infrastructure:'st-infra',
  Economy:'st-econ', Justice:'st-justice', Environment:'st-env', Social:'st-social',
  Labor:'st-labor', Science:'st-science', Defense:'st-defense', Governance:'st-gov'
};

function classifyBill(title='', subjects=[]) {
  const text = (title + ' ' + subjects.join(' ')).toLowerCase();
  const found = [];
  for (const rule of SECTOR_RULES) {
    if (rule.kw.some(k => text.includes(k))) {
      found.push(rule.sector);
      if (found.length >= 3) break;
    }
  }
  return found.length ? found : ['Governance'];
}

function sectorTag(s) {
  const cls = SECTOR_CLASS[s] || 'st-default';
  return `<span class="stag ${cls}">${s}</span>`;
}

// ── State ───────────────────────────────────────────────────────────
let senators = [];        // [{id, name, party, authored, passed, v, w, sectors, bills, selected}]
let optimalIdxs = [];
let activeSector = 'All';
let billsData = [];       // for Bills tab

// ── Tabs ────────────────────────────────────────────────────────────
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    btn.classList.add('active');
    const tab = btn.dataset.tab;
    document.getElementById('page-' + tab).classList.add('active');
    if (tab === 'bills') initBillsTab();
  });
});

// ── Fetch helpers ───────────────────────────────────────────────────
async function apiFetch(path) {
  const res = await fetch(BASE + path);
  if (!res.ok) throw new Error(`API ${res.status}: ${res.statusText}`);
  const json = await res.json();
  if (!json.success) throw new Error(json.error?.message || 'API error');
  return json.data;
}

async function fetchAllPaginated(path, paramSep='?') {
  const items = [];
  let offset = 0;
  const limit = 100;
  while (true) {
    const sep = path.includes('?') ? '&' : '?';
    const data = await fetch(BASE + path + sep + `limit=${limit}&offset=${offset}`)
      .then(r => r.json());
    if (!data.success) break;
    const chunk = Array.isArray(data.data) ? data.data : [];
    items.push(...chunk);
    if (!data.pagination?.has_more || chunk.length < limit) break;
    offset += limit;
  }
  return items;
}

// ── Load Senators ───────────────────────────────────────────────────
async function loadSenators() {
  const congress = document.getElementById('congressSelect').value;
  const loadBtn = document.getElementById('loadBtn');
  const runBtn  = document.getElementById('runBtn');
  const loader  = document.getElementById('gridLoader');
  const grid    = document.getElementById('candidateGrid');
  const err     = document.getElementById('optimizerError');
  const status  = document.getElementById('apiStatus');

  loadBtn.disabled = true;
  runBtn.disabled  = true;
  loader.style.display = 'block';
  grid.innerHTML = '';
  err.style.display = 'none';
  document.getElementById('resultsWrap').style.display = 'none';
  senators = [];
  optimalIdxs = [];
  updateStats();

  try {
    status.textContent = 'Fetching senators…';
    const senData = await apiFetch(`/congresses/${congress}/senators?limit=100`);
    const rawList = Array.isArray(senData) ? senData : (senData.senators || []);

    if (!rawList.length) throw new Error('No senators returned for this congress.');

    status.textContent = `Found ${rawList.length} senators. Fetching bills…`;

    // Fetch bills for each senator in parallel (batched)
    const BATCH = 6;
    const results = [];
    for (let i = 0; i < rawList.length; i += BATCH) {
      const batch = rawList.slice(i, i + BATCH);
      const batchResults = await Promise.allSettled(
        batch.map(async (sen) => {
          const billsRaw = await fetchAllPaginated(`/people/${sen.id}/bills?congress=${congress}&type=sb`);
          const authored = billsRaw.length;
          // Heuristic: "passed" = bills whose title starts with "AN ACT" or subjects include enacted language
          const passed = billsRaw.filter(b => {
            const t = (b.title || '').toUpperCase();
            return t.startsWith('AN ACT') || (b.subjects || []).some(s => /enacted|republic act/i.test(s));
          }).length;
          const sectors = [...new Set(billsRaw.flatMap(b => classifyBill(b.title, b.subjects || [])))].slice(0,4);
          return {
            id: sen.id,
            name: sen.full_name || `${sen.first_name || ''} ${sen.last_name || ''}`.trim(),
            party: sen.party || sen.aliases?.[0] || '—',
            authored,
            passed,
            v: passed,
            w: parseFloat(Math.max(0.1, authored > 0 ? 1 - (passed / authored) : 0.9).toFixed(2)),
            sectors,
            bills: billsRaw.slice(0, 20),
            selected: false,
          };
        })
      );
      batchResults.forEach((r, j) => {
        if (r.status === 'fulfilled') results.push(r.value);
        else results.push({
          id: batch[j].id,
          name: batch[j].full_name || `${batch[j].first_name || ''} ${batch[j].last_name || ''}`.trim(),
          party: '—', authored: 0, passed: 0, v: 0, w: 0.9,
          sectors: ['Governance'], bills: [], selected: false, noData: true
        });
      });
      status.textContent = `Loaded ${Math.min(i + BATCH, rawList.length)} / ${rawList.length} senators…`;
    }

    senators = results;
    billsData = results; // share with bills tab
    status.textContent = `✓ ${senators.length} senators loaded from Congress ${congress}`;
    document.getElementById('statTotal').textContent = senators.length;
    runBtn.disabled = false;
    renderGrid();

  } catch (e) {
    err.textContent = '⚠ ' + (e.message || 'Failed to load data. Check network or API availability.');
    err.style.display = 'block';
    status.textContent = '';
  } finally {
    loader.style.display = 'none';
    loadBtn.disabled = false;
  }
}

// ── Render Cards ────────────────────────────────────────────────────
function renderGrid() {
  const grid = document.getElementById('candidateGrid');
  if (!senators.length) { grid.innerHTML = '<div class="empty-state"><div class="empty-icon">📋</div>Load senators first.</div>'; return; }

  grid.innerHTML = senators.map((s, i) => `
    <div class="candidate-card ${s.selected ? 'selected' : ''} ${optimalIdxs.includes(i) ? 'optimal' : ''} ${s.noData ? 'no-data' : ''}"
         onclick="toggleCard(${i})" style="animation-delay:${Math.min(i * 18, 400)}ms">
      <div class="card-top">
        <div>
          <div class="card-name">${s.name}</div>
          <div class="card-party">${s.party}</div>
        </div>
        <div class="check-circle">
          <svg viewBox="0 0 10 8" fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="1,4 4,7 9,1"/>
          </svg>
        </div>
      </div>
      <div class="metrics-row">
        <span class="mpill mpill-neutral">Bills: ${s.authored}</span>
        ${s.authored > 0
          ? `<span class="mpill mpill-blue">V = ${s.v}</span><span class="mpill mpill-red">W = ${s.w.toFixed(2)}</span>`
          : `<span class="mpill mpill-gray">no bill data</span>`}
      </div>
      <div class="sectors-row">${s.sectors.map(sectorTag).join('')}</div>
    </div>
  `).join('');

  updateStats();
}

function toggleCard(i) {
  const s = senators[i];
  if (s.noData || s.authored === 0) return;
  const sel = senators.filter(x => x.selected);
  const totalW = sel.reduce((a, x) => a + x.w, 0);
  if (!s.selected) {
    if (sel.length >= 12) { alert('Maximum 12 senators per ballot.'); return; }
    if (+(totalW + s.w).toFixed(2) > 9.0) { alert('Adding this senator exceeds the inefficiency weight cap (9.0).'); return; }
  }
  s.selected = !s.selected;
  renderGrid();
}

function updateStats() {
  const sel = senators.filter(s => s.selected);
  const totalW = +sel.reduce((a, s) => a + s.w, 0).toFixed(2);
  const totalV = sel.reduce((a, s) => a + s.v, 0);
  document.getElementById('statSel').textContent = sel.length;
  document.getElementById('statVal').textContent = totalV;
  document.getElementById('weightLabel').textContent = `W: ${totalW.toFixed(2)} / 9.00`;
  document.getElementById('seatLabel').textContent = `${sel.length} / 12`;
  const pct = Math.min(100, (totalW / 9) * 100);
  const fill = document.getElementById('weightFill');
  fill.style.width = pct + '%';
  fill.className = 'weight-fill' + (totalW > 9 ? ' over' : '');
  if (sel.length > 0) {
    const avgEff = sel.reduce((a, s) => a + (s.authored > 0 ? s.passed / s.authored : 0), 0) / sel.length;
    document.getElementById('statEff').textContent = (avgEff * 100).toFixed(1) + '%';
  } else {
    document.getElementById('statEff').textContent = '—';
  }
}

function resetAll() {
  senators.forEach(s => s.selected = false);
  optimalIdxs = [];
  document.getElementById('resultsWrap').style.display = 'none';
  renderGrid();
}

// ── Branch & Bound ───────────────────────────────────────────────────
function upperBound(items, idx, count, curW, curV, cap, maxCount) {
  if (curW > cap || count > maxCount) return 0;
  let bound = curV, w = curW, c = count;
  for (let i = idx; i < items.length; i++) {
    if (c >= maxCount) break;
    if (w + items[i].w <= cap) { w += items[i].w; bound += items[i].v; c++; }
    else {
      const rem = Math.min(cap - w, (maxCount - c) * 9);
      bound += items[i].v * (rem / Math.max(items[i].w, 0.001));
      break;
    }
  }
  return bound;
}

function branchAndBound(items, cap, maxCount) {
  // Sort by value/weight ratio desc
  const sorted = items.map((s, i) => ({ ...s, origIdx: i }))
    .sort((a, b) => (b.v / b.w) - (a.v / a.w));

  let best = { v: 0, chosen: [] };
  let nodesExplored = 0, pruned = 0;

  function bb(idx, count, curW, curV, chosen) {
    nodesExplored++;
    if (count === maxCount && curW <= cap) {
      if (curV > best.v) best = { v: curV, chosen: [...chosen] };
      return;
    }
    if (idx >= sorted.length) {
      if (curW <= cap && curV > best.v) best = { v: curV, chosen: [...chosen] };
      return;
    }
    const bound = upperBound(sorted, idx, count, curW, curV, cap, maxCount);
    if (bound <= best.v) { pruned++; return; }

    const item = sorted[idx];
    // Include
    if (count < maxCount && +(curW + item.w).toFixed(4) <= cap) {
      bb(idx + 1, count + 1, +(curW + item.w).toFixed(4), curV + item.v, [...chosen, item.origIdx]);
    }
    // Exclude
    bb(idx + 1, count, curW, curV, chosen);
  }

  bb(0, 0, 0, 0, []);
  return { best, nodesExplored, pruned };
}

// ── Shaker Sort ──────────────────────────────────────────────────────
function shakerSort(arr) {
  let left = 0, right = arr.length - 1, swapped = true;
  const passes = [];
  while (swapped) {
    swapped = false;
    let passSwaps = 0;
    for (let i = left; i < right; i++) {
      if (arr[i].v < arr[i + 1].v) { [arr[i], arr[i + 1]] = [arr[i + 1], arr[i]]; swapped = true; passSwaps++; }
    }
    right--;
    for (let i = right; i > left; i--) {
      if (arr[i].v > arr[i - 1].v) { [arr[i], arr[i - 1]] = [arr[i - 1], arr[i]]; swapped = true; passSwaps++; }
    }
    left++;
    if (passSwaps > 0) passes.push(passSwaps);
  }
  return { sorted: arr, passes };
}

// ── Run Optimizer ────────────────────────────────────────────────────
function runOptimizer() {
  const eligible = senators.filter(s => s.authored > 0 && !s.noData);
  if (eligible.length === 0) { alert('No senators with bill data to optimize.'); return; }

  const runBtn = document.getElementById('runBtn');
  runBtn.disabled = true;
  runBtn.innerHTML = '<span style="font-size:11px">⏳</span> Running…';

  setTimeout(() => {
    const { best, nodesExplored, pruned } = branchAndBound(eligible, 9.0, 12);
    optimalIdxs = best.chosen.map(i => senators.indexOf(eligible[i]));
    senators.forEach((s, i) => s.selected = optimalIdxs.includes(i));

    const slateRaw = optimalIdxs.map(i => senators[i]);
    const { sorted, passes } = shakerSort([...slateRaw]);
    const totalV = sorted.reduce((a, s) => a + s.v, 0);
    const totalW = +sorted.reduce((a, s) => a + s.w, 0).toFixed(2);

    // Render log
    const log = document.getElementById('algoLog');
    log.innerHTML = [
      `<span class="log-info">» Branch & Bound complete</span>`,
      `  Nodes explored : ${nodesExplored}`,
      `  Branches pruned: ${pruned}`,
      `  Eligible items : ${eligible.length}`,
      `<span class="log-ok">» Optimal slate found — Value: ${best.v} | W: ${totalW.toFixed(2)}</span>`,
      `<span class="log-info">» Shaker Sort applied — ${passes.length} passes, swaps: [${passes.join(', ')}]</span>`,
      `  Final ranking  : ${sorted.map(s => s.name.split(' ').pop()).join(' → ')}`,
    ].join('\n');

    // Render slate
    const slateList = document.getElementById('slateList');
    slateList.innerHTML = sorted.map((s, i) => `
      <div class="slate-row">
        <div class="slate-rank">${i + 1}</div>
        <div class="slate-name">
          ${s.name}
          <small>${s.party}</small>
        </div>
        <div class="slate-tags">${s.sectors.map(sectorTag).join('')}</div>
        <div class="slate-meta">
          <div class="slate-v">V = ${s.v}</div>
          <div class="slate-w">W = ${s.w.toFixed(2)}</div>
        </div>
      </div>
    `).join('');

    document.getElementById('resultsWrap').style.display = 'block';
    renderGrid();
    document.getElementById('resultsWrap').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    runBtn.disabled = false;
    runBtn.innerHTML = '<svg width="13" height="13" viewBox="0 0 12 12" fill="currentColor"><path d="M3 2l7 4-7 4V2z"/></svg> Run Optimizer';
  }, 40);
}

// ── BILLS TAB ────────────────────────────────────────────────────────
let billsTabLoaded = false;

async function initBillsTab() {
  if (billsTabLoaded && billsData.length) { renderBillsView(); return; }

  const loader = document.getElementById('billsLoader');
  const err    = document.getElementById('billsError');
  const view   = document.getElementById('billsView');

  // If senators already loaded from optimizer tab, reuse
  if (senators.length) {
    billsData = senators;
    billsTabLoaded = true;
    renderBillsView();
    return;
  }

  // Otherwise load 19th congress senators independently
  loader.style.display = 'block';
  err.style.display = 'none';
  view.innerHTML = '';

  try {
    const senData = await apiFetch('/congresses/19/senators?limit=100');
    const rawList = Array.isArray(senData) ? senData : (senData.senators || []);

    const BATCH = 5;
    const results = [];
    for (let i = 0; i < rawList.length; i += BATCH) {
      const batch = rawList.slice(i, i + BATCH);
      const batchRes = await Promise.allSettled(batch.map(async sen => {
        const bills = await fetchAllPaginated(`/people/${sen.id}/bills?congress=19&type=sb`);
        const passed = bills.filter(b => {
          const t = (b.title || '').toUpperCase();
          return t.startsWith('AN ACT') || (b.subjects || []).some(s => /enacted|republic act/i.test(s));
        }).length;
        return {
          id: sen.id,
          name: sen.full_name || `${sen.first_name || ''} ${sen.last_name || ''}`.trim(),
          party: sen.party || '—',
          authored: bills.length,
          passed,
          v: passed,
          w: parseFloat(Math.max(0.1, bills.length > 0 ? 1 - (passed / bills.length) : 0.9).toFixed(2)),
          sectors: [...new Set(bills.flatMap(b => classifyBill(b.title, b.subjects || [])))].slice(0, 4),
          bills: bills.slice(0, 25),
        };
      }));
      batchRes.forEach((r, j) => {
        if (r.status === 'fulfilled') results.push(r.value);
      });
    }

    billsData = results;
    billsTabLoaded = true;
    renderBillsView();

  } catch (e) {
    err.textContent = '⚠ ' + (e.message || 'Failed to load data.');
    err.style.display = 'block';
  } finally {
    loader.style.display = 'none';
  }
}

function renderBillsView() {
  const view = document.getElementById('billsView');
  const data = activeSector === 'All'
    ? billsData
    : billsData.filter(s => s.sectors.includes(activeSector));

  if (!data.length) {
    view.innerHTML = '<div class="empty-state"><div class="empty-icon">🔍</div>No senators found for this sector.</div>';
    return;
  }

  view.innerHTML = data.map(s => {
    const filteredBills = activeSector === 'All'
      ? s.bills
      : s.bills.filter(b => classifyBill(b.title, b.subjects || []).includes(activeSector));

    return `
    <div class="senator-block">
      <div class="senator-block-top">
        <div>
          <div class="senator-block-name">${s.name}</div>
          <div class="senator-block-party">${s.party}</div>
        </div>
        <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap">
          ${s.sectors.map(sectorTag).join('')}
          <span class="mpill mpill-blue" style="font-size:11px">V=${s.v}</span>
          <span class="mpill mpill-red" style="font-size:11px">W=${s.w.toFixed(2)}</span>
        </div>
      </div>
      ${filteredBills.length ? `
      <table class="bills-table">
        <thead>
          <tr>
            <th>Bill number</th>
            <th>Title</th>
            <th>Sector(s)</th>
            <th>Enacted?</th>
          </tr>
        </thead>
        <tbody>
          ${filteredBills.map(b => {
            const enacted = b.title && b.title.toUpperCase().startsWith('AN ACT');
            const secs = classifyBill(b.title, b.subjects || []);
            return `<tr>
              <td style="font-family:'DM Mono',monospace;font-size:11px;white-space:nowrap">${b.bill_number || b.id || '—'}</td>
              <td style="max-width:320px">${b.title || '—'}</td>
              <td>${secs.map(sectorTag).join(' ')}</td>
              <td>
                <span class="enacted-dot ${enacted ? 'dot-yes' : 'dot-no'}"></span>${enacted ? 'Yes' : 'No'}
              </td>
            </tr>`;
          }).join('')}
        </tbody>
      </table>` : '<p style="font-size:12.5px;color:var(--faint);padding:4px 0">No bills found for this sector filter.</p>'}
    </div>`;
  }).join('');
}

// Sector filters
document.querySelectorAll('#sectorFilterBar .filter-chip').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('#sectorFilterBar .filter-chip').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    activeSector = btn.dataset.sector;
    if (billsTabLoaded) renderBillsView();
  });
});

// Auto-load on page start (optional — comment out to require manual load)
// loadSenators();
