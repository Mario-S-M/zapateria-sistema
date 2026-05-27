import https from 'https';
import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const BASE_URL = 'http://localhost:3000';
const TMP_DIR = '/tmp/zapateria-seed-images';

// ──────────────────────────────────────────────
// Datos simulados
// ──────────────────────────────────────────────

const INVERSIONISTAS = [
  { nombre: 'Carlos Mendoza', telefono: '5551234567', email: 'carlos.mendoza@gmail.com' },
  { nombre: 'Sofía Ramírez', telefono: '5559876543', email: 'sofia.ramirez@hotmail.com' },
  { nombre: 'Jorge Hernández', telefono: '5554561230', email: 'jorge.hernandez@outlook.com' },
];

const CATEGORIAS = [
  { nombre: 'Casual', activo: true },
  { nombre: 'Deportivo', activo: true },
  { nombre: 'Formal', activo: true },
  { nombre: 'Sandalia', activo: true },
  { nombre: 'Bota', activo: true },
];

const COLORES = [
  { nombre: 'Negro', hexadecimal: '#1A1A1A' },
  { nombre: 'Blanco', hexadecimal: '#FFFFFF' },
  { nombre: 'Café', hexadecimal: '#795548' },
  { nombre: 'Azul Marino', hexadecimal: '#1A237E' },
  { nombre: 'Rojo', hexadecimal: '#C62828' },
  { nombre: 'Gris', hexadecimal: '#757575' },
  { nombre: 'Beige', hexadecimal: '#D7CCC8' },
  { nombre: 'Dorado', hexadecimal: '#F9A825' },
  { nombre: 'Rosa', hexadecimal: '#E91E63' },
  { nombre: 'Verde', hexadecimal: '#2E7D32' },
];

// Imágenes de picsum con seeds específicos para que sean consistentes
const IMAGE_SEEDS = [10, 20, 50, 64, 91, 110, 130, 160, 180, 200, 220, 250, 270, 300, 320];

const ZAPATOS_DATA = [
  { nombre: 'Tenis Runner Pro', modelo: 'RP-2024', codigoBarras: '7501000000001', precioCompra: 450, precioPublico: 899, medidaInicio: 22, medidaFin: 28, categoria: 'Deportivo', colores: ['Negro', 'Blanco'], inversionista: 'Carlos Mendoza' },
  { nombre: 'Oxford Clásico', modelo: 'OX-100', codigoBarras: '7501000000002', precioCompra: 680, precioPublico: 1299, medidaInicio: 25, medidaFin: 29, categoria: 'Formal', colores: ['Negro', 'Café'], inversionista: 'Sofía Ramírez' },
  { nombre: 'Sneaker Urban', modelo: 'SU-500', codigoBarras: '7501000000003', precioCompra: 380, precioPublico: 749, medidaInicio: 22, medidaFin: 27, categoria: 'Casual', colores: ['Blanco', 'Gris'], inversionista: 'Jorge Hernández' },
  { nombre: 'Sandalia Playa', modelo: 'SP-001', codigoBarras: '7501000000004', precioCompra: 200, precioPublico: 399, medidaInicio: 22, medidaFin: 26, categoria: 'Sandalia', colores: ['Beige', 'Café'], inversionista: 'Carlos Mendoza' },
  { nombre: 'Bota Vaquera', modelo: 'BV-300', codigoBarras: '7501000000005', precioCompra: 950, precioPublico: 1850, medidaInicio: 24, medidaFin: 29, categoria: 'Bota', colores: ['Café', 'Negro'], inversionista: 'Sofía Ramírez' },
  { nombre: 'Mocasín Elegante', modelo: 'ME-200', codigoBarras: '7501000000006', precioCompra: 520, precioPublico: 1050, medidaInicio: 25, medidaFin: 28, categoria: 'Formal', colores: ['Negro', 'Café'], inversionista: 'Jorge Hernández' },
  { nombre: 'Tenis Retro 90s', modelo: 'TR-90', codigoBarras: '7501000000007', precioCompra: 420, precioPublico: 850, medidaInicio: 22, medidaFin: 28, categoria: 'Casual', colores: ['Blanco', 'Rojo', 'Azul Marino'], inversionista: 'Carlos Mendoza' },
  { nombre: 'Ballerina Suave', modelo: 'BS-050', codigoBarras: '7501000000008', precioCompra: 290, precioPublico: 580, medidaInicio: 22, medidaFin: 26, categoria: 'Casual', colores: ['Rosa', 'Beige', 'Negro'], inversionista: 'Sofía Ramírez' },
  { nombre: 'Bota Táctica', modelo: 'BT-700', codigoBarras: '7501000000009', precioCompra: 750, precioPublico: 1499, medidaInicio: 25, medidaFin: 30, categoria: 'Bota', colores: ['Negro', 'Café'], inversionista: 'Jorge Hernández' },
  { nombre: 'Sandalia Casual Dama', modelo: 'SCD-10', codigoBarras: '7501000000010', precioCompra: 180, precioPublico: 349, medidaInicio: 22, medidaFin: 25, categoria: 'Sandalia', colores: ['Dorado', 'Beige', 'Rosa'], inversionista: 'Carlos Mendoza' },
  { nombre: 'Tenis Alto Basket', modelo: 'TAB-11', codigoBarras: '7501000000011', precioCompra: 550, precioPublico: 1099, medidaInicio: 24, medidaFin: 30, categoria: 'Deportivo', colores: ['Negro', 'Rojo'], inversionista: 'Sofía Ramírez' },
  { nombre: 'Loafer Moderno', modelo: 'LM-400', codigoBarras: '7501000000012', precioCompra: 480, precioPublico: 980, medidaInicio: 25, medidaFin: 29, categoria: 'Casual', colores: ['Verde', 'Café', 'Negro'], inversionista: 'Jorge Hernández' },
  { nombre: 'Zapato Derby', modelo: 'ZD-600', codigoBarras: '7501000000013', precioCompra: 610, precioPublico: 1249, medidaInicio: 25, medidaFin: 28, categoria: 'Formal', colores: ['Negro'], inversionista: 'Carlos Mendoza' },
  { nombre: 'Tenis Trail', modelo: 'TT-800', codigoBarras: '7501000000014', precioCompra: 490, precioPublico: 979, medidaInicio: 23, medidaFin: 29, categoria: 'Deportivo', colores: ['Gris', 'Verde', 'Negro'], inversionista: 'Sofía Ramírez' },
  { nombre: 'Bota Tobillera', modelo: 'BTB-15', codigoBarras: '7501000000015', precioCompra: 680, precioPublico: 1380, medidaInicio: 23, medidaFin: 27, categoria: 'Bota', colores: ['Negro', 'Café'], inversionista: 'Jorge Hernández' },
];

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────

function downloadImage(seed) {
  const tmpPath = path.join(TMP_DIR, `shoe_${seed}.jpg`);
  const url = `https://picsum.photos/seed/${seed}/400/600`;

  return new Promise((resolve, reject) => {
    const follow = (u) => {
      const mod = u.startsWith('https') ? https : http;
      mod.get(u, (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) {
          follow(res.headers.location);
          return;
        }
        const file = fs.createWriteStream(tmpPath);
        res.pipe(file);
        file.on('finish', () => file.close(() => resolve(tmpPath)));
        file.on('error', reject);
      }).on('error', reject);
    };
    follow(url);
  });
}

async function uploadImage(imagePath) {
  const boundary = '----FormBoundary' + Math.random().toString(36).slice(2);
  const fileBuffer = fs.readFileSync(imagePath);
  const filename = path.basename(imagePath);

  const body = Buffer.concat([
    Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="image"; filename="${filename}"\r\nContent-Type: image/jpeg\r\n\r\n`),
    fileBuffer,
    Buffer.from(`\r\n--${boundary}--\r\n`),
  ]);

  const res = await fetch(`${BASE_URL}/upload/zapato-image`, {
    method: 'POST',
    headers: {
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
      'Content-Length': body.length,
    },
    body,
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Upload falló (${res.status}): ${txt}`);
  }
  const data = await res.json();
  return data.filePath;
}

async function post(path, body) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`POST ${path} falló (${res.status}): ${txt}`);
  }
  return res.json();
}

async function getAll(path) {
  const res = await fetch(`${BASE_URL}${path}`);
  return res.json();
}

function log(emoji, msg) { console.log(`${emoji}  ${msg}`); }

// ──────────────────────────────────────────────
// Main
// ──────────────────────────────────────────────

async function main() {
  fs.mkdirSync(TMP_DIR, { recursive: true });

  // ── Inversionistas ──
  log('👤', 'Creando inversionistas...');
  const invMap = {};
  const existingInv = await getAll('/inversionistas');
  for (const inv of INVERSIONISTAS) {
    const exists = existingInv.find(e => e.nombre === inv.nombre);
    if (exists) {
      invMap[inv.nombre] = exists.id;
      log('  ⏭️', `${inv.nombre} ya existe`);
    } else {
      const created = await post('/inversionistas', inv);
      invMap[inv.nombre] = created.id;
      log('  ✅', `${inv.nombre}`);
    }
  }

  // ── Categorías ──
  log('📂', 'Creando categorías...');
  const catMap = {};
  const existingCat = await getAll('/categorias');
  for (const cat of CATEGORIAS) {
    const exists = existingCat.find(e => e.nombre === cat.nombre);
    if (exists) {
      catMap[cat.nombre] = exists.id;
      log('  ⏭️', `${cat.nombre} ya existe`);
    } else {
      const created = await post('/categorias', cat);
      catMap[cat.nombre] = created.id;
      log('  ✅', `${cat.nombre}`);
    }
  }

  // ── Colores ──
  log('🎨', 'Creando colores...');
  const colMap = {};
  const existingCol = await getAll('/colores');
  for (const col of COLORES) {
    const exists = existingCol.find(e => e.nombre === col.nombre);
    if (exists) {
      colMap[col.nombre] = exists.id;
      log('  ⏭️', `${col.nombre} ya existe`);
    } else {
      const created = await post('/colores', col);
      colMap[col.nombre] = created.id;
      log('  ✅', `${col.nombre}`);
    }
  }

  // ── Imágenes ──
  log('🖼️ ', 'Descargando y subiendo imágenes...');
  const fotoPaths = [];
  for (let i = 0; i < ZAPATOS_DATA.length; i++) {
    const seed = IMAGE_SEEDS[i];
    process.stdout.write(`  ⬇️  Imagen ${i + 1}/${ZAPATOS_DATA.length} (seed ${seed})...`);
    const tmpPath = await downloadImage(seed);
    const filePath = await uploadImage(tmpPath);
    fotoPaths.push(filePath);
    console.log(` ✅ ${filePath}`);
  }

  // ── Zapatos ──
  log('👟', 'Creando zapatos...');
  const existingZapatos = await getAll('/zapatos');
  const existingCodes = new Set(existingZapatos.map(z => z.codigoBarras));

  for (let i = 0; i < ZAPATOS_DATA.length; i++) {
    const z = ZAPATOS_DATA[i];
    if (existingCodes.has(z.codigoBarras)) {
      log('  ⏭️', `${z.nombre} ya existe`);
      continue;
    }
    const colorIds = z.colores.map(c => colMap[c]).filter(Boolean);
    await post('/zapatos', {
      codigoBarras: z.codigoBarras,
      nombre: z.nombre,
      modelo: z.modelo,
      foto: fotoPaths[i],
      precioCompra: z.precioCompra,
      precioPublico: z.precioPublico,
      medidaInicio: z.medidaInicio,
      medidaFin: z.medidaFin,
      categoriaId: catMap[z.categoria],
      inversionistaId: invMap[z.inversionista],
      colorIds,
    });
    log('  ✅', `${z.nombre} (${z.modelo}) — $${z.precioPublico}`);
  }

  // Cleanup
  fs.rmSync(TMP_DIR, { recursive: true, force: true });

  console.log('\n🎉  ¡Seed completado! La base de datos tiene datos de prueba listos.\n');
}

main().catch(err => {
  console.error('\n❌ Error en el seed:', err.message);
  process.exit(1);
});
