const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/ventas/reporte/cierre-caja?fechaInicio=2026-01-03&fechaFin=2026-01-03',
  method: 'GET',
  timeout: 30000
};

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  let data = '';
  
  res.on('data', chunk => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Response:', data);
    try {
      const parsed = JSON.parse(data);
      console.log('Parsed JSON:', JSON.stringify(parsed, null, 2));
    } catch (e) {
      console.error('Parse error:', e.message);
    }
  });
});

req.on('error', (e) => {
  console.error(`Error: ${e.message}`);
  console.error('Code:', e.code);
});

req.on('timeout', () => {
  console.error('Request timeout');
  req.destroy();
});

console.log('Sending request...');
req.end();
