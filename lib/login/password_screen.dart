import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/home.dart';
import '../system/index.dart';
import '../utils/auth_error_handler.dart';
import '../widgets/error_widgets.dart';

class PasswordScreen extends StatefulWidget {
  final String username;

  const PasswordScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _passController = TextEditingController();
  final FocusNode _passFocusNode = FocusNode();

  // Controladores de animación para cada dígito
  late List<AnimationController> _bounceControllers;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();
    _passFocusNode.addListener(_onPassFocusChange);
    _passController.addListener(_onPassTextChange);

    // Inicializar controladores de animación para cada dígito
    _bounceControllers = List.generate(4, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
    });
  }

  void _onPassFocusChange() {
    setState(() {});
  }

  void _onPassTextChange() {
    int currentLength = _passController.text.length;

    // Si se agregó un nuevo dígito, animar ese dígito
    if (currentLength > _previousLength && currentLength <= 4) {
      _bounceControllers[currentLength - 1].forward(from: 0.0).then((_) {
        _bounceControllers[currentLength - 1].reverse();
      });
    }

    _previousLength = currentLength;
    setState(() {});
  }

  @override
  void dispose() {
    _passFocusNode.removeListener(_onPassFocusChange);
    _passController.removeListener(_onPassTextChange);
    _passFocusNode.dispose();
    _passController.dispose();
    for (var controller in _bounceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isLoading = false;

  // Tiempo de expiración de sesión en minutos
  static const int sessionExpirationMinutes = 10;

  /// Genera un token de sesión único
  String _generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Verifica si la sesión existente ha expirado
  bool _isSessionExpired(int? sessionTimestamp) {
    if (sessionTimestamp == null) return true;

    final sessionTime = DateTime.fromMillisecondsSinceEpoch(sessionTimestamp);
    final now = DateTime.now();
    final difference = now.difference(sessionTime);

    return difference.inMinutes >= sessionExpirationMinutes;
  }

  void _login() async {
    if (_passController.text.length != 4) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.username)
          .get();

      if (doc.exists && doc.data()?['pin'].toString() == _passController.text) {
        final data = doc.data();
        final existingToken = data?['session_token']?.toString() ?? '';
        final sessionTimestamp = data?['session_timestamp'] as int?;
        final prefs = await SharedPreferences.getInstance();

        // Obtener token local guardado
        final localToken = prefs.getString('session_token') ?? '';

        // Verificar si ya hay una sesión activa Y no ha expirado
        final bool hasActiveSession = existingToken.isNotEmpty;
        final bool isExpired = _isSessionExpired(sessionTimestamp);

        // Es el mismo dispositivo si el token local coincide con Firebase
        final bool isSameDevice =
            localToken.isNotEmpty &&
            localToken != 'DUPLICATE_SESSION' &&
            localToken == existingToken;

        // Solo es sesión duplicada si hay sesión activa, no expiró, Y es otro dispositivo
        final bool isDuplicateSession =
            hasActiveSession && !isExpired && !isSameDevice;

        if (isDuplicateSession) {
          // Ya hay sesión activa en OTRO dispositivo: mostrar diálogo
          await prefs.setString('logged_username', widget.username);
          await prefs.setString('session_token', 'DUPLICATE_SESSION');
        } else {
          // No hay sesión, expiró, o es el mismo dispositivo: crear/renovar sesión
          final sessionToken = _generateSessionToken();
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.username)
              .update({
                'session_token': sessionToken,
                'session_timestamp': timestamp,
              });

          await prefs.setString('logged_username', widget.username);
          await prefs.setString('session_token', sessionToken);
        }

        // Navegar al home
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(fromPasswordScreen: true),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ErrorSnackBar.show(context, message: 'PIN incorrecto', isError: true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMessage = AuthErrorHandler.getFriendlyMessage(e);
        ErrorSnackBar.show(context, message: errorMessage, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Variables para posicionar el icono X (ajusta estos valores)
    final double xPosX = screenW * 0.05; // Posición horizontal
    final double xPosY = screenH * 0.025; // Posición vertical
    final double chevronSize = screenW * 0.05;

    // Variables para el círculo de carga
    final double circleSize = screenW * 0.4;
    final double circlePosX = screenW * 0.5;
    final double circlePosY = screenH * 0.5;

    // Variable para controlar el eje X del trazo 2
    final double trazo2OffsetX = screenW * -0.11;
    // Variable para controlar el ancho (eje X) del trazo 2
    final double trazo2Width = screenW * 0.09;

    return SystemAwareScaffold(
      body: Stack(
        children: [
          // Trazo SVG decorativo - posición relativa
          Positioned(
            left: screenW * -0.085,
            top: screenH * 0.12,
            child: SvgPicture.asset(
              'assets/trazos/trazo_contrasena.svg',
              width: screenW * 0.1,
              height: screenH * 0.1,
              fit: BoxFit.cover,
            ),
          ),
          // Trazo SVG decorativo 2 - posición relativa
          Positioned(
            right: trazo2OffsetX,
            top: screenH * 0.18,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(trazo2Width / (screenW * 0.1), 1.0),
              child: SvgPicture.asset(
                'assets/trazos/trazo_contrasena2.svg',
                width: screenW * 0.1,
                height: screenH * 0.1,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Botón Cerrar (izquierda)
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
                  Transform.scale(
                    scaleX: -1,
                    child: ColorFiltered(
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
                  ),
                  SizedBox(width: screenW * 0.02),
                  Text(
                    'Volver',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.04,
                      color: isDark ? const Color(0xFFF2F2F4) : Colors.black,
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
                    'Ingresar',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.04,
                      color: isDark ? const Color(0xFFF2F2F4) : Colors.black,
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
                  'Iniciar sesión',
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
                    fontSize: screenW * 0.06,
                    color: isDark ? const Color(0xFFF2F2F4) : Colors.black,
                  ),
                ),
                SizedBox(height: screenH * 0.05),
                // Cuadrado para contraseña
                Container(
                  width: screenW * 1.0,
                  height: screenH * 0.18,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF454648)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Stack(
                    children: [
                      // Icono pic-lock centrado en la parte superior
                      Positioned(
                        left: 0,
                        right: 0,
                        top: screenH * 0.02,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/pic-lock.svg',
                            width: screenW * 0.065,
                            height: screenW * 0.065,
                            colorFilter: ColorFilter.mode(
                              isDark ? const Color(0xFFF2F2F4) : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      // Texto centrado debajo del icono
                      Positioned(
                        left: 0,
                        right: 0,
                        top: screenH * 0.05,
                        child: Center(
                          child: Text(
                            'Ingresa la clave que usas en el cajero',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.03,
                              color: isDark
                                  ? const Color(0xFFF2F2F4)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // TextField oculto para capturar la contraseña
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            _passFocusNode.requestFocus();
                          },
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // TextField invisible
                      Positioned(
                        left: -1000,
                        child: SizedBox(
                          width: 1,
                          child: TextField(
                            controller: _passController,
                            focusNode: _passFocusNode,
                            obscureText: false,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                        ),
                      ),
                      // Dígitos visibles encima de las líneas
                      Positioned(
                        left: screenW * 0.1,
                        right: screenW * 0.1,
                        top: screenH * 0.09,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            String digit = index < _passController.text.length
                                ? '*'
                                : '';
                            return Container(
                              width: screenW * 0.10,
                              margin: EdgeInsets.symmetric(
                                horizontal: screenW * 0.015,
                              ),
                              child: Center(
                                child: Text(
                                  digit,
                                  style: TextStyle(
                                    fontSize: screenW * 0.05,
                                    color: isDark
                                        ? const Color(0xFFF2F2F4)
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // Líneas debajo de los campos PIN con animación de rebote
                      Positioned(
                        left: screenW * 0.15,
                        right: screenW * 0.15,
                        top: screenH * 0.13,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return AnimatedBuilder(
                              animation: _bounceControllers[index],
                              builder: (context, child) {
                                double offset =
                                    _bounceControllers[index].value * 5;
                                return Transform.translate(
                                  offset: Offset(0, offset),
                                  child: Container(
                                    width: screenW * 0.10,
                                    height: 2,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: screenW * 0.015,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index < _passController.text.length
                                          ? const Color(0xFFFFD700)
                                          : const Color(0xFF9E9E9E),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
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
                    onPressed: _passController.text.length == 4 && !_isLoading
                        ? _login
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _passController.text.length == 4
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
                      'Ingresar',
                      style: TextStyle(
                        fontFamily: 'OpenSansSemibold',
                        fontSize: screenW * 0.045,
                        color: _passController.text.length == 4
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Círculo de carga cuando _isLoading es true
          if (_isLoading) ...[
            // Fondo borroso
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
            ),
            // Círculo con spinner y texto
            Positioned(
              left: circlePosX - circleSize / 2,
              top: circlePosY - circleSize / 2,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF353537) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: circleSize * 0.35,
                      height: circleSize * 0.35,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : const Color(0xFFFFDD00),
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.02),
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.04,
                        color: isDark
                            ? const Color(0xFF9E9E9E)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
