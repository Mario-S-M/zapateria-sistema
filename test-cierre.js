const http = require('http');

const url = 'http://localhost:3000/ventas/reporte/cierre-caja?fechaInicio=2026-01-03&fechaFin=2026-01-03';

http.get(url, (res) => {
  let data = '';
  res.on('data', chunk => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', data);
    try {
      const parsed = JSON.parse(data);
      console.log('Parsed:', JSON.stringify(parsed, null, 2));
    } catch (e) {
      console.error('Parse error:', e.message);
    }
  });
}).on('error', (e) => {
  console.error('Error:', e.message);
});
