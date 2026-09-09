const http = require('http');

const port = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', uptime: process.uptime() }));
    return;
  }

  res.writeHead(500, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Azure App Service Demo</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; display: grid; place-items: center; min-height: 100vh; background: #0f172a; color: #e2e8f0; }
    main { text-align: center; padding: 2rem; }
    h1 { margin: 0 0 0.5rem; font-size: 2rem; }
    code { background: #1e293b; padding: 0.2rem 0.4rem; border-radius: 4px; }
  </style>
</head>
<body>
  <main>
    <h1>Hello from Azure App Service</h1>
    <p>Bicep でデプロイした Node.js アプリです。</p>
    <p>Node ${process.version} / ${new Date().toISOString()}</p>
    <p><code>/health</code> でヘルスチェックできます。</p>
  </main>
</body>
</html>`);
});

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
