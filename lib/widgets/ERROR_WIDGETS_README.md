# Widgets Personalizados de Manejo de Errores

Este documento explica cómo usar los widgets personalizados de manejo de errores en la aplicación.

## Archivos Creados

1. **`lib/utils/auth_error_handler.dart`** - Clase para traducir errores de Firebase a mensajes amigables
2. **`lib/widgets/error_widgets.dart`** - Widgets personalizados para mostrar errores
3. **`lib/widgets/error_widgets_example.dart`** - Ejemplos de uso

## Componentes Disponibles

### 1. AuthErrorHandler

Clase utilitaria para convertir códigos de error de Firebase en mensajes amigables en español.

```dart
import '../utils/auth_error_handler.dart';

// Obtener mensaje desde código de error
String message = AuthErrorHandler.getErrorMessage('invalid-email');
// Resultado: "El correo electrónico no es válido"

// Obtener mensaje desde una excepción
try {
  await authService.signIn(email, password);
} catch (e) {
  String friendlyMessage = AuthErrorHandler.getFriendlyMessage(e);
  // Muestra un mensaje amigable en lugar del error técnico
}
```

### 2. ErrorSnackBar

SnackBar personalizado que aparece en la parte superior de la pantalla con animación de deslizamiento.

**Características:**
- Aparece desde arriba con animación suave
- Se desliza hacia arriba al desaparecer
- Se puede cerrar tocándolo
- Auto-dismiss después de la duración especificada
- Colores diferentes para errores y éxitos

```dart
import '../widgets/error_widgets.dart';

// Mostrar error (aparece arriba con animación)
ErrorSnackBar.show(
  context,
  message: 'Contraseña incorrecta',
  isError: true,
);

// Mostrar éxito
ErrorSnackBar.show(
  context,
  message: '¡Inicio de sesión exitoso!',
  isError: false,
);

// Con duración personalizada
ErrorSnackBar.show(
  context,
  message: 'Este mensaje dura 5 segundos',
  isError: true,
  duration: Duration(seconds: 5),
);
```

**Animación:**
- Entrada: Desliza desde arriba hacia abajo (400ms, easeOutCubic)
- Salida: Desliza hacia arriba (400ms)
- El usuario puede cerrar tocando el mensaje

**Colores:**
- Error: Rojo fuerte (#d32f2f) 🔴
- Éxito: Verde fuerte (#4CAF50) 🟢

### 3. ErrorBanner

Banner inline para mostrar errores dentro de formularios.

```dart
// Banner básico
ErrorBanner(
  message: 'El correo electrónico no es válido',
)

// Banner con botón de cerrar
ErrorBanner(
  message: 'Error de validación',
  onDismiss: () {
    // Acción al cerrar
  },
)

// Banner personalizado
ErrorBanner(
  message: 'Advertencia importante',
  icon: Icons.info_outline,
  backgroundColor: Color(0xFFe3f2fd),
  iconColor: Color(0xFF1976d2),
  textColor: Color(0xFF0d47a1),
)
```

### 4. ErrorDialog

Diálogo modal para mostrar errores importantes.

```dart
// Mostrar diálogo de error
ErrorDialog.show(
  context,
  title: 'Error de autenticación',
  message: 'No se pudo iniciar sesión. Verifica tus credenciales.',
  buttonText: 'Entendido',
  onPressed: () {
    // Acción opcional al presionar el botón
  },
);

// O usar el widget directamente
showDialog(
  context: context,
  builder: (context) => ErrorDialog(
    title: 'Error',
    message: 'Algo salió mal',
    buttonText: 'OK',
  ),
);
```

### 5. ErrorBottomSheet

Bottom sheet para mostrar errores con opción de reintentar.

```dart
ErrorBottomSheet.show(
  context,
  title: 'Error de conexión',
  message: 'No se pudo conectar al servidor. Verifica tu conexión a internet.',
  buttonText: 'Reintentar',
  icon: Icons.wifi_off,
  onPressed: () {
    // Acción al presionar reintentar
    _retryConnection();
  },
);
```

## Ejemplos de Uso Completo

### En un formulario de Login

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  Future<void> _signIn() async {
    try {
      await authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: '¡Bienvenido!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthErrorHandler.getFriendlyMessage(e);
        
        // Opción 1: Mostrar en SnackBar
        ErrorSnackBar.show(
          context,
          message: errorMessage,
          isError: true,
        );
        
        // Opción 2: Mostrar en Dialog
        ErrorDialog.show(
          context,
          message: errorMessage,
        );
        
        // Opción 3: Mostrar en BottomSheet
        ErrorBottomSheet.show(
          context,
          message: errorMessage,
          buttonText: 'Reintentar',
          onPressed: () => _signIn(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        if (_emailError != null)
          ErrorBanner(message: _emailError!),
        
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
        ),
        if (_passwordError != null)
          ErrorBanner(message: _passwordError!),
        
        ElevatedButton(
          onPressed: _signIn,
          child: Text('Sign In'),
        ),
      ],
    );
  }
}
```

## Códigos de Error Soportados

El `AuthErrorHandler` traduce los siguientes códigos de error de Firebase:

### Errores de Email/Contraseña
- `invalid-email` → "El correo electrónico no es válido"
- `user-disabled` → "Esta cuenta ha sido deshabilitada"
- `user-not-found` → "No existe una cuenta con este correo"
- `wrong-password` → "Contraseña incorrecta"
- `email-already-in-use` → "Este correo ya está registrado"
- `weak-password` → "La contraseña es muy débil"

### Errores de Red
- `network-request-failed` → "Error de conexión. Verifica tu internet"
- `too-many-requests` → "Demasiados intentos. Intenta más tarde"

### Errores de Google Sign In
- `account-exists-with-different-credential` → "Ya existe una cuenta con este correo usando otro método"
- `invalid-credential` → "Las credenciales no son válidas"
- `popup-closed-by-user` → "Inicio de sesión cancelado"

### Otros
- Cualquier error no reconocido → "Ocurrió un error inesperado. Intenta de nuevo"

## Personalización

Todos los widgets aceptan parámetros de personalización:

```dart
ErrorBanner(
  message: 'Tu mensaje',
  icon: Icons.tu_icono,
  backgroundColor: Color(0xFFtuColor),
  textColor: Color(0xFFtuColor),
  iconColor: Color(0xFFtuColor),
)
```

## Mejores Prácticas

1. **Usa ErrorSnackBar** para mensajes rápidos y no críticos
2. **Usa ErrorDialog** para errores que requieren atención del usuario
3. **Usa ErrorBottomSheet** para errores con opción de reintentar
4. **Usa ErrorBanner** para validaciones inline en formularios
5. **Siempre usa AuthErrorHandler** para traducir errores de Firebase
6. **Verifica `mounted`** antes de mostrar errores en widgets async

```dart
try {
  await someAsyncOperation();
} catch (e) {
  if (mounted) {  // ← Importante!
    ErrorSnackBar.show(context, message: e.toString());
  }
}
```
