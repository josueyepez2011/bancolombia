# 🎯 Sistema Activo de Errores y Advertencias

## ¿Qué se creó?

Se implementó un **sistema centralizado y automático** de manejo de errores que se puede aplicar a todas las pantallas de la aplicación.

## 📁 Archivos Creados

```
lib/system/
├── error_handler_system.dart              ← Sistema principal
├── error_handler_integration_guide.dart   ← Guía de integración
├── ERROR_HANDLER_SYSTEM_README.md         ← Documentación completa
└── SISTEMA_ERRORES_RESUMEN.md            ← Este archivo
```

## 🚀 Características Principales

### 1. **ErrorHandlerSystem** (Singleton)
- Gestiona una cola centralizada de errores
- Notifica cambios automáticamente
- Soporta múltiples tipos de mensajes

### 2. **ErrorHandlerScreen** (Widget Wrapper)
- Envuelve cualquier pantalla
- Inyecta automáticamente la UI de errores
- Configurable (banners, snackbars, diálogos)

### 3. **Extensión de Contexto**
- Acceso fácil desde cualquier widget
- Métodos: `showError()`, `showWarning()`, `showSuccess()`

## 📊 Tipos de Mensajes

| Tipo | Color | Icono | Uso |
|------|-------|-------|-----|
| **Error** | 🔴 Rojo | error_outline | Errores críticos |
| **Warning** | 🟠 Naranja | warning_rounded | Advertencias |
| **Success** | 🟢 Verde | check_circle_outline | Confirmaciones |

## 💻 Uso Rápido

### Paso 1: Importar
```dart
import '../system/index.dart';
```

### Paso 2: Envolver la pantalla
```dart
class MiPantalla extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      child: Scaffold(
        appBar: AppBar(title: Text('Mi Pantalla')),
        body: MiContenido(),
      ),
    );
  }
}
```

### Paso 3: Mostrar errores
```dart
// Error
context.showError(
  message: 'No se pudo cargar',
  title: 'Error',
);

// Advertencia
context.showWarning(
  message: 'Acción irreversible',
  title: 'Advertencia',
);

// Éxito
context.showSuccess(
  message: 'Guardado correctamente',
  title: 'Éxito',
);
```

## 🎨 Visualización

### ErrorSnackBar (desde arriba)
```
┌─────────────────────────────────┐
│ 🔴 Error: No se pudo cargar  ✕ │  ← Aparece desde arriba
└─────────────────────────────────┘
```

### ErrorBanner (inline)
```
┌─────────────────────────────────┐
│ ⚠️  Advertencia importante    ✕ │  ← Dentro de la pantalla
└─────────────────────────────────┘
```

### ErrorDialog (modal)
```
    ┌──────────────────────┐
    │   🔴 Error           │
    │                      │
    │ Mensaje de error     │
    │                      │
    │  [  Entendido  ]     │
    └──────────────────────┘
```

## 🔄 Flujo de Funcionamiento

```
┌─────────────────────────────────────────────────────┐
│ 1. Usuario interactúa con la pantalla               │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 2. Ocurre un error/advertencia                      │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 3. context.showError() es llamado                   │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 4. ErrorHandlerSystem agrega el error a la cola     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 5. ErrorHandlerScreen detecta el cambio             │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 6. Muestra el error en:                             │
│    - Banner inline (si showErrorBanner = true)      │
│    - SnackBar (si showErrorSnackBar = true)         │
│    - Dialog (si showErrorDialog = true)             │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 7. Error se auto-elimina después de la duración     │
└─────────────────────────────────────────────────────┘
```

## 📋 Checklist de Integración

Para integrar a todas las pantallas:

```
Pantalla: lib/screen/home.dart
- [ ] Importar: import '../system/index.dart';
- [ ] Envolver: return ErrorHandlerScreen(child: Scaffold(...));
- [ ] Reemplazar: ErrorSnackBar.show() → context.showError()
- [ ] Agregar: context.showSuccess() para confirmaciones
- [ ] Agregar: context.showWarning() para advertencias

Pantalla: lib/screen/login.dart
- [ ] Importar
- [ ] Envolver
- [ ] Reemplazar
- [ ] Agregar

... (repetir para cada pantalla)
```

## 🎯 Ventajas del Sistema

✅ **Centralizado** - Un único lugar para gestionar errores
✅ **Automático** - Se inyecta en cualquier pantalla
✅ **Flexible** - Configurable por pantalla
✅ **Consistente** - UI uniforme en toda la app
✅ **Fácil de usar** - Extensión de contexto simple
✅ **Escalable** - Soporta múltiples errores simultáneamente
✅ **Reutilizable** - Funciona con cualquier pantalla

## 🔧 Configuración Avanzada

### Personalizar por pantalla

```dart
ErrorHandlerScreen(
  child: Scaffold(...),
  showErrorBanner: true,      // Mostrar banners
  showErrorSnackBar: true,    // Mostrar snackbars
  showErrorDialog: false,     // No mostrar diálogos
)
```

### Agregar reintentos

```dart
context.showError(
  message: 'Error de conexión',
  title: 'Error',
  onRetry: () {
    _loadData(); // Función a reintentar
  },
);
```

### Duración personalizada

```dart
context.showError(
  message: 'Error',
  duration: Duration(seconds: 5), // Mostrar 5 segundos
);
```

## 📚 Documentación Completa

Para más detalles, consulta:
- `lib/system/ERROR_HANDLER_SYSTEM_README.md` - Documentación completa
- `lib/system/error_handler_integration_guide.dart` - Ejemplos de código
- `lib/widgets/error_widgets.dart` - Componentes base

## 🚀 Próximos Pasos

1. **Integrar a home.dart** (pantalla principal)
2. **Integrar a login.dart** (autenticación)
3. **Integrar a transacciones.dart** (operaciones)
4. **Integrar a todas las demás pantallas**
5. **Reemplazar ErrorSnackBar.show() con context.showError()**

## 💡 Ejemplo Completo

```dart
import '../system/index.dart';

class MiPantalla extends StatefulWidget {
  @override
  State<MiPantalla> createState() => _MiPantallaState();
}

class _MiPantallaState extends State<MiPantalla> {
  Future<void> _loadData() async {
    try {
      // Cargar datos
      await Future.delayed(Duration(seconds: 2));
      
      if (mounted) {
        context.showSuccess(
          message: 'Datos cargados',
          title: 'Éxito',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          message: 'Error: $e',
          title: 'Error de carga',
          onRetry: _loadData,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      child: Scaffold(
        appBar: AppBar(title: Text('Mi Pantalla')),
        body: Center(child: Text('Contenido')),
      ),
    );
  }
}
```

---

**Sistema creado y listo para usar en todas las pantallas de la aplicación** ✅
