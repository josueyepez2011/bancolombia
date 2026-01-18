import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'qr_guardados_screen.dart';
import 'victimas_bancolombia_screen.dart';

import '../system/index.dart';
import '../main.dart' show themeProvider;
import 'transacciones.dart';

class AjusteScreen extends StatefulWidget {
  const AjusteScreen({super.key});

  @override
  State<AjusteScreen> createState() => _AjusteScreenState();
}

class _AjusteScreenState extends State<AjusteScreen> {
  double _saldoFirebase = 0; // Saldo de la base de datos (solo lectura)
  double _saldoHome = 0; // Saldo que se muestra en home (editable)
  String _userName = '';
  String _loggedUsername = '';
  String _numeroCuenta = ''; // Número de cuenta personalizado

  // Función para formatear números con puntos cada 3 dígitos
  String _formatNumber(double number) {
    String numStr = number.toInt().toString();
    String result = '';
    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      count++;
      result = numStr[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadLoggedUsername();
    _loadUserName();
    _loadSaldoHome();
    _loadNumeroCuenta();
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLoggedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedUsername = prefs.getString('logged_username') ?? '';
    _loadSaldoFromFirebase();
  }

  Future<void> _loadSaldoFromFirebase() async {
    if (_loggedUsername.isEmpty) {
      debugPrint('No hay usuario logueado');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_loggedUsername)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        final saldo = data?['saldo'];
        setState(() {
          _saldoFirebase = (saldo is num) ? saldo.toDouble() : 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error cargando saldo: $e');
    }
  }

  Future<void> _loadSaldoHome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saldoHome = prefs.getDouble('saldo_reserva') ?? 0;
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
    });
  }

  Future<void> _saveUserName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', value);
  }

  Future<void> _loadNumeroCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _numeroCuenta = prefs.getString('numero_cuenta_personalizado') ?? '';
    });
  }

  Future<void> _saveNumeroCuenta(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('numero_cuenta_personalizado', value);
  }

  void _editarNumeroCuenta() {
    final controller = TextEditingController(text: _numeroCuenta);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2634) : const Color(0xFFF0FAFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de tarjeta estilo cyan
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  'Tu número de cuenta',
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
                    fontSize: 20,
                    color: isDark ? Colors.white : const Color(0xFF1A2634),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ingresa los 11 dígitos',
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 20),
                // Campo de texto estilo cyan
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
                    fontSize: 22,
                    letterSpacing: 3,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '00000000000',
                    hintStyle: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: 20,
                      letterSpacing: 3,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white,
                    counterStyle: const TextStyle(
                      fontFamily: 'OpenSansRegular',
                      color: Color(0xFF00BCD4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00BCD4),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Botones estilo cyan
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white : Colors.black12,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: 15,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BCD4).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _numeroCuenta = controller.text;
                            });
                            _saveNumeroCuenta(controller.text);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(
                              fontFamily: 'OpenSansBold',
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editarNombre() async {
    final TextEditingController controller = TextEditingController(
      text: _userName,
    );

    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2D2D3A), const Color(0xFF1A1A24)]
                    : [const Color(0xFFFFFDF5), const Color(0xFFFFF8E1)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono decorativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Título con estilo
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ).createShader(bounds),
                  child: const Text(
                    '¿Cómo te llamas?',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personaliza tu experiencia',
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 24),
                // Campo de texto estilizado
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tu nombre aquí',
                      hintStyle: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: 18,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Botones estilizados
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: 16,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context, controller.text.trim());
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(
                              fontFamily: 'OpenSansBold',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _userName = result;
      });
      await _saveUserName(result);
    }
  }

  Future<void> _saveSaldoHome(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saldo_reserva', value);
  }

  Future<void> _updateSaldoFirebase(double nuevoSaldo) async {
    if (_loggedUsername.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_loggedUsername)
          .update({'saldo': nuevoSaldo});

      setState(() {
        _saldoFirebase = nuevoSaldo;
      });
    } catch (e) {
      debugPrint('Error actualizando saldo en Firebase: $e');
    }
  }

  void _editarSaldo() async {
    final TextEditingController controller = TextEditingController(
      text: _saldoHome.toInt().toString(),
    );
    String? errorText;
    final double saldoTotalDisponible = _saldoFirebase + _saldoHome;

    final result = await showDialog<double>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2E1A)
                      : const Color(0xFFF0FAF0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.25),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono de dinero estilo verde
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Título
                    Text(
                      'Editar tu saldo',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: 20,
                        color: isDark ? Colors.white : const Color(0xFF1A2E1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Disponible: \$ ${_formatNumber(saldoTotalDisponible)}',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: 13,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Campo de texto estilo verde
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: 28,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: 28,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        errorText: errorText,
                        errorStyle: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF4CAF50),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value) ?? 0;
                        setDialogState(() {
                          if (parsed > saldoTotalDisponible) {
                            errorText =
                                'Máximo: \$ ${_formatNumber(saldoTotalDisponible)}';
                          } else if (parsed < 0) {
                            errorText = 'No puede ser negativo';
                          } else {
                            errorText = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Botones estilo verde
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: 15,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () {
                                final value =
                                    double.tryParse(controller.text) ?? 0;
                                if (value > saldoTotalDisponible) {
                                  setDialogState(() {
                                    errorText =
                                        'Máximo: \$ ${_formatNumber(saldoTotalDisponible)}';
                                  });
                                  return;
                                }
                                if (value < 0) {
                                  setDialogState(() {
                                    errorText = 'No puede ser negativo';
                                  });
                                  return;
                                }
                                Navigator.pop(context, value);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontFamily: 'OpenSansBold',
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && result >= 0 && result <= saldoTotalDisponible) {
      // Calcular la diferencia entre el nuevo valor y el actual
      final diferencia = result - _saldoHome;
      // Nuevo saldo en Firebase = actual - diferencia
      // Si diferencia es positiva (subió el Home), se resta de Firebase
      // Si diferencia es negativa (bajó el Home), se suma a Firebase
      final nuevoSaldoFirebase = _saldoFirebase - diferencia;

      setState(() {
        _saldoHome = result;
      });
      await _saveSaldoHome(result);
      await _updateSaldoFirebase(nuevoSaldoFirebase);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar themeProvider directamente para obtener el estado del tema
    final bool isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    final Color bgColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF5F5F7);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Ajustes',
            style: TextStyle(fontFamily: 'RegularCustom', color: textColor),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Fondo con trazo SVG (tamaño y posición relativos)
          Positioned(
            right: screenWidth * 0.0,
            bottom: screenHeight * 0.3,
            child: SvgPicture.asset(
              'assets/trazos/trazo-comprobante.svg',
              width: screenWidth * 1.0,
              height: screenWidth * 1.0,
            ),
          ),
          // Contenido con scroll
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildGlassNombreUsuario(textColor, isDark),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QrGuardadosScreen(),
                        ),
                      );
                    },
                    child: _buildGlassQrMenuItem(
                      textColor: textColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassSaldoReserva(textColor, isDark),
                  const SizedBox(height: 12),
                  // Configurar Bancolombia víctimas
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VictimasNequiScreen(),
                        ),
                      );
                    },
                    child: _buildGlassMenuItem(
                      context,
                      icon: 'assets/icons/pic-cards.svg',
                      title: 'Configurar Bancolombia víctimas',
                      textColor: textColor,
                      isDark: isDark,
                      iconColor: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Personalizar cuenta
                  GestureDetector(
                    onTap: _editarNumeroCuenta,
                    child: _buildGlassMenuItem(
                      context,
                      icon: 'assets/icons/settings.svg',
                      title: 'Personalizar cuenta',
                      textColor: textColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dos tarjetas en columnas - Modo oscuro/claro
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildThemeCard(
                            title: 'Modo oscuro',
                            textColor: textColor,
                            isDark: isDark,
                            isSelected: isDark,
                            phoneBgColor: const Color(0xFF2C2C2C),
                            onTap: () async {
                              await themeProvider.setThemeMode(ThemeMode.dark);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildThemeCard(
                            title: 'Modo claro',
                            textColor: textColor,
                            isDark: isDark,
                            isSelected: !isDark,
                            phoneBgColor: const Color(0xFFF5F5F7),
                            onTap: () async {
                              await themeProvider.setThemeMode(ThemeMode.light);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _AjusteBottomNavBar(isDark: isDark),
      ),
    );
  }

  // Widget contenedor con efecto glassmorphism
  Widget _buildGlassContainer({
    required Widget child,
    required bool isDark,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassMenuItem(
    BuildContext context, {
    required String icon,
    required String title,
    required Color textColor,
    required bool isDark,
    Color? iconColor,
  }) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(
              iconColor ?? textColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'RegularCustom',
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: textColor),
        ],
      ),
    );
  }

  Widget _buildGlassSquareCard({
    required IconData icon,
    required String title,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.8)),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: const Color(0xFFFFD700)),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'RegularCustom',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required Color textColor,
    required bool isDark,
    required bool isSelected,
    required Color phoneBgColor,
    required VoidCallback onTap,
  }) {
    final bool isPhoneDark = phoneBgColor == const Color(0xFF2C2C2C);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.8)),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de celular con fondo
                Container(
                  width: 56,
                  height: 90,
                  decoration: BoxDecoration(
                    color: phoneBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Notch del celular
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isPhoneDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Grid de apps (3x3)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Fila 1
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildMiniApp(Colors.red.shade400),

                                  _buildMiniApp(Colors.green.shade400),

                                  _buildMiniApp(Colors.blue.shade400),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Fila 2
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildMiniApp(Colors.orange.shade400),
                                  _buildMiniApp(Colors.purple.shade400),
                                  _buildMiniApp(Colors.teal.shade400),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Fila 3
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildMiniApp(Colors.pink.shade400),
                                  _buildMiniApp(const Color(0xFFFFD700)),
                                  _buildMiniApp(Colors.cyan.shade400),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Barra inferior (dock)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        width: 36,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isPhoneDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'RegularCustom',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniApp(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildGlassQrMenuItem({
    required Color textColor,
    required bool isDark,
  }) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.qr_code,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'QRs cuentas Bancolombia',
              style: TextStyle(
                fontFamily: 'RegularCustom',
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: textColor),
        ],
      ),
    );
  }

  Widget _buildGlassSaldoReserva(Color textColor, bool isDark) {
    return _buildGlassContainer(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: CustomPaint(
                size: const Size(80, 160),
                painter: YellowCurvePainter(),
              ),
            ),
          ),
          Positioned(
            right: 15,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _editarSaldo,
              child: const Center(
                child: Icon(Icons.edit, color: Colors.black, size: 24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: 16,
              bottom: 16,
              right: 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: textColor, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: textColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo en base de datos',
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '\$ ${_formatNumber(_saldoFirebase)}',
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.home_outlined,
                          color: Color(0xFFFFD700),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo mostrado en Home',
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '\$ ${_formatNumber(_saldoHome)}',
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNombreUsuario(Color textColor, bool isDark) {
    return GestureDetector(
      onTap: _editarNombre,
      child: _buildGlassContainer(
        isDark: isDark,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: textColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.person_outline, color: textColor, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu nombre',
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _userName.isEmpty ? 'Sin nombre' : _userName,
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: textColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// Barra de navegación para Ajustes
class _AjusteBottomNavBar extends StatefulWidget {
  final bool isDark;

  const _AjusteBottomNavBar({required this.isDark});

  @override
  State<_AjusteBottomNavBar> createState() => _AjusteBottomNavBarState();
}

class _AjusteBottomNavBarState extends State<_AjusteBottomNavBar> {
  int selectedIndex = 4; // Ajustes está seleccionado

  final List<String> icons = [
    'assets/icons/home.svg',
    'assets/icons/pic-cards.svg',
    'assets/icons/pic-explore.svg',
    'assets/icons/pic-hand-holding-document.svg',
    'assets/icons/settings.svg',
  ];

  final List<String> labels = [
    'Inicio',
    'Transacciones',
    'Explorar',
    'Trámites y\nsolicitudes',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isDark ? Colors.white : Colors.black;
    final Color bgColor = widget.isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFFFFFFF);
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(icons.length, (index) {
            final bool isSelected = index == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (index == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  } else if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransaccionesScreen(),
                      ),
                    );
                  } else {
                    setState(() {
                      selectedIndex = index;
                    });
                  }
                },
                child: Container(
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        icons[index],
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          isSelected ? Colors.black : iconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'RegularCustom',
                          fontSize: 10,
                          color: isSelected ? Colors.black : iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class YellowCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.3, size.height);
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.5,
      size.width * 0.2,
      0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
