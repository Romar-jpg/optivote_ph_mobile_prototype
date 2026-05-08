# Optivote-PH

> Lightweight client for Optivote PH — static frontend with a small API proxy.

## Project structure

- `index.html` — main app HTML
- `index.js` — frontend JavaScript
- `style.css` — styles
- `api/proxy.js` — simple Node proxy for API requests

## Requirements

- Node.js (for the API proxy)
- A static file server or a browser (you can open `index.html` directly)

## Run (quick)

Open `index.html` in your browser for a quick local test.

## Run with a static server (recommended)

Using Python (if installed):

```bash
python -m http.server 8000
# then open http://localhost:8000
```

Or using `http-server` (npm):

```bash
npx http-server -c-1 . -p 8000
# then open http://localhost:8000
```

## Run the API proxy

If you need the proxy in `api/proxy.js`, start it with Node:

```bash
node api/proxy.js
# defaults: http://localhost:3000 (check file for details)
```

Adjust ports in `api/proxy.js` as needed.

## Contributing

Pull requests and issues are welcome. For small changes, update files and open a PR.

## License

MIT — see LICENSE or add one if needed.
