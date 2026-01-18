/// EJEMPLO: Cómo integrar ErrorHandlerSystem en home.dart
/// 
/// Este archivo muestra exactamente cómo modificar home.dart
/// para usar el nuevo sistema de errores.

import 'package:flutter/material.dart';
import 'error_handler_system.dart';

/// CAMBIOS NECESARIOS EN home.dart:
/// 
/// 1. AGREGAR IMPORT:
///    import '../system/index.dart';
/// 
/// 2. ENVOLVER EL BUILD CON ErrorHandlerScreen:
///    
///    @override
///    Widget build(BuildContext context) {
///      return ErrorHandlerScreen(
///        child: Scaffold(
///          // ... resto del código
///        ),
///      );
///    }
/// 
/// 3. REEMPLAZAR ErrorSnackBar.show() CON context.showError():
///    
///    // ANTES:
///    ErrorSnackBar.show(
///      context,
///      message: 'Sesión cerrada: se inició sesión en otro dispositivo',
///      isError: true,
///    );
///    
///    // DESPUÉS:
///    context.showError(
///      message: 'Sesión cerrada: se inició sesión en otro dispositivo',
///      title: 'Sesión cerrada',
///    );

/// EJEMPLO ESPECÍFICO PARA home.dart:

class HomeScreenWithErrorHandler extends StatefulWidget {
  final bool fromPasswordScreen;

  const HomeScreenWithErrorHandler({
    super.key,
    this.fromPasswordScreen = false,
  });

  @override
  State<HomeScreenWithErrorHandler> createState() =>
      _HomeScreenWithErrorHandlerState();
}

class _HomeScreenWithErrorHandlerState
    extends State<HomeScreenWithErrorHandler> {
  @override
  void initState() {
    super.initState();
    // Aquí iría el código de inicialización
  }

  /// Método de logout actualizado
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Código de logout aquí...
      
      // ANTES (viejo):
      // ErrorSnackBar.show(
      //   context,
      //   message: 'Sesión cerrada correctamente',
      //   isError: false,
      // );
      
      // DESPUÉS (nuevo):
      if (context.mounted) {
        context.showSuccess(
          message: 'Sesión cerrada correctamente',
          title: 'Sesión cerrada',
        );
      }
    } catch (e) {
      // ANTES (viejo):
      // ErrorSnackBar.show(
      //   context,
      //   message: 'Error al cerrar sesión',
      //   isError: true,
      // );
      
      // DESPUÉS (nuevo):
      if (context.mounted) {
        context.showError(
          message: 'Error al cerrar sesión: $e',
          title: 'Error',
        );
      }
    }
  }

  /// Método para mostrar error de sesión duplicada
  void _showDuplicateSessionError() {
    // ANTES (viejo):
    // ErrorDialog.show(
    //   context,
    //   title: 'Sesión activa',
    //   message: 'Esta sesión ya está iniciada en otro dispositivo...',
    //   buttonText: 'Cerrar',
    //   onPressed: _forceLogoutDuplicate,
    // );
    
    // DESPUÉS (nuevo):
    context.showError(
      message: 'Esta sesión ya está iniciada en otro dispositivo.\n\n'
          'Solo puedes tener una sesión activa a la vez.',
      title: 'Sesión activa',
    );
  }

  /// Método para mostrar error de conexión
  void _showNetworkError() {
    context.showError(
      message: 'No se pudo conectar al servidor. Verifica tu conexión.',
      title: 'Error de conexión',
      onRetry: () {
        // Aquí va la función para reintentar
      },
    );
  }

  /// Método para mostrar advertencia
  void _showWarning(String message) {
    context.showWarning(
      message: message,
      title: 'Advertencia',
    );
  }

  /// Método para mostrar éxito
  void _showSuccess(String message) {
    context.showSuccess(
      message: message,
      title: 'Éxito',
    );
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: Envolver todo con ErrorHandlerScreen
    return ErrorHandlerScreen(
      // Configuración del ErrorHandlerScreen
      showErrorBanner: true,      // Mostrar banners inline
      showErrorSnackBar: true,    // Mostrar snackbars desde arriba
      showErrorDialog: false,     // No mostrar diálogos (usamos banners)
      
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón para probar error
              ElevatedButton(
                onPressed: () {
                  context.showError(
                    message: 'Este es un error de ejemplo',
                    title: 'Error',
                  );
                },
                child: const Text('Mostrar Error'),
              ),
              const SizedBox(height: 16),
              
              // Botón para probar advertencia
              ElevatedButton(
                onPressed: () {
                  context.showWarning(
                    message: 'Esta es una advertencia de ejemplo',
                    title: 'Advertencia',
                  );
                },
                child: const Text('Mostrar Advertencia'),
              ),
              const SizedBox(height: 16),
              
              // Botón para probar éxito
              ElevatedButton(
                onPressed: () {
                  context.showSuccess(
                    message: 'Operación completada exitosamente',
                    title: 'Éxito',
                  );
                },
                child: const Text('Mostrar Éxito'),
              ),
              const SizedBox(height: 16),
              
              // Botón para probar logout
              ElevatedButton(
                onPressed: () => _handleLogout(context),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// RESUMEN DE CAMBIOS:
/// 
/// 1. Importar el sistema:
///    import '../system/index.dart';
/// 
/// 2. Envolver el Scaffold con ErrorHandlerScreen:
///    return ErrorHandlerScreen(
///      child: Scaffold(...),
///    );
/// 
/// 3. Reemplazar todos los ErrorSnackBar.show() con context.showError():
///    - context.showError() para errores
///    - context.showWarning() para advertencias
///    - context.showSuccess() para confirmaciones
/// 
/// 4. Reemplazar ErrorDialog.show() con context.showError():
///    - El sistema maneja automáticamente la visualización
/// 
/// 5. Agregar onRetry para errores de red:
///    context.showError(
///      message: 'Error de conexión',
///      onRetry: () => _loadData(),
///    );

/// VENTAJAS DE ESTE CAMBIO:
/// 
/// ✅ Código más limpio y legible
/// ✅ Consistencia en toda la app
/// ✅ Manejo centralizado de errores
/// ✅ UI uniforme para todos los errores
/// ✅ Fácil de mantener y actualizar
/// ✅ Soporte para reintentos automáticos
/// ✅ Mejor experiencia de usuario
