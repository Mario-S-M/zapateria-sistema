# 📱 Sistema de Carga y Gestión de Imágenes - Zapatería

## 🚀 Estado del Sistema

### ✅ **Funcionalidades Implementadas**

1. **Carga de Imágenes**:
   - ✅ Selección desde cámara o galería
   - ✅ Upload automático al servidor
   - ✅ Validación de tipos (JPG, PNG, GIF, WEBP)
   - ✅ Límite de tamaño (5MB)
   - ✅ Nomenclatura única (UUID)

2. **Almacenamiento Local**:
   - ✅ Archivos guardados en `/uploads/`
   - ✅ Servicio estático configurado
   - ✅ URLs del servidor en base de datos
   - ✅ Persistencia con Docker volumes

3. **Eliminación Automática**:
   - ✅ Cleanup al borrar zapatos
   - ✅ Manejo robusto de errores
   - ✅ Logs detallados para debugging

## 🔧 **Configuración Actual**

### Backend (NestJS)
```
Puerto: 3000
Endpoint Upload: POST /upload/zapato-image
Archivos Estáticos: GET /uploads/*
Carpeta: ./uploads/
```

### Frontend (React Native)
```
API Base: http://192.168.0.145:3000
Timeout: 30 segundos
Interceptors: Logging habilitado
```

## 🧪 **Cómo Probar el Sistema**

### 1. Iniciar Backend
```bash
cd d:\ZAPATERIA\zapateria-backend
npm run start:dev
```
**Verificar**: `Application is running on: http://localhost:3000`

### 2. Iniciar App Móvil
```bash
cd d:\ZAPATERIA\zapateria-mobile  
npm start
```

### 3. Probar Upload de Imágenes
1. Ir a **Zapatos** → **Agregar Nuevo**
2. Presionar **"Seleccionar Imagen"**
3. Elegir **Cámara** o **Galería**
4. Verificar que aparezca **"✓ Imagen seleccionada"**
5. Completar formulario y **Guardar**

### 4. Verificar Eliminación
1. Crear zapato con imagen
2. Eliminar el zapato
3. Verificar logs del backend:
   ```
   Eliminando zapato ID: xxx con foto: http://...
   Zapato xxx eliminado de la base de datos
   Intentando eliminar imagen: http://...
   Imagen eliminada exitosamente
   ```

## 🐛 **Debugging**

### Problemas Comunes

1. **"No se puede cargar imagen"**
   - ✅ Verificar que backend esté corriendo
   - ✅ Revisar IP en `.env` (192.168.0.145)
   - ✅ Comprobar permisos de cámara/galería

2. **"Error 500 al eliminar"** 
   - ✅ YA RESUELTO: Eliminación robusta implementada

3. **"Imagen no se muestra"**
   - ✅ Verificar URL en logs del frontend
   - ✅ Probar URL directamente en navegador
   - ✅ Comprobar archivos estáticos del backend

### Logs Importantes

**Frontend:**
```
ImagePicker - Iniciando upload de: file://...
Subiendo imagen: { imageUri, filename, type }
API Request: POST http://192.168.0.145:3000/upload/zapato-image
API Response: 200 /upload/zapato-image
URL de imagen generada: http://192.168.0.145:3000/uploads/...
```

**Backend:**
```
Eliminando zapato ID: xxx con foto: http://...
Zapato xxx eliminado de la base de datos  
Intentando eliminar imagen: http://...
Imagen eliminada: /path/to/file.jpg
```

## 🎯 **Próximos Pasos**

Si encuentras problemas:

1. **Verificar Network**: Probar `http://192.168.0.145:3000` en navegador
2. **Revisar Logs**: Tanto frontend como backend tienen logging detallado
3. **Probar Manual**: Usar Postman/Thunder Client para test directo
4. **Docker**: Si usas containers, verificar volúmenes montados

## 📁 **Estructura de Archivos**

```
zapateria-backend/
├── uploads/           # Imágenes subidas
│   ├── .gitkeep      # Mantiene carpeta en Git
│   └── [uuid].jpg    # Archivos con nombres únicos
├── src/upload/       # Módulo de upload
│   ├── upload.service.ts    # Lógica de archivos
│   ├── upload.controller.ts # Endpoint HTTP  
│   └── upload.module.ts     # Configuración
└── main.ts           # Servicio de archivos estáticos

zapateria-mobile/
├── .env              # Configuración API
├── src/components/
│   └── ImagePicker.tsx      # Selector de imágenes
├── src/services/
│   └── upload.service.ts    # Cliente de upload
└── src/lib/
    └── api.ts        # Configuración Axios con interceptors
```

¡El sistema está completamente funcional! 🎉