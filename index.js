'use strict';

// API Configuration
const API_ROOT = 'https://open-congress-api.bettergov.ph/api';
const IS_FILE_PROTOCOL = window.location.protocol === 'file:';
const IS_LOCALHOST = ['localhost', '127.0.0.1', '::1'].includes(window.location.hostname);

function buildApiUrl(path) {
  if (IS_FILE_PROTOCOL) return API_ROOT + path;
  if (IS_LOCALHOST) return `https://corsproxy.io/?${encodeURIComponent(API_ROOT + path)}`;
  return `/api/proxy?path=${encodeURIComponent(path)}`;
}

// ── Sector keyword map ──────────────────────────────────────────────
const SECTOR_RULES = [
  { sector: 'Social Services & Human Development', kw: ['health','medical','hospital','medicine','disease','vaccine','pharmaceu','nutrition','sanitation','demography','social welfare','senior','child','women','family','poverty','disability','gender equality','youth','sports','cultural','muslim affairs','barangay','community'] },
  { sector: 'Education, Science & Culture', kw: ['education','school','university','tuition','student','curriculum','teacher','learning','literacy','academ','scholarship','science','technolog','innovat','digital','information and communications','ICT','research','AI','cyber','culture','arts','heritage','sustainable development','SDG','futures'] },
  { sector: 'Economy, Finance & Labor', kw: ['economy','econom','finance','tax','tariff','invest','fiscal','budget','bank','banking','currency','trade','commerce','business','enterprise','industry','market','entrepreneur','worker','employ','wage','labor','livelihood','manpower','skill','occupat','OFW','overseas worker','migrant','tourism','cooperative','govern corporation','public enterprise','amusement','games'] },
  { sector: 'Infrastructure & Public Services', kw: ['infrastructure','road','bridge','transport','highway','construct','urban','housing','resettlement','water supply','sewage','electricity','electrif','energy','power','communication','telecom','public works','public service'] },
  { sector: 'Agriculture & Environment', kw: ['agriculture','agri','farm','fisher','fishing','crop','livestock','rice','coconut','rural','food secur','irrigat','environment','climate','ecolog','forest','biodiversit','waste','pollution','water resource','natural resource','green','organic','agrarian'] },
  { sector: 'Justice, Law & Security', kw: ['justice','court','crime','anti-corruption','punish','penal','law enforce','illegal','drug','human right','civil right','legal','defense','military','armed','security','police','coast guard','AFP','PNP','disaster','emergency','terrorism','peace','unification','reconciliation','foreign relation','constitution','amendment'] },
  { sector: 'Governance & Internal Affairs', kw: ['government','governance','transparency','accountability','election','suffrage','autonomy','local government','congress','senate','bureaucra','civil service','reorganization','professional regulation','blue ribbon','investigation','public officer','media','ethics','privilege','rules','public information','transparency'] },
];

const SECTOR_CLASS = {
  'Social Services & Human Development': 'st-sshd',
  'Education, Science & Culture': 'st-esc',
  'Economy, Finance & Labor': 'st-efl',
  'Infrastructure & Public Services': 'st-ips',
  'Agriculture & Environment': 'st-ae',
  'Justice, Law & Security': 'st-jls',
  'Governance & Internal Affairs': 'st-gia'
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
  return found.length ? found : ['Governance & Internal Affairs'];
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
let billsTabCongress = null; // track which congress bills were loaded for

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
  try {
    const res = await fetch(buildApiUrl(path), {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }
    });
    
    if (!res.ok) {
      console.error(`API Error: ${res.status} ${res.statusText}`, await res.text());
      throw new Error(`API ${res.status}: ${res.statusText}`);
    }
    
    const json = await res.json();
    if (!json.success) throw new Error(json.error?.message || 'API error');
    return json.data;
  } catch (error) {
    console.error('Fetch error details:', error);
    throw error;
  }
}

async function fetchAllPaginated(path, paramSep='?') {
  const items = [];
  let offset = 0;
  const limit = 100;
  while (true) {
    const sep = path.includes('?') ? '&' : '?';
    const data = await fetch(buildApiUrl(path + sep + `limit=${limit}&offset=${offset}`))
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
async function testAPI() {
  const testUrl = buildApiUrl('/people?type=senator&congress=20&limit=5&sort=last_name&dir=asc');
  console.log('Testing API connection to:', testUrl);
  
  try {
    const res = await fetch(testUrl);
    console.log('Response status:', res.status, res.statusText);
    const json = await res.json();
    console.log('Response body:', json);
    
    if (res.ok && json.success) {
      alert('✅ API is working! You have ' + json.data.length + ' test senators.');
    } else {
      alert('❌ API returned an error:\n' + JSON.stringify(json.error || 'Unknown error'));
    }
  } catch (error) {
    console.error('Test error:', error);
    const msg = error.message || String(error);
    alert('❌ Connection failed:\n' + msg + '\n\nCheck browser console (F12) for more details.');
  }
}

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
    const senData = await apiFetch(`/people?type=senator&congress=${congress}&limit=100&sort=last_name&dir=asc`);
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
          const searchTerm = encodeURIComponent(sen.last_name || sen.first_name || sen.name || '');
          const billsRaw = await fetchAllPaginated(`/documents?search=${searchTerm}&congress=${congress}&type=sb&sort=date_filed&dir=desc`);
          const authoredBills = billsRaw.filter(b => Array.isArray(b.authors) && b.authors.some(a => a.id === sen.id));
          const authored = authoredBills.length;
          // Heuristic: "passed" = bills with subjects indicating Republic Act or enactment
          const passed = authoredBills.filter(b => {
            return (b.subjects || []).some(s => /republic act|enacted into law|ra \d+/i.test(s));
          }).length;
          const sectors = [...new Set(authoredBills.flatMap(b => classifyBill(b.title, b.subjects || [])))].slice(0,4);
          return {
            id: sen.id,
            name: sen.full_name || `${sen.first_name || ''} ${sen.last_name || ''}`.trim(),
            party: sen.party || sen.aliases?.[0] || '—',
            authored,
            passed,
            v: passed,
            w: parseFloat(Math.max(0.1, authored > 0 ? 1 - (passed / authored) : 0.9).toFixed(2)),
            sectors,
            bills: authoredBills.slice(0, 20),
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
    const errorMsg = e.message || 'Failed to load data. Check network or API availability.';
    console.error('Load error:', errorMsg);
    
    // Check if it's a CORS error
    if (errorMsg.includes('NetworkError') || errorMsg.includes('Failed to fetch')) {
      err.textContent = '⚠ CORS Error: The API may be blocking requests from this origin. Try opening the API directly: https://open-congress-api.bettergov.ph/api/people?type=senator&congress=19&limit=100&sort=last_name&dir=asc';
    } else {
      err.textContent = '⚠ ' + errorMsg;
    }
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
        <span class="mpill mpill-neutral">Authored: ${s.authored}</span>
        <span class="mpill mpill-neutral">Passed: ${s.passed}</span>
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
  const loader = document.getElementById('billsLoader');
  const err    = document.getElementById('billsError');
  const view   = document.getElementById('billsView');
  const congress = document.getElementById('congressSelect').value;
  
  // Reset if congress changed
  if (congress !== billsTabCongress) {
    billsTabLoaded = false;
    billsData = [];
  }
  if (billsTabLoaded && billsData.length) { renderBillsView(); return; }

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
    const senData = await apiFetch(`/people?type=senator&congress=${congress}&limit=100&sort=last_name&dir=asc`);
    const rawList = Array.isArray(senData) ? senData : (senData.senators || []);
    const statusEl = document.getElementById('billsStatus');

    const BATCH = 5;
    const results = [];
    for (let i = 0; i < rawList.length; i += BATCH) {
      if (statusEl) statusEl.textContent = `Loading senator ${i+1}–${Math.min(i+BATCH, rawList.length)} of ${rawList.length}…`;
      const batch = rawList.slice(i, i + BATCH);
      const batchRes = await Promise.allSettled(batch.map(async sen => {
        const searchTerm = encodeURIComponent(sen.last_name || sen.first_name || sen.name || '');
        const billsRaw = await fetchAllPaginated(`/documents?search=${searchTerm}&congress=${congress}&type=sb&sort=date_filed&dir=desc`);
        const bills = billsRaw.filter(b => Array.isArray(b.authors) && b.authors.some(a => a.id === sen.id));
        const passed = bills.filter(b => {
          return (b.subjects || []).some(s => /republic act|enacted into law|ra \d+/i.test(s));
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
    billsTabCongress = congress;
    billsTabLoaded = true;
    if (statusEl) statusEl.textContent = '';
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

  // Build summary table
  const summaryRows = data.sort((a, b) => b.authored - a.authored).map(s => {
    const sectorCounts = {};
    SECTOR_RULES.forEach(r => sectorCounts[r.sector] = 0);
    s.bills.forEach(b => {
      classifyBill(b.title, b.subjects || []).forEach(sec => {
        if (sectorCounts[sec] !== undefined) sectorCounts[sec]++;
      });
    });
    return { ...s, sectorCounts };
  });
  
  const summaryHtml = `
    <div class="bills-summary-table" style="margin-bottom:20px;overflow-x:auto;">
      <table style="width:100%;border-collapse:collapse;font-size:12px;">
        <thead>
          <tr style="border-bottom:2px solid var(--border);">
            <th style="text-align:left;padding:8px;font-weight:600;">Senator</th>
            <th style="text-align:right;padding:8px;font-weight:600;">Authored</th>
            <th style="text-align:right;padding:8px;font-weight:600;">Passed</th>
            ${SECTOR_RULES.map(r => `<th style="text-align:center;padding:8px;font-weight:600;">${r.sector.split(' ').slice(0,2).join(' ')}</th>`).join('')}
          </tr>
        </thead>
        <tbody>
          ${summaryRows.map((s, idx) => `
            <tr style="border-bottom:1px solid var(--border);${idx % 2 === 0 ? 'background:#fafafe;' : ''}">
              <td style="text-align:left;padding:8px;">
                <strong>${s.name}</strong>
                <br/><small style="color:var(--faint);">${s.party}</small>
              </td>
              <td style="text-align:right;padding:8px;font-family:'DM Mono',monospace;">${s.authored}</td>
              <td style="text-align:right;padding:8px;font-family:'DM Mono',monospace;color:#10b981;">${s.passed}</td>
              ${SECTOR_RULES.map(r => `<td style="text-align:center;padding:8px;font-family:'DM Mono',monospace;">${s.sectorCounts[r.sector] || 0}</td>`).join('')}
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;

  // Build senator blocks with collapsible bills (summary table will be appended below)
  const senatorsHtml = data.map(s => {
    const filteredBills = activeSector === 'All'
      ? s.bills
      : s.bills.filter(b => classifyBill(b.title, b.subjects || []).includes(activeSector));
    const blockId = `senbills-${s.id}`;
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
          <button class="toggle-bills" onclick="toggleBills('${blockId}')">Show bills ▾</button>
        </div>
      </div>
      <div id="${blockId}" class="bills-collapsible">
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
      </div>
    </div>`;
  }).join('');

  // Place the summary table BELOW the list of senator blocks
  view.innerHTML = senatorsHtml + summaryHtml;

}

// Toggle collapsible bills for a senator block
function toggleBills(id) {
  const el = document.getElementById(id);
  if (!el) return;
  const isOpen = el.classList.toggle('open');
  // update the button text inside the same parent
  const btn = el.parentElement.querySelector('.toggle-bills');
  if (btn) btn.textContent = isOpen ? 'Hide bills ▴' : 'Show bills ▾';
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
