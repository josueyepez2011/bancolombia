import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase/firebase_options.dart';
import 'login/login_screen.dart'; // Importa la pantalla de login
import 'screen/preview_screen.dart'; // Importa la pantalla de preview
import 'system/index.dart'; // Importa la configuración del sistema Android
import 'system/theme_provider.dart';

// Provider global del tema
final themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Inicializa el binding primero

  // Bloquear orientación a solo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Autenticación anónima para permitir acceso a Firestore
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint('Error en autenticación anónima: $e');
  }

  AndroidSystemConfig.configureSystemBars(); // Configura las barras del sistema
  // Aplica los colores según el tema actual del sistema
  final brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;
  AndroidSystemConfig.configureForBrightness(brightness);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Limpiar sesión cuando la app se cierra o pasa a background
    if (state == AppLifecycleState.detached) {
      _clearSessionOnClose();
    }
  }

  /// Limpia el session_token cuando la app se cierra
  Future<void> _clearSessionOnClose() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedUsername = prefs.getString('logged_username') ?? '';
      final sessionToken = prefs.getString('session_token') ?? '';

      // Solo limpiar si hay sesión válida (no duplicada)
      if (loggedUsername.isNotEmpty &&
          sessionToken.isNotEmpty &&
          sessionToken != 'DUPLICATE_SESSION') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(loggedUsername)
            .update({'session_token': ''});
      }
    } catch (e) {
      debugPrint('Error limpiando sesión: $e');
    }
  }

  @override
  void didChangePlatformBrightness() {
    // Actualiza los colores de las barras cuando cambia el tema del sistema
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AndroidSystemConfig.configureForBrightness(brightness);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F2F4),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF2C2C2C),
          ),
          home: const LogoPantalla(),
        );
      },
    );
  }
}

class LogoPantalla extends StatefulWidget {
  const LogoPantalla({super.key});

  @override
  State<LogoPantalla> createState() => _LogoPantallaState();
}

class _LogoPantallaState extends State<LogoPantalla> {
  int counter = 1;
  Timer? timer;

  // Posición relativa del contador (0.0 a 1.0)
  double xFactor = 0.5; // centro horizontal
  double yFactor = 0.85; // debajo de la animación

  @override
  void initState() {
    super.initState();
    // Contador rápido
    timer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (counter >= 99) {
        t.cancel();
        // Navegar automáticamente a PreviewScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PreviewScreen()),
        );
      } else {
        setState(() {
          counter++;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double anchoPantalla = MediaQuery.of(context).size.width;
    final double altoPantalla = MediaQuery.of(context).size.height;
    final double tRel = anchoPantalla * 0.5;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Tamaño relativo del contador
    final double contadorFontSize =
        anchoPantalla * 0.06; // 5% del ancho de pantalla
    final double porcentajeFontSize =
        anchoPantalla * 0.055; // un poco más pequeño

    return PopScope(
      canPop: false, // Desactiva el botón "back"
      child: Scaffold(
        body: AbsorbPointer(
          absorbing: true,
          child: Stack(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animación Lottie
                    Lottie.asset(
                      'assets/trazos/trazo_splash.json',
                      width: anchoPantalla,
                      fit: BoxFit.contain,
                    ),
                    // Logo SVG centrado
                    SvgPicture.asset(
                      'assets/images/brand-Bancolombia-primario-positivo.svg',
                      width: tRel * 0.4,
                      height: tRel * 0.4,
                      colorFilter: isDarkMode
                          ? const ColorFilter.mode(
                              Color(0xFFF2F2F4),
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              // Contador posicionable
              Positioned(
                left:
                    anchoPantalla * xFactor -
                    contadorFontSize, // centra el contador
                top: altoPantalla * yFactor,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      counter.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: contadorFontSize,
                        fontFamily: 'RegularCustom',
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: porcentajeFontSize,
                        fontFamily: 'RegularCustom',
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
