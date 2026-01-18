import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'system.dart';

/// Soluciones para problemas comunes con las barras del sistema
class SystemBarTroubleshooting {
  /// Aplica la configuración de manera ultra agresiva
  /// Usar si las barras siguen siendo blancas
  static void ultraAggressiveConfig(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final barColor = isDark
        ? AndroidSystemConfig.darkSystemBarColor
        : AndroidSystemConfig.lightSystemBarColor;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    // Configurar múltiples veces para asegurar que se aplique
    for (int i = 0; i < 3; i++) {
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
  }

  /// Configuración específica para dispositivos problemáticos
  static void deviceSpecificConfig(Brightness brightness) {
    // Primero configurar el modo UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Esperar un frame y aplicar colores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AndroidSystemConfig.configureForBrightness(brightness);
    });
  }

  /// Widget de diagnóstico para verificar la configuración
  static Widget diagnosticWidget(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final currentColor = isDark
        ? AndroidSystemConfig.darkSystemBarColor
        : AndroidSystemConfig.lightSystemBarColor;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'DIAGNÓSTICO DEL SISTEMA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text('Color configurado: $currentColor'),
          Text('Modo: ${isDark ? "Oscuro" : "Claro"}'),
          const Text(
            'Si las barras son blancas, hay un problema de configuración',
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              ultraAggressiveConfig(brightness);
            },
            child: const Text('Forzar Configuración'),
          ),
        ],
      ),
    );
  }
}

/// Widget que aplica configuración continua
class ContinuousSystemConfig extends StatefulWidget {
  final Widget child;

  const ContinuousSystemConfig({super.key, required this.child});

  @override
  State<ContinuousSystemConfig> createState() => _ContinuousSystemConfigState();
}

class _ContinuousSystemConfigState extends State<ContinuousSystemConfig> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Aplicar configuración cada segundo (solo para debugging)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      SystemBarTroubleshooting.ultraAggressiveConfig(brightness);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Instrucciones paso a paso para solucionar problemas
class TroubleshootingInstructions {
  static const String instructions = '''
SOLUCIÓN PARA BARRAS BLANCAS:

1. VERIFICAR EN MAIN.DART:
   - Debe tener: WidgetsFlutterBinding.ensureInitialized();
   - Debe llamar: AndroidSystemConfig.configureSystemBars();

2. SI SIGUEN BLANCAS, USAR CONFIGURACIÓN AGRESIVA:
   - Llamar: SystemBarTroubleshooting.ultraAggressiveConfig(brightness);
   - En cada pantalla que tenga problemas

3. PARA DISPOSITIVOS ESPECÍFICOS:
   - Usar: SystemBarTroubleshooting.deviceSpecificConfig(brightness);
   - En lugar de la configuración normal

4. VERIFICAR EN ANDROID/APP/SRC/MAIN/RES/VALUES/STYLES.XML:
   - Debe tener: <item name="android:statusBarColor">@android:color/transparent</item>
   - Debe tener: <item name="android:navigationBarColor">@android:color/transparent</item>

5. SI NADA FUNCIONA:
   - Usar ContinuousSystemConfig como wrapper de toda la app
   - Solo para debugging, no para producción
''';
}
