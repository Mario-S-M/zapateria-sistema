#!/usr/bin/env node

// Script de prueba para verificar el sistema de upload e imágenes
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const API_BASE = 'http://localhost:3000';

async function testImageUpload() {
  console.log('🧪 Iniciando pruebas del sistema de imágenes...\n');

  try {
    // 1. Verificar que el servidor esté disponible
    console.log('1. Verificando servidor...');
    const healthCheck = await axios.get(`${API_BASE}/`);
    console.log('✅ Servidor disponible');

    // 2. Verificar endpoint de upload
    console.log('2. Verificando endpoint de upload...');
    
    // Crear una imagen de prueba simple (1x1 pixel PNG)
    const testImageBuffer = Buffer.from([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ]);

    const formData = new FormData();
    formData.append('image', testImageBuffer, {
      filename: 'test-image.png',
      contentType: 'image/png'
    });

    const uploadResponse = await axios.post(
      `${API_BASE}/upload/zapato-image`,
      formData,
      {
        headers: {
          ...formData.getHeaders()
        }
      }
    );

    console.log('✅ Upload exitoso:', uploadResponse.data);
    
    // 3. Verificar que la imagen se pueda descargar
    const imageUrl = `${API_BASE}/${uploadResponse.data.filePath}`;
    console.log('3. Verificando acceso a imagen:', imageUrl);
    
    const downloadResponse = await axios.get(imageUrl);
    console.log('✅ Imagen accesible, tamaño:', downloadResponse.data.length);

    console.log('\n🎉 Todas las pruebas pasaron exitosamente!');
    
    return uploadResponse.data.filePath;
    
  } catch (error) {
    console.error('❌ Error en las pruebas:', error.response?.data || error.message);
    throw error;
  }
}

if (require.main === module) {
  testImageUpload()
    .then((filePath) => {
      console.log('\n📁 Archivo creado:', filePath);
      console.log('👍 Sistema de imágenes funcionando correctamente');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Pruebas fallidas');
      process.exit(1);
    });
}