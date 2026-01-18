import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../system/index.dart';
import '../utils/download_helper_factory.dart';
import '../main.dart';
import 'home.dart';
import 'ajuste.dart';
import 'transacciones.dart';

class EnviobancolombiaScreen extends StatefulWidget {
  final String valorTransferencia;

  const EnviobancolombiaScreen({super.key, required this.valorTransferencia});

  @override
  State<EnviobancolombiaScreen> createState() => _EnviobancolombiaScreenState();
}

class _EnviobancolombiaScreenState extends State<EnviobancolombiaScreen> {
  final TextEditingController _cuentaController = TextEditingController();
  final FocusNode _cuentaFocusNode = FocusNode();
  bool _cuentaLabelUp = false;
  int _tipoProducto = 0; // 0 = ninguno, 1 = ahorros, 2 = corriente

  @override
  void initState() {
    super.initState();
    _cuentaFocusNode.addListener(_onCuentaFocusChange);
    _cuentaController.addListener(_onCuentaTextChange);
  }

  void _onCuentaFocusChange() {
    setState(() {
      _cuentaLabelUp =
          _cuentaFocusNode.hasFocus || _cuentaController.text.isNotEmpty;
    });
  }

  void _onCuentaTextChange() {
    setState(() {
      _cuentaLabelUp =
          _cuentaFocusNode.hasFocus || _cuentaController.text.isNotEmpty;
      // Resetear selección si se borra el número
      if (_cuentaController.text.isEmpty) {
        _tipoProducto = 0;
      }
    });
  }

  @override
  void dispose() {
    _cuentaFocusNode.removeListener(_onCuentaFocusChange);
    _cuentaController.removeListener(_onCuentaTextChange);
    _cuentaFocusNode.dispose();
    _cuentaController.dispose();
    super.dispose();
  }

  Future<Map<String, String>?> _obtenerVictima(String numeroCuenta) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('victimas_bancolombia');
    if (data != null) {
      final List<dynamic> victimas = json.decode(data);
      for (var victima in victimas) {
        if (victima['cuenta'] == numeroCuenta) {
          return {
            'nombre': victima['nombre'] as String,
            'tipo': (victima['tipo'] as String?) ?? 'Ahorros',
          };
        }
      }
    }
    return null;
  }

  void _mostrarErrorCuenta() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cuenta no válida',
                style: TextStyle(
                  fontFamily: 'OpenSansBold',
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'El número de cuenta ingresado no coincide con ninguna cuenta registrada en Bancolombia Víctimas. Por favor verifica el número o agrega la cuenta en Ajustes.',
          style: TextStyle(
            fontFamily: 'OpenSansRegular',
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                fontFamily: 'OpenSansSemibold',
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAdvertenciaTipoProducto(
    String tipoGuardado,
    String tipoSeleccionado,
    Map<String, String> victima,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[400],
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Ojo, cuidado!',
                style: TextStyle(
                  fontFamily: 'OpenSansBold',
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'La cuenta está registrada como "$tipoGuardado" pero seleccionaste "$tipoSeleccionado". ¿Estás seguro de continuar?',
          style: TextStyle(
            fontFamily: 'OpenSansRegular',
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'OpenSansSemibold',
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navegarAConfirmacion(victima);
            },
            child: const Text(
              'Continuar de todos modos',
              style: TextStyle(
                fontFamily: 'OpenSansSemibold',
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navegarAConfirmacion(Map<String, String> victima) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ConfirmacionTransferenciaBancolombiaScreen(
          valorTransferencia: widget.valorTransferencia,
          numeroCuentaDestino: _cuentaController.text,
          tipoProducto: _tipoProducto == 1 ? 'Ahorros' : 'Corriente',
          nombreDestinatario: victima['nombre']!,
        ),
      ),
    );
  }

  Future<void> _onContinuarPressed() async {
    final victima = await _obtenerVictima(_cuentaController.text);
    if (victima != null) {
      final tipoSeleccionado = _tipoProducto == 1 ? 'Ahorros' : 'Corriente';
      final tipoGuardado = victima['tipo']!;

      if (tipoSeleccionado != tipoGuardado) {
        _mostrarAdvertenciaTipoProducto(
          tipoGuardado,
          tipoSeleccionado,
          victima,
        );
      } else {
        _navegarAConfirmacion(victima);
      }
    } else {
      _mostrarErrorCuenta();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenW * 0.04,
                  vertical: screenH * 0.01,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          Transform.rotate(
                            angle: 3.14159, // 180 grados en radianes
                            child: Image.asset(
                              'assets/icons/pic-chevron-right.png',
                              width: screenW * 0.045,
                              height: screenW * 0.045,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(width: screenW * 0.02),
                          Text(
                            'Volver',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.045,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: screenW * 0.05),
                      child: SvgPicture.asset(
                        'assets/icons/CIB.svg',
                        width: screenW * 0.08,
                        height: screenW * 0.08,
                        colorFilter: isDark
                            ? const ColorFilter.mode(
                                Color(0xFFF2F2F4),
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(
                            'Continuar',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.045,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(width: screenW * 0.02),
                          Image.asset(
                            'assets/icons/pic-chevron-right.png',
                            width: screenW * 0.045,
                            height: screenW * 0.045,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenH * 0.02),
              // Título
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transferir a productos no inscritos Bancolombia',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.035,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenW * 0.001),
                    Text(
                      'Producto destino',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.065,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenH * 0.03),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                child: Container(
                  width: double.infinity,
                  height: screenH * 0.25,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF454648) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Icono al lado del texto
                      Positioned(
                        left: screenW * 0.04,
                        top: screenH * 0.05,
                        child: SvgPicture.asset(
                          'assets/icons/pic-send-money-from.svg',
                          width: screenW * 0.06,
                          height: screenW * 0.06,
                          colorFilter: ColorFilter.mode(
                            isDark ? const Color(0xFFF2F2F4) : Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      // Texto animado "Ingresa el número de producto"
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        left: _cuentaLabelUp ? screenW * 0.04 : screenW * 0.13,
                        top: _cuentaLabelUp ? screenH * 0.025 : screenH * 0.05,
                        child: GestureDetector(
                          onTap: () {
                            _cuentaFocusNode.requestFocus();
                          },
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: _cuentaLabelUp
                                  ? screenW * 0.03
                                  : screenW * 0.04,
                              color: isDark
                                  ? const Color(0xFFF2F2F4)
                                  : Colors.grey,
                            ),
                            child: const Text('Ingresa el número de producto'),
                          ),
                        ),
                      ),
                      // TextField para capturar el número
                      Positioned(
                        left: screenW * 0.13,
                        top: screenH * 0.05,
                        right: screenW * 0.05,
                        child: TextField(
                          controller: _cuentaController,
                          focusNode: _cuentaFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.045,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            counterText: '',
                          ),
                        ),
                      ),
                      // Línea horizontal divisora
                      Positioned(
                        left: screenW * 0.04,
                        right: screenW * 0.04,
                        top: screenH * 0.085,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          color: _cuentaController.text.isNotEmpty
                              ? const Color(0xFFFFD700)
                              : (isDark
                                    ? const Color(0xFF5A5A5C)
                                    : const Color(0xFFE0E0E0)),
                        ),
                      ),
                      // Texto "Selecciona el tipo de producto"
                      Positioned(
                        left: screenW * 0.04,
                        top: screenH * 0.105,
                        child: Text(
                          'Selecciona el tipo de producto',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.035,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      // Opción Ahorros
                      Positioned(
                        left: screenW * 0.04,
                        top: screenH * 0.15,
                        child: GestureDetector(
                          onTap: _cuentaController.text.isNotEmpty
                              ? () {
                                  setState(() {
                                    _tipoProducto = 1;
                                  });
                                }
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                _tipoProducto == 1
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: screenW * 0.06,
                                color: _tipoProducto == 1
                                    ? const Color(0xFFFFD700)
                                    : (_cuentaController.text.isNotEmpty
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black)
                                          : Colors.grey),
                              ),
                              SizedBox(width: screenW * 0.03),
                              Text(
                                'Ahorros',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.04,
                                  color: _cuentaController.text.isNotEmpty
                                      ? (isDark ? Colors.white : Colors.black)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Opción Corriente
                      Positioned(
                        left: screenW * 0.04,
                        top: screenH * 0.185,
                        child: GestureDetector(
                          onTap: _cuentaController.text.isNotEmpty
                              ? () {
                                  setState(() {
                                    _tipoProducto = 2;
                                  });
                                }
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                _tipoProducto == 2
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: screenW * 0.06,
                                color: _tipoProducto == 2
                                    ? const Color(0xFFFFD700)
                                    : (_cuentaController.text.isNotEmpty
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black)
                                          : Colors.grey),
                              ),
                              SizedBox(width: screenW * 0.03),
                              Text(
                                'Corriente',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.04,
                                  color: _cuentaController.text.isNotEmpty
                                      ? (isDark ? Colors.white : Colors.black)
                                      : Colors.grey,
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
              const Spacer(),
              // Contenedor con botón y paso 4
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenW * 0.05,
                  vertical: screenH * 0.02,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF454648) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Botón Continuar
                    ElevatedButton(
                      onPressed:
                          (_cuentaController.text.length == 11 &&
                              _tipoProducto != 0)
                          ? () => _onContinuarPressed()
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, screenH * 0.055),
                        backgroundColor:
                            (_cuentaController.text.length == 11 &&
                                _tipoProducto != 0)
                            ? const Color(0xFFFFD700)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color:
                                (_cuentaController.text.length == 11 &&
                                    _tipoProducto != 0)
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continuar',
                        style: TextStyle(
                          fontFamily: 'OpenSansSemibold',
                          fontSize: screenW * 0.045,
                          color:
                              (_cuentaController.text.length == 11 &&
                                  _tipoProducto != 0)
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.015),
                    // Paso 4 de 4 con línea amarilla
                    Row(
                      children: [
                        Text(
                          'Paso 4 de 4',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(width: screenW * 0.03),
                        Container(
                          width:
                              screenW *
                              0.65, // Ajusta este valor para controlar el largo de la línea
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenH * 0.0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ CONFIRMACION TRANSFERENCIA BANCOLOMBIA SCREEN ============
class ConfirmacionTransferenciaBancolombiaScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCuentaDestino;
  final String tipoProducto;
  final String numeroCuenta;
  final String nombreDestinatario;

  const ConfirmacionTransferenciaBancolombiaScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCuentaDestino,
    required this.tipoProducto,
    this.numeroCuenta = '000 - 000000 - 00',
    this.nombreDestinatario = 'Usuario',
  }) : super(key: key);

  @override
  State<ConfirmacionTransferenciaBancolombiaScreen> createState() =>
      _ConfirmacionTransferenciaBancolombiaScreenState();
}

class _ConfirmacionTransferenciaBancolombiaScreenState
    extends State<ConfirmacionTransferenciaBancolombiaScreen> {
  bool _showCircle = false;
  String _numeroCuentaPersonalizado = '';

  @override
  void initState() {
    super.initState();
    _loadNumeroCuenta();
  }

  Future<void> _loadNumeroCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty && customAccount.length == 11) {
      setState(() {
        _numeroCuentaPersonalizado =
            '${customAccount.substring(0, 3)}-${customAccount.substring(3, 9)}-${customAccount.substring(9, 11)}';
      });
    }
  }

  String get _displayNumeroCuenta => _numeroCuentaPersonalizado.isNotEmpty
      ? _numeroCuentaPersonalizado
      : widget.numeroCuenta;

  String _formatearCuentaDestino(String cuenta) {
    final limpio = cuenta.replaceAll(RegExp(r'\D'), '');
    if (limpio.length == 11) {
      return '${limpio.substring(0, 3)}-${limpio.substring(3, 9)}-${limpio.substring(9, 11)}';
    }
    return cuenta;
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Variables para el círculo centrado
    final double circleSize = screenW * 0.4;
    final double circlePosX = screenW / 2;
    final double circlePosY = screenH / 2;
    final double lottieSize = circleSize * 0.6;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenW * 0.04,
                  vertical: screenH * 0.01,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          Transform.rotate(
                            angle: 3.14159, // 180 grados en radianes
                            child: Image.asset(
                              'assets/icons/pic-chevron-right.png',
                              width: screenW * 0.045,
                              height: screenW * 0.045,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(width: screenW * 0.02),
                          Text(
                            'Volver',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.045,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: screenW * 0.05),
                      child: SvgPicture.asset(
                        'assets/icons/CIB.svg',
                        width: screenW * 0.08,
                        height: screenW * 0.08,
                        colorFilter: isDark
                            ? const ColorFilter.mode(
                                Color(0xFFF2F2F4),
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(
                            'Transferir',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.04,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(width: screenW * 0.02),
                          Image.asset(
                            'assets/icons/pic-chevron-right.png',
                            width: screenW * 0.045,
                            height: screenW * 0.045,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenH * 0.02),
              // Título
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transferir a Bancolombia',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.035,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenW * 0.01),
                    Text(
                      'Verifica la transferencia',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.06,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenH * 0.02),
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenW * 0.04),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: screenW * 0.1,
                              height: screenW * 0.1,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF9AD1C9).withOpacity(0.3),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                size: screenW * 0.06,
                                color: const Color(0xFF9AD1C9),
                              ),
                            ),
                            SizedBox(width: screenW * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tus transferencias a Nequi y cuentas Bancolombia no tienen costo.',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.035,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: screenH * 0.01),
                                  Text(
                                    'A otros bancos te cuesta \$7.300 + IVA cada una. Si tienes Plan Oro o Plan Pensión 035, tienes transferencias sin costo.',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.03,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: screenH * 0.01),
                                  Text(
                                    'Descubre tu plan',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.035,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenH * 0.03),
                      // ¿Cuánto vas a pagar?
                      Text(
                        '¿Cuánto vas a pagar?',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.045,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenH * 0.015),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenW * 0.04),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Valor a transferir',
                                  style: TextStyle(
                                    fontFamily: 'OpenSansRegular',
                                    fontSize: screenW * 0.03,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: screenH * 0.005),
                                Text(
                                  '\$ ${widget.valorTransferencia}',
                                  style: TextStyle(
                                    fontFamily: 'OpenSansBold',
                                    fontSize: screenW * 0.05,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Cambiar',
                                  style: TextStyle(
                                    fontFamily: 'OpenSansRegular',
                                    fontSize: screenW * 0.035,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: screenW * 0.05,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenH * 0.03),
                      // ¿A quien le llega?
                      Text(
                        '¿A quien le llega?',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.045,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenH * 0.015),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenW * 0.04),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cuenta ${widget.tipoProducto} Bancolombia',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Text(
                              _formatearCuentaDestino(
                                widget.numeroCuentaDestino,
                              ),
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize: screenW * 0.045,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenH * 0.03),
                      // ¿De dónde sale la plata?
                      Text(
                        '¿De dónde sale la plata?',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.045,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenH * 0.015),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenW * 0.04),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cuenta de ahorros',
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize: screenW * 0.04,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Text(
                              'Ahorros',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _displayNumeroCuenta,
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenH * 0.02),
                    ],
                  ),
                ),
              ),
              // Botones
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: screenH * 0.06,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _showCircle = true);
                          Future.delayed(const Duration(seconds: 9), () {
                            if (mounted) {
                              setState(() => _showCircle = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => ComprobanteBancolombiaScreen(
                                    valorTransferencia:
                                        widget.valorTransferencia,
                                    numeroCuentaDestino:
                                        widget.numeroCuentaDestino,
                                    tipoProducto: widget.tipoProducto,
                                    numeroCuenta: widget.numeroCuenta,
                                    nombreDestinatario:
                                        widget.nombreDestinatario,
                                  ),
                                ),
                              );
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Transferir plata',
                          style: TextStyle(
                            fontFamily: 'OpenSansSemibold',
                            fontSize: screenW * 0.045,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.015),
                    SizedBox(
                      width: double.infinity,
                      height: screenH * 0.06,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'OpenSansSemibold',
                            fontSize: screenW * 0.045,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenH * 0.02),
            ],
          ),
          // Fondo borroso cuando se muestra el círculo
          if (_showCircle)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
          // Círculo centrado con lottie
          if (_showCircle)
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: lottieSize * 0.5,
                        height: lottieSize * 0.5,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : const Color(0xFFFFDD00),
                          ),
                        ),
                      ),
                      SizedBox(height: lottieSize * 0.1),
                      Text(
                        'Validando\nclave dinámica',
                        style: TextStyle(
                          fontSize: lottieSize * 0.12,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'OpenSansRegular',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============ COMPROBANTE BANCOLOMBIA SCREEN ============
class ComprobanteBancolombiaScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCuentaDestino;
  final String tipoProducto;
  final String numeroCuenta;
  final String nombreDestinatario;

  const ComprobanteBancolombiaScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCuentaDestino,
    required this.tipoProducto,
    this.numeroCuenta = '*0000',
    this.nombreDestinatario = 'Usuario',
  }) : super(key: key);

  @override
  State<ComprobanteBancolombiaScreen> createState() =>
      _ComprobanteBancolombiaScreenState();
}

class _ComprobanteBancolombiaScreenState
    extends State<ComprobanteBancolombiaScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _comprobanteKey = GlobalKey();
  bool _showCompactHeader = false;
  String _numeroCuentaPersonalizado = '';

  // Función para ocultar parcialmente el nombre (ej: "Camilo Osorio Posada" -> "Cam*** Oso*** Pos***")
  // Muestra las primeras 3 letras de cada palabra y el resto con asteriscos
  String _ocultarNombre(String nombre) {
    if (nombre.isEmpty) return '';
    final palabras = nombre.split(' ').where((p) => p.isNotEmpty).toList();
    final resultado = <String>[];
    for (var palabra in palabras) {
      if (palabra.length <= 3) {
        // Si la palabra tiene 3 o menos letras, mostrar toda
        resultado.add(palabra);
      } else {
        // Mostrar las primeras 3 letras y el resto con asteriscos
        final visibles = palabra.substring(0, 3);
        final ocultos = palabra.length - 3;
        resultado.add('$visibles${'*' * ocultos}');
      }
    }
    return resultado.join(' ');
  }

  String get _numeroComprobante {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return '000000${random.toString().padLeft(4, '0')}';
  }

  String get _displayNumeroCuenta => _numeroCuentaPersonalizado.isNotEmpty
      ? _numeroCuentaPersonalizado
      : widget.numeroCuenta;

  String get _fechaHora {
    final now = DateTime.now();
    final meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final hora = now.hour > 12 ? now.hour - 12 : now.hour;
    final periodo = now.hour >= 12 ? 'p.m.' : 'a.m.';
    final minutos = now.minute.toString().padLeft(2, '0');
    return '${now.day} ${meses[now.month - 1]}. ${now.year} - $hora:$minutos $periodo';
  }

  String _formatearCuentaDestino(String cuenta) {
    final limpio = cuenta.replaceAll(RegExp(r'\D'), '');
    if (limpio.length == 11) {
      return '${limpio.substring(0, 3)}-${limpio.substring(3, 9)}-${limpio.substring(9, 11)}';
    }
    return cuenta;
  }

  String get _ultimos4Digitos {
    final limpio = _displayNumeroCuenta.replaceAll(RegExp(r'\D'), '');
    if (limpio.length >= 4) {
      return '*${limpio.substring(limpio.length - 4)}';
    }
    return '*0000';
  }

  String _formatearValor(String valor) {
    final limpio = valor.replaceAll(RegExp(r'\D'), '');
    if (limpio.isEmpty) return valor;
    final resultado = StringBuffer();
    for (int i = 0; i < limpio.length; i++) {
      if (i > 0 && (limpio.length - i) % 3 == 0) {
        resultado.write('.');
      }
      resultado.write(limpio[i]);
    }
    return resultado.toString();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNumeroCuentaPersonalizado();
    _descontarSaldo();
  }

  Future<void> _descontarSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    final saldoActual = prefs.getDouble('saldo_reserva') ?? 0;
    final valorLimpio = widget.valorTransferencia.replaceAll(RegExp(r'\D'), '');
    final valorTransferido = double.tryParse(valorLimpio) ?? 0;
    final nuevoSaldo = saldoActual - valorTransferido;
    await prefs.setDouble('saldo_reserva', nuevoSaldo > 0 ? nuevoSaldo : 0);

    // Guardar el movimiento
    await _guardarMovimiento(valorTransferido);
  }

  Future<void> _guardarMovimiento(double valor) async {
    final prefs = await SharedPreferences.getInstance();
    final movimientosJson = prefs.getString('movimientos_bancolombia') ?? '[]';
    final List<dynamic> movimientos = json.decode(movimientosJson);

    final nuevoMovimiento = {
      'fecha': DateTime.now().toIso8601String(),
      'descripcion': 'TRANSFERENCIA A BANCOLOMBIA',
      'valor': valor,
      'tipo': 'debito', // salida de dinero
    };

    movimientos.insert(0, nuevoMovimiento); // Agregar al inicio
    await prefs.setString('movimientos_bancolombia', json.encode(movimientos));
  }

  Future<void> _loadNumeroCuentaPersonalizado() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty && customAccount.length == 11) {
      setState(() {
        _numeroCuentaPersonalizado =
            '${customAccount.substring(0, 3)}-${customAccount.substring(3, 9)}-${customAccount.substring(9, 11)}';
      });
    }
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 180;
    if (shouldShow != _showCompactHeader) {
      setState(() => _showCompactHeader = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedUsername = prefs.getString('logged_username') ?? '';
      final saldoHome = prefs.getDouble('saldo_reserva') ?? 0;

      if (loggedUsername.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(loggedUsername)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final saldoFirebase = (data?['saldo'] is num)
              ? (data!['saldo'] as num).toDouble()
              : 0.0;
          final nuevoSaldo = saldoFirebase + saldoHome;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(loggedUsername)
              .update({
                'saldo': nuevoSaldo,
                'device_id': '',
                'session_token': '',
                'session_timestamp': 0,
              });
        }
      }

      await prefs.setDouble('saldo_reserva', 0);
      await prefs.remove('logged_username');
      await prefs.remove('session_token');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LogoPantalla()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LogoPantalla()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _compartirComprobante() async {
    try {
      final double screenW = MediaQuery.of(context).size.width;
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      final comprobanteWidget = _buildComprobanteCompleto(screenW, isDark);
      final RenderRepaintBoundary boundary = await _createImageFromWidget(
        comprobanteWidget,
        screenW,
      );
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        await downloadHelper.downloadImage(
          pngBytes,
          'comprobante_bancolombia.png',
        );
      } else {
        await downloadHelper.downloadImage(
          pngBytes,
          'comprobante_bancolombia.png',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al compartir el comprobante')),
        );
      }
    }
  }

  Future<RenderRepaintBoundary> _createImageFromWidget(
    Widget widget,
    double width,
  ) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    final RenderView renderView = RenderView(
      view: View.of(context),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints(
          maxWidth: width,
          maxHeight: double.infinity,
        ),
        devicePixelRatio: 3.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
          container: repaintBoundary,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(data: MediaQuery.of(context), child: widget),
          ),
        ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    return repaintBoundary;
  }

  Widget _buildComprobanteCompleto(double screenW, bool isDark) {
    final double circleSize = screenW * 0.15;
    return Container(
      width: screenW,
      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F4),
      child: Stack(
        children: [
          Positioned(
            top: screenW * 0.3,
            left: 0,
            right: 0,
            child: Center(
              child: SvgPicture.asset(
                'assets/trazos/trazo-comprobante.svg',
                width: screenW,
                height: screenW,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenW * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: screenW * 0.3),
                    SvgPicture.asset(
                      'assets/icons/CIB.svg',
                      width: screenW * 0.08,
                      height: screenW * 0.08,
                      colorFilter: isDark
                          ? const ColorFilter.mode(
                              Color(0xFFF2F2F4),
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/logout.svg',
                          width: screenW * 0.08,
                          height: screenW * 0.08,
                          colorFilter: ColorFilter.mode(
                            isDark ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenW * 0.04),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF64DAB7),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/check.svg',
                    width: circleSize * 0.5,
                    height: circleSize * 0.5,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenW * 0.04),
              Text(
                '¡Transferencia exitosa!',
                style: TextStyle(
                  fontFamily: 'OpenSansBold',
                  fontSize: screenW * 0.055,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenW * 0.02),
              Text(
                'Comprobante No. $_numeroComprobante',
                style: TextStyle(
                  fontFamily: 'OpenSansRegular',
                  fontSize: screenW * 0.04,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenW * 0.01),
              Text(
                _fechaHora,
                style: TextStyle(
                  fontFamily: 'OpenSansRegular',
                  fontSize: screenW * 0.04,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenW * 0.06),
              // Card Datos de la transferencia
              _buildCardDatosForCapture(screenW, isDark),
              SizedBox(height: screenW * 0.04),
              // Card Producto destino
              _buildCardDestinoForCapture(screenW, isDark),
              SizedBox(height: screenW * 0.04),
              // Card Producto origen
              _buildCardOrigenForCapture(screenW, isDark),
              SizedBox(height: screenW * 0.04),
              // Barra de navegación
              _buildNavBarForCapture(screenW, isDark),
              SizedBox(height: screenW * 0.02),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardDatosForCapture(double screenW, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenW * 0.03,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Datos de la transferencia',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: -3.14159 / 2,
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: screenW * 0.05,
                      height: screenW * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor de la transferencia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.01),
                  Text(
                    '\$ ${_formatearValor(widget.valorTransferencia)}',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.05,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenW * 0.04),
                  Text(
                    'Costo de la transferencia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.01),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$ 0',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.05,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ',00',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForCapture(
    double screenW,
    bool isDark,
    String title,
    String subtitle,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenW * 0.03,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'OpenSansBold',
                  fontSize: screenW * 0.04,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.01),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.05,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDestinoForCapture(double screenW, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenW * 0.03,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Producto destino',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: -3.14159 / 2,
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: screenW * 0.05,
                      height: screenW * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ocultarNombre(widget.nombreDestinatario),
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenW * 0.005),
                  Text(
                    '${widget.tipoProducto} - Bancolombia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.005),
                  Text(
                    _formatearCuentaDestino(widget.numeroCuentaDestino),
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOrigenForCapture(double screenW, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenW * 0.03,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Producto origen',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: -3.14159 / 2,
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: screenW * 0.05,
                      height: screenW * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuenta de ahorros',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenW * 0.005),
                  Text(
                    'Ahorros',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.005),
                  Text(
                    _ultimos4Digitos,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarForCapture(double screenW, bool isDark) {
    final List<Map<String, String>> items = [
      {'icon': 'assets/icons/home.svg', 'label': 'Inicio'},
      {'icon': 'assets/icons/pic-cards.svg', 'label': 'Transacciones'},
      {'icon': 'assets/icons/pic-explore.svg', 'label': 'Explorar'},
      {
        'icon': 'assets/icons/pic-hand-holding-document.svg',
        'label': 'Trámites',
      },
      {'icon': 'assets/icons/settings.svg', 'label': 'Ajustes'},
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                item['icon']!,
                width: screenW * 0.06,
                height: screenW * 0.06,
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: screenW * 0.01),
              Text(
                item['label']!,
                style: TextStyle(
                  fontFamily: 'OpenSansRegular',
                  fontSize: screenW * 0.025,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double iconSize = screenW * 1.0;
    final double iconTopPosition = screenH * 0.2;
    final double circleSize = screenW * 0.15;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      body: RepaintBoundary(
        key: _comprobanteKey,
        child: Stack(
          children: [
            Container(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F4),
            ),
            Positioned(
              top: iconTopPosition,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/trazos/trazo-comprobante.svg',
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SizedBox(height: screenH * 0.01),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenW * 0.04,
                        right: screenW * 0.01,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: screenW * 0.35),
                          SvgPicture.asset(
                            'assets/icons/CIB.svg',
                            width: screenW * 0.08,
                            height: screenW * 0.08,
                            colorFilter: isDark
                                ? const ColorFilter.mode(
                                    Color(0xFFF2F2F4),
                                    BlendMode.srcIn,
                                  )
                                : null,
                          ),
                          GestureDetector(
                            onTap: _cerrarSesion,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Cerrar sesión',
                                  style: TextStyle(
                                    fontFamily: 'OpenSansRegular',
                                    fontSize: screenW * 0.04,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                SvgPicture.asset(
                                  'assets/icons/logout.svg',
                                  width: screenW * 0.1,
                                  height: screenW * 0.1,
                                  colorFilter: ColorFilter.mode(
                                    isDark ? Colors.white : Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenH * 0.035),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF64DAB7),
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/check.svg',
                          width: circleSize * 0.5,
                          height: circleSize * 0.5,
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenH * 0.02),
                    Text(
                      '¡Transferencia exitosa!',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.055,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenH * 0.01),
                    Text(
                      'Comprobante No. $_numeroComprobante',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.04,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenH * 0.005),
                    Text(
                      _fechaHora,
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.04,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenH * 0.03),
                    // Card info transferencias
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenW * 0.04),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: screenW * 0.1,
                              height: screenW * 0.1,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF64DAB7).withOpacity(0.3),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                size: screenW * 0.06,
                                color: const Color(0xFF64DAB7),
                              ),
                            ),
                            SizedBox(width: screenW * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tus transferencias a Nequi y cuentas Bancolombia no tienen costo.',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.035,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: screenH * 0.01),
                                  Text(
                                    'A otros bancos te cuesta \$7.190 + IVA cada una. Si tienes Plan Oro o Plan Pensión 035, tienes transferencias sin costo.',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.03,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: screenH * 0.01),
                                  Text(
                                    'Descubre tu plan',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.035,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.02),
                    _buildCardDatosTransferencia(
                      context,
                      screenW,
                      screenH,
                      isDark,
                    ),
                    SizedBox(height: screenH * 0.02),
                    _buildCardProductoDestino(
                      context,
                      screenW,
                      screenH,
                      isDark,
                    ),
                    SizedBox(height: screenH * 0.02),
                    _buildCardProductoOrigen(context, screenW, screenH, isDark),
                    SizedBox(height: screenH * 0.03),
                    // Botones de acción
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenW * 0.04),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              context: context,
                              screenW: screenW,
                              isDark: isDark,
                              icon: 'assets/icons/pic-share.svg',
                              label: 'Compartir',
                              onTap: _compartirComprobante,
                            ),
                            _buildActionButton(
                              context: context,
                              screenW: screenW,
                              isDark: isDark,
                              icon: 'assets/icons/pic-qr-scan.svg',
                              label: 'Escanear\ncódigo QR',
                              onTap: () {},
                            ),
                            _buildActionButton(
                              context: context,
                              screenW: screenW,
                              isDark: isDark,
                              icon: 'assets/icons/pic-send-money.svg',
                              label: 'Hacer otra\ntransferencia',
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.15),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavBar(context, screenW, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
    String title,
    String subtitle,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenH * 0.015,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: -3.14159 / 2,
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: screenW * 0.05,
                      height: screenW * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenH * 0.005),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'RegularCusto',
                      fontSize: screenW * 0.05,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDatosTransferencia(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenH * 0.015,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Datos de la transferencia',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: -3.14159 / 2,
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: screenW * 0.05,
                      height: screenW * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor de la transferencia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenH * 0.005),
                  Text(
                    '\$ ${_formatearValor(widget.valorTransferencia)}',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.05,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.02),
                  Text(
                    'Costo de la transferencia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenH * 0.005),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$ 0',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.05,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ',00',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardProductoDestino(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenH * 0.015,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Producto destino',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: -3.14159 / 2,
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: screenW * 0.05,
                      height: screenW * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ocultarNombre(widget.nombreDestinatario),
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.005),
                  Text(
                    '${widget.tipoProducto} - Bancolombia ',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenH * 0.005),
                  Text(
                    _formatearCuentaDestino(widget.numeroCuentaDestino),
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardProductoOrigen(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenH * 0.015,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF3C3C3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Producto origen',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  Transform.rotate(
                    angle: -3.14159 / 2,
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: screenW * 0.05,
                      height: screenW * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuenta de ahorros',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.04,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.003),
                  Text(
                    'Ahorros',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenH * 0.003),
                  Text(
                    _ultimos4Digitos,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.015),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nuevo saldo disponible',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.035,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Container(
                        width: screenW * 0.08,
                        height: screenW * 0.08,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[600]!
                                : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.visibility_outlined,
                          size: screenW * 0.045,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenH * 0.005),
                  Text(
                    '*****',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.05,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required double screenW,
    required bool isDark,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: screenW * 0.08,
            height: screenW * 0.08,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white : Colors.black,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: screenW * 0.02),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSansRegular',
              fontSize: screenW * 0.03,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, double screenW, bool isDark) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: 'assets/icons/home.svg',
            label: 'Inicio',
            isDark: isDark,
            screenW: screenW,
            isSelected: false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          _buildNavItem(
            icon: 'assets/icons/pic-cards.svg',
            label: 'Transacciones',
            isDark: isDark,
            screenW: screenW,
            isSelected: false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const TransaccionesScreen()),
                (route) => false,
              );
            },
          ),
          _buildNavItem(
            icon: 'assets/icons/pic-explore.svg',
            label: 'Explorar',
            isDark: isDark,
            screenW: screenW,
            isSelected: false,
            onTap: () {},
          ),
          _buildNavItem(
            icon: 'assets/icons/pic-hand-holding-document.svg',
            label: 'Trámites y\nsolicitudes',
            isDark: isDark,
            screenW: screenW,
            isSelected: false,
            onTap: () {},
          ),
          _buildNavItem(
            icon: 'assets/icons/settings.svg',
            label: 'Ajustes',
            isDark: isDark,
            screenW: screenW,
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AjusteScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required bool isDark,
    required double screenW,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color iconColor = isSelected
        ? const Color(0xFFFFD700)
        : (isDark ? Colors.white : Colors.black);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            width: screenW * 0.06,
            height: screenW * 0.06,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSansRegular',
              fontSize: screenW * 0.025,
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
