# 🚀 Guía Rápida - Widgets de Error

## Uso Básico en 3 Pasos

### 1️⃣ Importar
```dart
import 'package:salud_mental/widgets/error_widgets.dart';
import 'package:salud_mental/utils/auth_error_handler.dart';
```

### 2️⃣ Usar en try-catch
```dart
try {
  await authService.signIn(email, password);
  
  ErrorSnackBar.show(
    context,
    message: '¡Bienvenido!',
    isError: false,
  );
} catch (e) {
  ErrorSnackBar.show(
    context,
    message: AuthErrorHandler.getFriendlyMessage(e),
    isError: true,
  );
}
```

### 3️⃣ ¡Listo! 🎉

---

## 📱 Tipos de Widgets

### ErrorSnackBar (Aparece arriba con animación)
```dart
ErrorSnackBar.show(context, message: 'Tu mensaje', isError: true);
```

### ErrorBanner (Inline en formularios)
```dart
if (error != null) ErrorBanner(message: error)
```

### ErrorDialog (Modal)
```dart
ErrorDialog.show(context, message: 'Error importante');
```

### ErrorBottomSheet (Con botón de acción)
```dart
ErrorBottomSheet.show(
  context,
  message: 'Error',
  buttonText: 'Reintentar',
  onPressed: () => retry(),
);
```

---

## 🎨 Ver Demo

Para ver todos los ejemplos en acción:

```dart
import 'package:salud_mental/widgets/error_demo_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ErrorDemoScreen()),
);
```

---

## ✅ Ya Implementado En:

- ✅ `lib/login/login.dart`
- ✅ `lib/login/sign_up.dart`

Puedes usar el mismo patrón en cualquier otra pantalla de tu app.
