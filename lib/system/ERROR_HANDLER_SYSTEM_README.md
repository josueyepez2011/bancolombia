# Sistema Activo de Manejo de Errores

Este sistema proporciona un gestor centralizado de errores y advertencias que se puede aplicar a **todas las pantallas** de la aplicación.

## Características

✅ **Sistema singleton** - Una única instancia para toda la app
✅ **Inyección automática** - Envuelve cualquier pantalla con `ErrorHandlerScreen`
✅ **Múltiples tipos** - Error, Advertencia, Éxito
✅ **UI personalizada** - Banners, SnackBars, Diálogos
✅ **Extensión de contexto** - Acceso fácil desde cualquier widget
✅ **Cola de errores** - Maneja múltiples errores simultáneamente

## Instalación

El sistema ya está exportado en `lib/system/index.dart`:

```dart
import '../system/index.dart';
```

## Uso Básico

### 1. Envolver una pantalla

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

### 2. Mostrar errores desde cualquier lugar

```dart
// Usando la extensión de contexto (recomendado)
context.showError(
  message: 'No se pudo cargar los datos',
  title: 'Error de conexión',
);

// O usando el sistema directamente
ErrorHandlerSystem.showError(
  context,
  message: 'No se pudo cargar los datos',
  title: 'Error de conexión',
);
```

### 3. Mostrar advertencias

```dart
context.showWarning(
  message: 'Esta acción no se puede deshacer',
  title: 'Advertencia',
);
```

### 4. Mostrar éxito

```dart
context.showSuccess(
  message: '¡Datos guardados correctamente!',
  title: 'Éxito',
);
```

## Ejemplos Completos

### Ejemplo 1: Pantalla con manejo de errores

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    try {
      // Simular login
      await Future.delayed(Duration(seconds: 2));
      
      if (mounted) {
        context.showSuccess(
          message: '¡Bienvenido!',
          title: 'Inicio de sesión exitoso',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          message: 'No se pudo iniciar sesión: $e',
          title: 'Error de autenticación',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      child: Scaffold(
        appBar: AppBar(title: Text('Iniciar Sesión')),
        body: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Ejemplo 2: Pantalla con reintentos

```dart
class DataScreen extends StatefulWidget {
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  Future<void> _loadData() async {
    try {
      // Cargar datos
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      if (mounted) {
        context.showError(
          message: 'No se pudieron cargar los datos',
          title: 'Error',
          onRetry: _loadData, // Permite reintentar
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
        appBar: AppBar(title: Text('Datos')),
        body: Center(child: Text('Contenido')),
      ),
    );
  }
}
```

### Ejemplo 3: Múltiples pantallas con el mismo sistema

```dart
// En main.dart o en tu navegación
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ErrorHandlerScreen(
        child: HomeScreen(),
      ),
      routes: {
        '/login': (context) => ErrorHandlerScreen(
          child: LoginScreen(),
        ),
        '/profile': (context) => ErrorHandlerScreen(
          child: ProfileScreen(),
        ),
        '/settings': (context) => ErrorHandlerScreen(
          child: SettingsScreen(),
        ),
      },
    );
  }
}
```

## Configuración del ErrorHandlerScreen

```dart
ErrorHandlerScreen(
  child: MiPantalla(),
  
  // Mostrar banners de error inline (default: true)
  showErrorBanner: true,
  
  // Mostrar SnackBars (default: true)
  showErrorSnackBar: true,
  
  // Mostrar diálogos para errores críticos (default: false)
  showErrorDialog: false,
)
```

## API del ErrorHandlerSystem

### Métodos principales

```dart
// Agregar error
ErrorHandlerSystem().addError(
  message: 'Mensaje de error',
  title: 'Título',
  type: ErrorType.error,
  duration: Duration(seconds: 3),
  onRetry: () { /* acción de reintento */ },
);

// Agregar advertencia
ErrorHandlerSystem().addWarning(
  message: 'Mensaje de advertencia',
  title: 'Advertencia',
  duration: Duration(seconds: 3),
);

// Agregar éxito
ErrorHandlerSystem().addSuccess(
  message: 'Mensaje de éxito',
  title: 'Éxito',
  duration: Duration(seconds: 2),
);

// Remover error específico
ErrorHandlerSystem().removeError(error);

// Limpiar todos los errores
ErrorHandlerSystem().clearAll();

// Obtener lista de errores
List<ErrorMessage> errors = ErrorHandlerSystem().errors;

// Escuchar cambios
ErrorHandlerSystem().errorNotifier.addListener(() {
  print('Errores actualizados: ${ErrorHandlerSystem().errors.length}');
});
```

## Extensión de Contexto

Desde cualquier widget, puedes usar:

```dart
// Mostrar error
context.showError(
  message: 'Mensaje',
  title: 'Error',
  duration: Duration(seconds: 3),
  onRetry: () { /* reintento */ },
);

// Mostrar advertencia
context.showWarning(
  message: 'Mensaje',
  title: 'Advertencia',
  duration: Duration(seconds: 3),
);

// Mostrar éxito
context.showSuccess(
  message: 'Mensaje',
  title: 'Éxito',
  duration: Duration(seconds: 2),
);
```

## Tipos de Errores

```dart
enum ErrorType {
  error,      // Rojo - Errores críticos
  warning,    // Naranja - Advertencias
  success,    // Verde - Mensajes de éxito
}
```

## Colores por Tipo

| Tipo | Color | Icono |
|------|-------|-------|
| Error | Rojo (#d32f2f) | error_outline |
| Warning | Naranja (#e67e22) | warning_rounded |
| Success | Verde (#4CAF50) | check_circle_outline |

## Mejores Prácticas

1. **Envuelve todas tus pantallas** con `ErrorHandlerScreen`
2. **Usa la extensión de contexto** para acceso fácil
3. **Siempre verifica `mounted`** antes de mostrar errores en async
4. **Personaliza la duración** según el tipo de mensaje
5. **Proporciona opciones de reintento** para errores de red
6. **Usa títulos descriptivos** para cada tipo de error

## Ejemplo de Integración Completa

```dart
// En lib/screen/home.dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _loadUserData() async {
    try {
      // Cargar datos del usuario
      await Future.delayed(Duration(seconds: 2));
      
      if (mounted) {
        context.showSuccess(
          message: 'Datos cargados correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          message: 'No se pudieron cargar los datos: $e',
          title: 'Error de carga',
          onRetry: _loadUserData,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      showErrorBanner: true,
      showErrorSnackBar: true,
      child: Scaffold(
        appBar: AppBar(title: Text('Home')),
        body: Center(child: Text('Contenido')),
      ),
    );
  }
}
```

## Troubleshooting

### Los errores no aparecen
- Asegúrate de que la pantalla está envuelta con `ErrorHandlerScreen`
- Verifica que `showErrorBanner` o `showErrorSnackBar` esté en `true`

### Los errores no se limpian
- Los errores se limpian automáticamente después de la duración especificada
- Puedes limpiar manualmente con `ErrorHandlerSystem().clearAll()`

### Múltiples errores se superponen
- El sistema muestra máximo 2 errores simultáneamente
- Los demás se encolan y aparecen cuando se cierren los anteriores

