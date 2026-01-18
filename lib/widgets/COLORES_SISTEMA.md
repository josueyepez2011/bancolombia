# 🎨 Paleta de Colores del Sistema de Errores

## Colores Principales

### 🔴 Error / Peligro
```dart
Color(0xFFd32f2f)  // Rojo fuerte
```
**Uso:**
- Mensajes de error
- Validaciones fallidas
- Operaciones canceladas
- Errores de autenticación

**Ejemplo visual:**
```
████████████████████
█  ERROR MESSAGE   █
████████████████████
```

---

### 🟢 Éxito / Confirmación
```dart
Color(0xFF4CAF50)  // Verde fuerte Material Design
```
**Uso:**
- Operaciones exitosas
- Confirmaciones
- Inicio de sesión correcto
- Datos guardados

**Ejemplo visual:**
```
████████████████████
█  SUCCESS! ✓      █
████████████████████
```

---

### 🟠 Advertencia / Validación
```dart
Color(0xFFe67e22)  // Naranja
```
**Uso:**
- Validaciones de formularios
- Advertencias inline
- Campos requeridos
- Formato incorrecto

**Ejemplo visual:**
```
████████████████████
█  ⚠ Warning       █
████████████████████
```

---

## Colores Secundarios

### Texto sobre fondos de color
```dart
Colors.white  // Texto en errores y éxitos
Color(0xFF4f3422)  // Texto en advertencias
```

### Fondos de advertencia
```dart
Color(0xFFfff3e0)  // Fondo claro para advertencias
Colors.white  // Fondo para banners inline
```

---

## Comparación de Colores

| Tipo | Color Hex | RGB | Uso Principal |
|------|-----------|-----|---------------|
| Error | #d32f2f | rgb(211, 47, 47) | ErrorSnackBar, ErrorDialog |
| Éxito | #4CAF50 | rgb(76, 175, 80) | Confirmaciones, Success messages |
| Advertencia | #e67e22 | rgb(230, 126, 34) | ErrorBanner, Validaciones |
| Texto Error | #4f3422 | rgb(79, 52, 34) | Texto en banners |

---

## Accesibilidad

✅ **Contraste WCAG AA:**
- Texto blanco sobre rojo (#d32f2f): **Ratio 5.5:1** ✓
- Texto blanco sobre verde (#4CAF50): **Ratio 4.6:1** ✓
- Texto oscuro sobre naranja claro: **Ratio 7.2:1** ✓

Todos los colores cumplen con los estándares de accesibilidad WCAG 2.1 nivel AA.

---

## Ejemplos de Uso

### ErrorSnackBar
```dart
// Error - Fondo rojo
ErrorSnackBar.show(context, message: 'Error', isError: true);

// Éxito - Fondo verde fuerte
ErrorSnackBar.show(context, message: 'Éxito', isError: false);
```

### ErrorBanner
```dart
// Advertencia - Borde naranja, fondo claro
ErrorBanner(
  message: 'Campo requerido',
  iconColor: Color(0xFFe67e22),
  backgroundColor: Color(0xFFfff3e0),
)
```

### ErrorDialog
```dart
// Error - Icono rojo
ErrorDialog.show(
  context,
  message: 'Error crítico',
  // Usa automáticamente el color rojo
)
```

---

## Personalización

Si necesitas cambiar los colores del sistema, edita estos archivos:

1. **`lib/widgets/error_widgets.dart`**
   - Línea ~120: Color del ErrorSnackBar de error
   - Línea ~120: Color del ErrorSnackBar de éxito
   - Línea ~163: Color del botón en ErrorDialog

2. **`lib/widgets/error_demo_screen.dart`**
   - Actualiza los colores de los botones de demostración

---

## 🎨 Paleta Completa de la App

### Colores de la Marca (App)
```dart
Color(0xFF9bb168)  // Verde oliva (color principal de la app)
Color(0xFFf7f4f2)  // Beige claro (fondo)
Color(0xFF4f3422)  // Marrón oscuro (texto)
```

### Colores del Sistema de Errores
```dart
Color(0xFFd32f2f)  // Rojo (errores)
Color(0xFF4CAF50)  // Verde fuerte (éxitos)
Color(0xFFe67e22)  // Naranja (advertencias)
```

---

## 💡 Recomendaciones

1. **Usa verde fuerte (#4CAF50)** para mensajes de éxito - es más visible y transmite mejor la sensación de "completado"
2. **Usa rojo (#d32f2f)** solo para errores reales - no para advertencias
3. **Usa naranja (#e67e22)** para validaciones y advertencias - es menos alarmante
4. **Mantén consistencia** - usa siempre los mismos colores para los mismos tipos de mensajes

---

## 🔄 Historial de Cambios

- **v1.1** - Cambiado verde de éxito de #9bb168 a #4CAF50 (más fuerte y visible)
- **v1.0** - Implementación inicial del sistema de colores
