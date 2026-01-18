import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configuración del sistema Android para barras de estado y navegación
class AndroidSystemConfig {
  // Colores para modo oscuro
  static const Color darkSystemBarColor = Color(0xFF333335);
  // Colores para modo claro
  static const Color lightSystemBarColor = Color(0xFF333335);

  /// Configura las barras del sistema Android (estado y navegación)
  /// Debe llamarse al inicio de la aplicación
  static void configureSystemBars() {
    // Configurar el modo de visualización primero
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Configura las barras según el tema actual (claro/oscuro)
  static void configureForBrightness(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color barColor = isDark ? darkSystemBarColor : lightSystemBarColor;
    // Iconos siempre blancos (Brightness.light = iconos claros/blancos)
    const Brightness iconBrightness = Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: barColor,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: barColor,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarDividerColor: barColor,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  /// Configuración más agresiva que se aplica en cada pantalla
  static void forceSystemBarColors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    configureForBrightness(brightness);
  }

  /// Obtiene el SystemUiOverlayStyle según el tema
  static SystemUiOverlayStyle getOverlayStyle(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color barColor = isDark ? darkSystemBarColor : lightSystemBarColor;
    // Iconos siempre blancos (Brightness.light = iconos claros/blancos)
    const Brightness iconBrightness = Brightness.light;

    return SystemUiOverlayStyle(
      statusBarColor: barColor,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: barColor,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: barColor,
      systemNavigationBarContrastEnforced: false,
    );
  }

  /// Widget wrapper que aplica la configuración del sistema
  /// y maneja correctamente las áreas seguras
  static Widget wrapWithSystemConfig({
    required Widget child,
    required Brightness brightness,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: getOverlayStyle(brightness),
      child: child,
    );
  }
}

/// Widget base que debe usarse como contenedor principal
/// en todas las pantallas de la aplicación
class SystemAwareScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const SystemAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Forzar la configuración del sistema en cada build
    AndroidSystemConfig.forceSystemBarColors(context);

    return AndroidSystemConfig.wrapWithSystemConfig(
      brightness: brightness,
      child: Scaffold(
        appBar: appBar,
        body: SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: body,
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        backgroundColor: backgroundColor,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      ),
    );
  }
}

/// Widget para contenido que necesita ocupar toda la pantalla
/// pero respetando las áreas del sistema
class FullScreenSystemAware extends StatelessWidget {
  final Widget child;
  final bool respectStatusBar;
  final bool respectNavigationBar;

  const FullScreenSystemAware({
    super.key,
    required this.child,
    this.respectStatusBar = true,
    this.respectNavigationBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AndroidSystemConfig.wrapWithSystemConfig(
      brightness: brightness,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.loose,
        children: [
          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Widget que fuerza la configuración del sistema en cada frame
class SystemBarForcer extends StatefulWidget {
  final Widget child;

  const SystemBarForcer({super.key, required this.child});

  @override
  State<SystemBarForcer> createState() => _SystemBarForcerState();
}

class _SystemBarForcerState extends State<SystemBarForcer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Reaplica la configuración cuando cambia el tema del sistema
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AndroidSystemConfig.configureForBrightness(brightness);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reaplica la configuración cuando la app vuelve al primer plano
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      AndroidSystemConfig.configureForBrightness(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extensión para obtener información de las áreas del sistema
extension SystemPadding on BuildContext {
  /// Obtiene el padding superior (altura de la barra de estado)
  double get statusBarHeight => MediaQuery.of(this).viewPadding.top;

  /// Obtiene el padding inferior (altura de la barra de navegación)
  double get navigationBarHeight => MediaQuery.of(this).viewPadding.bottom;

  /// Obtiene el padding total del sistema
  EdgeInsets get systemPadding => MediaQuery.of(this).viewPadding;

  /// Obtiene las áreas seguras del sistema
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
}
