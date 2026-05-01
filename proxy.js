const http = require('http');
const https = require('https');
const url = require('url');

const PORT = 3001;

const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Construct the target URL by forwarding to the actual API
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname; // e.g., /api/people
  const query = parsedUrl.search; // e.g., ?type=senator&...
  
  const targetUrl = `https://open-congress-api.bettergov.ph${pathname}${query}`;

  console.log(`Proxying: ${targetUrl}`);

  https.get(targetUrl, (apiRes) => {
    let data = '';

    apiRes.on('data', (chunk) => {
      data += chunk;
    });

    apiRes.on('end', () => {
      res.writeHead(apiRes.statusCode, { 'Content-Type': 'application/json' });
      res.end(data);
    });
  }).on('error', (e) => {
    console.error('Proxy error:', e);
    res.writeHead(500);
    res.end(JSON.stringify({error: 'Proxy error'}));
  });
});

server.listen(PORT, () => {
  console.log(`✅ CORS Proxy running at http://localhost:${PORT}`);
  console.log(`   Requests will be forwarded to open-congress-api.bettergov.ph`);
});
