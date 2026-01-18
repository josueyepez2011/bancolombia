import 'package:flutter/material.dart';
import 'error_widgets.dart';
import '../utils/auth_error_handler.dart';

/// Ejemplos de uso de los widgets de error personalizados
class ErrorWidgetsExample {
  
  /// Ejemplo 1: Mostrar error de autenticación con ErrorSnackBar
  static void showAuthError(BuildContext context, dynamic error) {
    final errorMessage = AuthErrorHandler.getFriendlyMessage(error);
    ErrorSnackBar.show(
      context,
      message: errorMessage,
      isError: true,
    );
  }

  /// Ejemplo 2: Mostrar mensaje de éxito con ErrorSnackBar
  static void showSuccessMessage(BuildContext context, String message) {
    ErrorSnackBar.show(
      context,
      message: message,
      isError: false,
    );
  }

  /// Ejemplo 3: Mostrar error de red con ErrorDialog
  static void showNetworkError(BuildContext context) {
    ErrorDialog.show(
      context,
      title: 'Sin conexión',
      message: 'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      buttonText: 'Entendido',
    );
  }

  /// Ejemplo 4: Mostrar error con opción de reintentar usando ErrorBottomSheet
  static void showRetryError(BuildContext context, VoidCallback onRetry) {
    ErrorBottomSheet.show(
      context,
      title: 'Error al cargar datos',
      message: 'No se pudieron cargar los datos. ¿Deseas intentar de nuevo?',
      buttonText: 'Reintentar',
      onPressed: onRetry,
    );
  }

  /// Ejemplo 5: Widget con ErrorBanner inline
  static Widget buildFormWithErrorBanner(String? errorMessage) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            border: OutlineInputBorder(),
          ),
        ),
        if (errorMessage != null)
          ErrorBanner(
            message: errorMessage,
            onDismiss: () {
              // Limpiar el error
            },
          ),
      ],
    );
  }

  /// Ejemplo 6: Manejo completo de errores en un login
  static Future<void> handleLogin(
    BuildContext context,
    String username,
    String password,
  ) async {
    try {
      // Simular login
      await Future.delayed(Duration(seconds: 2));
      
      // Si es exitoso
      if (context.mounted) {
        ErrorSnackBar.show(
          context,
          message: '¡Bienvenido!',
          isError: false,
        );
      }
    } catch (e) {
      // Si hay error
      if (context.mounted) {
        final errorMessage = AuthErrorHandler.getFriendlyMessage(e);
        
        // Si es error de red, mostrar diálogo
        if (AuthErrorHandler.isNetworkError(e)) {
          ErrorDialog.show(
            context,
            title: 'Error de conexión',
            message: errorMessage,
            buttonText: 'Reintentar',
            onPressed: () => handleLogin(context, username, password),
          );
        } else {
          // Otros errores, mostrar snackbar
          ErrorSnackBar.show(
            context,
            message: errorMessage,
            isError: true,
          );
        }
      }
    }
  }
}
