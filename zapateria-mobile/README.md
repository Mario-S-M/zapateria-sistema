# Zapatería Mobile - React Native + Expo + Tamagui

Aplicación móvil para el sistema de gestión de zapatería.

## Tecnologías

- **React Native** con Expo
- **Tamagui** - UI Framework
- **React Navigation** - Navegación
- **Zustand** - Estado global
- **React Query** - Gestión de datos
- **Axios** - Cliente HTTP
- **Zod** - Validaciones
- **Sonner Native** - Notificaciones
- **Expo Barcode Scanner** - Escaneo de códigos de barras

## Estructura del Proyecto

```
src/
├── screens/         # Pantallas de la app
│   ├── ScannerScreen.tsx
│   ├── CartScreen.tsx
│   ├── VentasScreen.tsx
│   └── ZapatosScreen.tsx
├── services/        # Servicios de API
│   ├── color.service.ts
│   ├── zapato.service.ts
│   ├── inversionista.service.ts
│   └── venta.service.ts
├── store/           # Estado global con Zustand
│   └── cart.ts
├── types/           # Tipos de TypeScript
│   └── index.ts
└── lib/             # Utilidades
    └── api.ts
```

## Requisitos Previos

- Node.js 18+
- Expo CLI
- Android Studio (para Android) o Xcode (para iOS)

## Instalación

```bash
npm install
```

## Configuración

Copia el archivo `.env.example` a `.env` y configura la URL del backend:

```env
EXPO_PUBLIC_API_URL=http://localhost:3000
```

## Desarrollo

```bash
# Iniciar en modo desarrollo
npm start

# Iniciar en Android
npm run android

# Iniciar en iOS
npm run ios

# Iniciar en web
npm run web
```

## Funcionalidades

- ✅ Escaneo de códigos de barras
- ✅ Catálogo de zapatos
- ✅ Carrito de compras
- ✅ Gestión de ventas
- ✅ Diferentes tipos de precios (Público, Mayorista, Inversionista)
- ✅ Historial de ventas

## Notas

- El backend debe estar corriendo en el puerto 3000
- Para probar en dispositivo físico, ajusta la URL del API en `.env`
