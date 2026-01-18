import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'system.dart';

/// Configuraciones avanzadas del sistema Android
class AdvancedSystemConfig {
  /// Configuración para pantallas específicas que necesitan comportamiento diferente
  static void configureForSpecificScreen({
    Color? statusBarColor,
    Color? navigationBarColor,
    Brightness? statusBarIconBrightness,
    Brightness? navigationBarIconBrightness,
    Brightness themeBrightness = Brightness.dark,
  }) {
    final defaultColor = themeBrightness == Brightness.dark
        ? AndroidSystemConfig.darkSystemBarColor
        : AndroidSystemConfig.lightSystemBarColor;
    final defaultIconBrightness = themeBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? defaultColor,
        statusBarIconBrightness:
            statusBarIconBrightness ?? defaultIconBrightness,
        statusBarBrightness: statusBarIconBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: navigationBarColor ?? defaultColor,
        systemNavigationBarIconBrightness:
            navigationBarIconBrightness ?? defaultIconBrightness,
        systemNavigationBarDividerColor: navigationBarColor ?? defaultColor,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  /// Restaura la configuración por defecto
  static void restoreDefaultConfiguration() {
    AndroidSystemConfig.configureSystemBars();
  }

  /// Configuración para modo inmersivo (oculta barras temporalmente)
  static void enableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Restaura las barras del sistema después del modo inmersivo
  static void exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    AndroidSystemConfig.configureSystemBars();
  }
}

/// Widget para pantallas que necesitan configuración temporal del sistema
class TemporarySystemConfig extends StatefulWidget {
  final Widget child;
  final Color? temporaryStatusBarColor;
  final Color? temporaryNavigationBarColor;
  final Brightness? temporaryStatusBarIconBrightness;
  final Brightness? temporaryNavigationBarIconBrightness;

  const TemporarySystemConfig({
    super.key,
    required this.child,
    this.temporaryStatusBarColor,
    this.temporaryNavigationBarColor,
    this.temporaryStatusBarIconBrightness,
    this.temporaryNavigationBarIconBrightness,
  });

  @override
  State<TemporarySystemConfig> createState() => _TemporarySystemConfigState();
}

class _TemporarySystemConfigState extends State<TemporarySystemConfig> {
  @override
  void initState() {
    super.initState();
    // Aplicar configuración temporal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdvancedSystemConfig.configureForSpecificScreen(
        statusBarColor: widget.temporaryStatusBarColor,
        navigationBarColor: widget.temporaryNavigationBarColor,
        statusBarIconBrightness: widget.temporaryStatusBarIconBrightness,
        navigationBarIconBrightness:
            widget.temporaryNavigationBarIconBrightness,
      );
    });
  }

  @override
  void dispose() {
    // Restaurar configuración por defecto al salir
    AdvancedSystemConfig.restoreDefaultConfiguration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Widget para pantallas en modo inmersivo
class ImmersiveScreen extends StatefulWidget {
  final Widget child;
  final bool autoExitOnTap;

  const ImmersiveScreen({
    super.key,
    required this.child,
    this.autoExitOnTap = true,
  });

  @override
  State<ImmersiveScreen> createState() => _ImmersiveScreenState();
}

class _ImmersiveScreenState extends State<ImmersiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdvancedSystemConfig.enableImmersiveMode();
    });
  }

  @override
  void dispose() {
    AdvancedSystemConfig.exitImmersiveMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    if (widget.autoExitOnTap) {
      child = GestureDetector(
        onTap: () {
          AdvancedSystemConfig.exitImmersiveMode();
        },
        child: child,
      );
    }

    return Scaffold(body: SizedBox.expand(child: child));
  }
}

/// Mixin para pantallas que necesitan manejar cambios del sistema
mixin SystemAwareMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // Asegurar configuración del sistema
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AndroidSystemConfig.configureSystemBars();
    });
  }

  /// Obtiene información actual del sistema
  SystemInfo get systemInfo => SystemInfo(
    statusBarHeight: MediaQuery.of(context).viewPadding.top,
    navigationBarHeight: MediaQuery.of(context).viewPadding.bottom,
    safeAreaPadding: MediaQuery.of(context).padding,
  );
}

/// Clase para almacenar información del sistema
class SystemInfo {
  final double statusBarHeight;
  final double navigationBarHeight;
  final EdgeInsets safeAreaPadding;

  const SystemInfo({
    required this.statusBarHeight,
    required this.navigationBarHeight,
    required this.safeAreaPadding,
  });

  @override
  String toString() {
    return 'SystemInfo(statusBar: ${statusBarHeight}px, navigationBar: ${navigationBarHeight}px)';
  }
}

/// Ejemplos de uso de configuraciones avanzadas
class AdvancedExamples {
  /// Ejemplo de pantalla con configuración temporal
  static Widget temporaryConfigExample() {
    return TemporarySystemConfig(
      temporaryStatusBarColor: Colors.red,
      temporaryNavigationBarColor: Colors.red,
      child: const SystemAwareScaffold(
        body: Center(
          child: Text(
            'Pantalla con barras rojas temporalmente',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Ejemplo de pantalla inmersiva
  static Widget immersiveExample() {
    return const ImmersiveScreen(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fullscreen, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Modo Inmersivo\nToca para salir',
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
