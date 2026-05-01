const API_ROOT = 'https://open-congress-api.bettergov.ph/api';

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const path = req.query.path;

  if (!path || typeof path !== 'string' || !path.startsWith('/')) {
    res.status(400).json({ success: false, error: 'Missing or invalid path parameter' });
    return;
  }

  const targetUrl = API_ROOT + path;

  try {
    const upstream = await fetch(targetUrl, {
      headers: {
        Accept: 'application/json',
      },
    });

    const contentType = upstream.headers.get('content-type') || 'application/json';
    const body = await upstream.text();

    res.status(upstream.status);
    res.setHeader('Content-Type', contentType);
    res.send(body);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message || 'Proxy error' });
  }
}