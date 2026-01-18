import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'password_screen.dart';
import '../system/index.dart';
import '../utils/auth_error_handler.dart';
import '../widgets/error_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final FocusNode _userFocusNode = FocusNode();
  bool _userLabelUp = false; // Controla si el label está arriba
  bool _isLoading = false; // Para mostrar loading mientras verifica

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el focus
    _userFocusNode.addListener(_onUserFocusChange);
    // Escuchar cambios en el texto
    _userController.addListener(_onUserTextChange);
  }

  void _onUserFocusChange() {
    setState(() {
      // Si tiene focus o tiene texto, el label sube
      _userLabelUp = _userFocusNode.hasFocus || _userController.text.isNotEmpty;
    });
  }

  void _onUserTextChange() {
    setState(() {
      // Si tiene texto, el label se queda arriba
      _userLabelUp = _userFocusNode.hasFocus || _userController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _userFocusNode.removeListener(_onUserFocusChange);
    _userController.removeListener(_onUserTextChange);
    _userFocusNode.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// Obtiene el device_id según la plataforma (móvil o web)
  /// Combina 3 métodos para mayor confiabilidad:
  /// 1. Android ID / iOS Identifier
  /// 2. Fingerprint del dispositivo
  /// 3. UUID persistente generado al instalar la app
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      // En web: usar combinación de browser info + UUID persistente
      try {
        final webInfo = await deviceInfo.webBrowserInfo;
        final browserName = webInfo.browserName.name;
        final platform = webInfo.platform ?? 'unknown';

        // Obtener o crear UUID persistente para esta instalación web
        String? webUuid = prefs.getString('web_device_uuid');
        if (webUuid == null) {
          webUuid = const Uuid().v4();
          await prefs.setString('web_device_uuid', webUuid);
        }

        // Combinar todo para un ID más único
        final combined = 'web_${browserName}_${platform}_$webUuid';
        debugPrint('Web Device ID: $combined');
        return combined;
      } catch (e) {
        debugPrint('Error obteniendo web info: $e');
        return 'web_unknown_${const Uuid().v4()}';
      }
    } else {
      // En móvil: combinar múltiples identificadores
      try {
        if (Theme.of(context).platform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;

          // 1. Android ID (único por app + dispositivo + usuario)
          final androidId = androidInfo.id;

          // 2. Fingerprint (combinación de hardware)
          final fingerprint = androidInfo.fingerprint;

          // 3. UUID persistente (generado al instalar la app)
          String? appUuid = prefs.getString('app_device_uuid');
          if (appUuid == null) {
            appUuid = const Uuid().v4();
            await prefs.setString('app_device_uuid', appUuid);
          }

          // Información adicional del dispositivo
          final model = androidInfo.model;
          final brand = androidInfo.brand;

          // Combinar todo para un ID súper único
          final combined =
              'android_${androidId}_${fingerprint.hashCode}_${model}_${brand}_$appUuid';
          debugPrint('Android Device ID: $combined');
          return combined;
        } else if (Theme.of(context).platform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;

          // 1. Identifier for Vendor (único por app + dispositivo)
          final iosId = iosInfo.identifierForVendor ?? 'unknown';

          // 2. Modelo del dispositivo
          final model = iosInfo.model;

          // 3. UUID persistente
          String? appUuid = prefs.getString('app_device_uuid');
          if (appUuid == null) {
            appUuid = const Uuid().v4();
            await prefs.setString('app_device_uuid', appUuid);
          }

          final combined = 'ios_${iosId}_${model}_$appUuid';
          debugPrint('iOS Device ID: $combined');
          return combined;
        }
      } catch (e) {
        debugPrint('Error obteniendo device_id: $e');
      }

      // Fallback: solo UUID persistente
      String? fallbackUuid = prefs.getString('app_device_uuid');
      if (fallbackUuid == null) {
        fallbackUuid = const Uuid().v4();
        await prefs.setString('app_device_uuid', fallbackUuid);
      }
      return 'unknown_$fallbackUuid';
    }
  }

  /// Valida y actualiza el device_id
  /// Retorna true si puede continuar, false si hay error de dispositivo
  Future<bool> _validateAndUpdateDeviceId(
    DocumentSnapshot doc,
    String username,
  ) async {
    final data = doc.data() as Map<String, dynamic>?;
    final storedDeviceId = data?['device_id']?.toString() ?? '';
    final currentDeviceId = await _getDeviceId();

    if (storedDeviceId.isEmpty) {
      // Primera vez: guardar el device_id actual
      await FirebaseFirestore.instance.collection('users').doc(username).update(
        {'device_id': currentDeviceId},
      );
      debugPrint('Device ID guardado por primera vez: $currentDeviceId');
      return true;
    } else {
      // Ya existe device_id: comparar con el actual
      if (storedDeviceId == currentDeviceId) {
        debugPrint('Device ID coincide: $currentDeviceId');
        return true;
      } else {
        debugPrint(
          'Device ID NO coincide. Guardado: $storedDeviceId, Actual: $currentDeviceId',
        );
        return false;
      }
    }
  }

  void _showDeviceError() {
    ErrorDialog.show(
      context,
      title: 'Dispositivo no autorizado',
      message:
          'Esta cuenta está vinculada a otro dispositivo. '
          'Por seguridad, no puedes iniciar sesión desde este dispositivo.\n\n'
          'Si necesitas cambiar de dispositivo, contacta a soporte.',
      buttonText: 'Entendido',
    );
  }

  void _login() async {
    final username = _userController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar si el usuario existe en la colección 'users'
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .get();

      if (doc.exists) {
        // Usuario existe, validar device_id
        final deviceValid = await _validateAndUpdateDeviceId(doc, username);

        if (!deviceValid) {
          // Dispositivo diferente: mostrar error
          if (mounted) {
            setState(() => _isLoading = false);
            _showDeviceError();
          }
          return;
        }

        // Device_id válido, navegar a PasswordScreen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PasswordScreen(username: username),
            ),
          );
        }
      } else {
        // Usuario no existe, mostrar error
        if (mounted) {
          ErrorSnackBar.show(
            context,
            message: 'Usuario no encontrado',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Error de conexión
      if (mounted) {
        final errorMessage = AuthErrorHandler.getFriendlyMessage(e);
        ErrorSnackBar.show(context, message: errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Variables para posicionar el icono X (ajusta estos valores)
    final double xPosX = screenW * 0.05; // Posición horizontal (90% del ancho)
    final double xPosY = screenH * 0.025; // Posición vertical (2% del alto)
    final double xSize = screenW * 0.08; // Tamaño relativo (6% del ancho)
    final double chevronSize =
        screenW * 0.05; // Tamaño del chevron (ajusta este valor)

    // Variables para controlar la animación del label "Ingrese su usuario"
    final double labelStartX =
        screenW * 0.13; // Posición X inicial (al lado del icono)
    final double labelStartY = screenH * 0.12 * 0.32; // Posición Y inicial
    final double labelEndX =
        screenW * 0.04; // Posición X final (arriba del icono)
    final double labelEndY =
        screenH * 0.25 * 0.08; // Posición Y final (ajusta este valor)

    // Variables para controlar la posición del TextField (donde escribes)
    final double textFieldX = screenW * 0.13; // Posición X del TextField
    final double textFieldY = screenH * 0.18 * 0.25; // Posición Y del TextField

    // Variable para el tamaño del círculo (ajusta este valor)
    final double circleSize = screenW * 0.4;
    // Variable para el tamaño de la animación Lottie (ajusta este valor)
    final double lottieSize = screenW * 2.0;
    // Variables para la posición del círculo (ajusta estos valores)
    final double circlePosX = screenW * 0.52; // Centro horizontal
    final double circlePosY = screenH * 0.65; // Posición vertical
    // Variables para la posición de la animación Lottie (ajusta estos valores)
    final double lottiePosX = screenW * 0.5; // Centro horizontal
    final double lottiePosY = screenH * 0.5; // Posición vertical

    // Variables para el icono fingerprint dentro del círculo (ajusta estos valores)
    final double fingerprintSize =
        circleSize * 0.35; // Tamaño del icono (50% del círculo)
    final double fingerprintOffsetX =
        0.0; // Offset X dentro del círculo (0 = centrado)
    final double fingerprintOffsetY =
        0.0; // Offset Y dentro del círculo (0 = centrado)

    return SystemAwareScaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: Stack(
            children: [
              // Contenido principal
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenH * 0.02),
                    // Icono CIB centrado
                    Center(
                      child: SvgPicture.asset(
                        'assets/icons/CIB.svg',
                        width: screenW * 0.04,
                        height: screenH * 0.04,
                        fit: BoxFit.contain,
                        colorFilter: isDark
                            ? const ColorFilter.mode(
                                Color(0xFFF2F2F4),
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: screenH * 0.02),
                    // Texto ¡Hola!
                    Text(
                      '¡Hola!',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.08,
                        color: isDark ? const Color(0xFFF2F2F4) : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenH * 0.05),
                    // Cuadrado debajo del Hola (como los de preview)
                    Container(
                      width: screenW * 0.95,
                      height: screenH * 0.12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF454648)
                            : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Stack(
                        children: [
                          // Icono pic-user arriba de la línea
                          Positioned(
                            left: screenW * 0.04,
                            top: screenH * 0.12 * 0.35, // Arriba de la línea
                            child: SvgPicture.asset(
                              'assets/icons/pic-user.svg',
                              width: screenW * 0.06,
                              height: screenW * 0.06,
                              colorFilter: ColorFilter.mode(
                                isDark ? const Color(0xFFF2F2F4) : Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          // Texto "Ingrese su usuario" con animación
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            left: _userLabelUp ? labelEndX : labelStartX,
                            top: _userLabelUp ? labelEndY : labelStartY,
                            child: GestureDetector(
                              onTap: () {
                                _userFocusNode.requestFocus();
                              },
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: _userLabelUp
                                      ? screenW * 0.03
                                      : screenW * 0.04,
                                  color: isDark
                                      ? const Color(0xFFF2F2F4)
                                      : Colors.grey,
                                ),
                                child: const Text('Ingrese su usuario'),
                              ),
                            ),
                          ),
                          // TextField para capturar el texto
                          Positioned(
                            left: textFieldX,
                            top: textFieldY,
                            right: screenW * 0.05,
                            child: TextField(
                              controller: _userController,
                              focusNode: _userFocusNode,
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.04,
                                color: isDark
                                    ? const Color(0xFFF2F2F4)
                                    : Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          // Línea horizontal un poco más abajo de la mitad (con márgenes)
                          Positioned(
                            left: screenW * 0.05,
                            right: screenW * 0.05,
                            top: screenH * 0.12 * 0.6, // 60% desde arriba
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 2,
                              color: _userController.text.isNotEmpty
                                  ? const Color(
                                      0xFFFFD700,
                                    ) // Amarillo cuando hay texto
                                  : (isDark
                                        ? const Color(0xFF5A5A5C)
                                        : const Color(0xFFE0E0E0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenH * 0.03),
                    // Botón Continuar
                    SizedBox(
                      width: screenW * 0.95,
                      height: screenH * 0.05,
                      child: ElevatedButton(
                        onPressed:
                            (_userController.text.isNotEmpty && !_isLoading)
                            ? _login
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _userController.text.isNotEmpty
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF9E9E9E).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          disabledBackgroundColor: const Color(
                            0xFF9E9E9E,
                          ).withValues(alpha: 0.5),
                        ),
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            fontFamily: 'OpenSansSemibold',
                            fontSize: screenW * 0.045,
                            color: _userController.text.isNotEmpty
                                ? Colors.black
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.04),
                    // Texto subrayado "¿Olvidaste tu usuario o clave?"
                    GestureDetector(
                      onTap: () {
                        // Acción al tocar
                      },
                      child: Text(
                        '¿Olvidaste tu usuario o clave?',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.035,
                          color: isDark
                              ? const Color(0xFFF2F2F4)
                              : Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.35),
                    // Texto subrayado "¿Aún no tienes usuario o cuenta?"
                    GestureDetector(
                      onTap: () {
                        // Acción al tocar
                      },
                      child: Text(
                        '¿Aún no tienes usuario o cuenta?',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.035,
                          color: isDark
                              ? const Color(0xFFF2F2F4)
                              : Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.02),
                  ],
                ),
              ),
              // Animación Lottie posicionada (debajo del círculo)
              Positioned(
                left: lottiePosX - lottieSize / 2,
                top: lottiePosY - lottieSize / 2,
                child: IgnorePointer(
                  child: Lottie.asset(
                    'assets/trazos/06_animate.json',
                    width: lottieSize,
                    height: lottieSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Círculo posicionado (encima del Lottie) con icono fingerprint
              Positioned(
                left: circlePosX - circleSize / 2,
                top: circlePosY - circleSize / 2,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF353537) : Colors.white,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(
                            fingerprintOffsetX,
                            fingerprintOffsetY,
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/pic-id-fingerprint.svg',
                            width: fingerprintSize,
                            height: fingerprintSize,
                            colorFilter: ColorFilter.mode(
                              isDark ? const Color(0xFFF2F2F4) : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        SizedBox(height: screenH * 0.01),
                        Text(
                          'Ingresa con\nhuella',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.03,
                            color: isDark
                                ? const Color(0xFFF2F2F4)
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Icono X posicionable con texto "Cerrar"
              Positioned(
                left: xPosX,
                top: xPosY,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close,
                        size: xSize,
                        color: isDark ? const Color(0xFFF2F2F4) : Colors.black,
                      ),
                      Text(
                        'Cerrar',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.05,
                          color: isDark
                              ? const Color(0xFFF2F2F4)
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Texto "Continuar>" en el lado derecho
              Positioned(
                right: xPosX,
                top: xPosY,
                child: GestureDetector(
                  onTap: () {
                    // Acción de continuar
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continuar',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.05,
                          color: isDark
                              ? const Color(0xFFF2F2F4)
                              : Colors.black,
                        ),
                      ),

                      SizedBox(width: screenW * 0.02),
                      ColorFiltered(
                        colorFilter: isDark
                            ? const ColorFilter.mode(
                                Color(0xFFF2F2F4),
                                BlendMode.srcIn,
                              )
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              ),
                        child: Image.asset(
                          'assets/icons/pic-chevron-right.png',
                          width: chevronSize,
                          height: chevronSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
