import 'package:flutter/material.dart';
import 'system.dart';

/// Guía para aplicar la configuración del sistema a TODAS las pantallas de la app
///
/// PASO 1: En main.dart, asegurar la configuración inicial
/// ```dart
/// void main() {
///   AndroidSystemConfig.configureSystemBars();
///   runApp(const MainApp());
/// }
/// ```
///
/// PASO 2: Reemplazar todos los Scaffold por SystemAwareScaffold
///
/// ANTES:
/// ```dart
/// class MiPantalla extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Mi Pantalla')),
///       body: MiContenido(),
///     );
///   }
/// }
/// ```
///
/// DESPUÉS:
/// ```dart
/// class MiPantalla extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return SystemAwareScaffold(
///       appBar: AppBar(title: Text('Mi Pantalla')),
///       body: MiContenido(),
///     );
///   }
/// }
/// ```

/// Ejemplo de cómo convertir una pantalla existente
class ExampleConversion {
  /// ANTES - Pantalla original sin configuración del sistema
  static Widget oldScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla Original'),
        backgroundColor: Colors.blue,
      ),
      body: const Column(
        children: [
          Text('Contenido que puede quedar detrás de las barras'),
          Spacer(),
          Text('Footer que puede quedar detrás de la navegación'),
        ],
      ),
    );
  }

  /// DESPUÉS - Pantalla convertida con configuración del sistema
  static Widget newScreen() {
    return SystemAwareScaffold(
      appBar: AppBar(
        title: const Text('Pantalla Convertida'),
        backgroundColor: Colors.blue,
      ),
      body: const Column(
        children: [
          Text('Contenido que respeta la barra de estado'),
          Spacer(),
          Text('Footer que respeta la barra de navegación'),
        ],
      ),
    );
  }
}

/// Plantilla base para nuevas pantallas
class ScreenTemplate extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const ScreenTemplate({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return SystemAwareScaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Plantilla para pantallas sin AppBar
class NoAppBarTemplate extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const NoAppBarTemplate({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return SystemAwareScaffold(
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Plantilla para pantallas fullscreen
class FullScreenTemplate extends StatelessWidget {
  final Widget child;
  final bool showStatusBar;
  final bool showNavigationBar;

  const FullScreenTemplate({
    super.key,
    required this.child,
    this.showStatusBar = true,
    this.showNavigationBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FullScreenSystemAware(
        respectStatusBar: showStatusBar,
        respectNavigationBar: showNavigationBar,
        child: child,
      ),
    );
  }
}

/// Utilidades para verificar la configuración del sistema
class SystemUtils {
  /// Verifica si las barras del sistema están configuradas correctamente
  static void checkSystemConfiguration(BuildContext context) {
    final statusHeight = context.statusBarHeight;
    final navHeight = context.navigationBarHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColor = isDark
        ? AndroidSystemConfig.darkSystemBarColor
        : AndroidSystemConfig.lightSystemBarColor;

    debugPrint('=== CONFIGURACIÓN DEL SISTEMA ===');
    debugPrint('Altura barra de estado: ${statusHeight}px');
    debugPrint('Altura barra de navegación: ${navHeight}px');
    debugPrint('Color configurado: $currentColor');
    debugPrint('Modo: ${isDark ? "Oscuro" : "Claro"}');
    debugPrint('================================');
  }

  /// Muestra información del sistema en un diálogo
  static void showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Sistema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barra de estado: ${context.statusBarHeight}px'),
            Text('Barra de navegación: ${context.navigationBarHeight}px'),
            const Text('Color barras: #282827'),
            const Text('Íconos: Blancos/Claros'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
