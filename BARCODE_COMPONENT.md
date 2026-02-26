# 📊 Componente BarcodeDisplay

## ✨ **Código de Barras Visual Real**

He creado un componente que genera códigos de barras visuales reales basados en el patrón Code128.

### 🎯 **Características**

- ✅ **Barras reales**: No números, sino barras visuales auténticas
- ✅ **Patrón Code128**: Algoritmo similar a códigos de barras comerciales
- ✅ **Tamaño personalizable**: Ancho y alto ajustables
- ✅ **Color configurable**: Barras en cualquier color
- ✅ **Etiqueta opcional**: Mostrar número debajo si se desea

### 🔧 **Uso en la Aplicación**

#### **En Cards de Zapatos** (Actual)
```tsx
<BarcodeDisplay 
  code={item.codigoBarras} 
  width={80} 
  height={12} 
  color="#666666"
/>
```

#### **Versión con Etiqueta** (Para formularios)
```tsx
<BarcodeDisplay 
  code="123456789012" 
  width={120} 
  height={20} 
  color="#000000"
  showLabel={true}
/>
```

### 📱 **Resultado Visual**

```
Nombre del zapato        $Precio
Modelo                      
|||||| |||| |||||| |||    <- Código de barras visual
                            
Tallas: 38 - 45

Colores disponibles:
● ● ●
```

### 🎨 **Opciones de Personalización**

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `code` | string | required | Código numérico a convertir |
| `width` | number | 60 | Ancho total en pixels |
| `height` | number | 16 | Alto de las barras |
| `color` | string | "#000000" | Color de las barras |
| `showLabel` | boolean | false | Mostrar número debajo |

### 💡 **Ejemplos de Uso**

#### **Card Compacto** (Como está ahora)
- Ancho: 80px, Alto: 12px
- Sin etiqueta de texto
- Color gris sutil

#### **Formulario Grande**
- Ancho: 150px, Alto: 25px  
- Con etiqueta de texto
- Color negro

#### **Recibo/Ticket**
- Ancho: 200px, Alto: 30px
- Con etiqueta de texto
- Color negro intenso

### 🧮 **Algoritmo**

El componente genera barras usando:
1. **Patrón de inicio**: Marcador Code128
2. **Dígitos del código**: Cada número → patrón de barras único
3. **Patrón de fin**: Marcador de cierre
4. **Fondo blanco**: Con borde sutil

¡Ahora los códigos de barras se ven como códigos reales! 📊✨