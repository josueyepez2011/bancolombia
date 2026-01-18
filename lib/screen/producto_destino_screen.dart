import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'ajuste.dart';
import 'enviobancolombia_screen.dart';
import '../utils/download_helper_factory.dart';
import '../system/index.dart';
import '../main.dart';
import 'transacciones.dart';

class ProductoDestinoScreen extends StatelessWidget {
  final String valorTransferencia;
  final String numeroCuenta;
  final String saldoDisponible;

  const ProductoDestinoScreen({
    Key? key,
    required this.valorTransferencia,
    this.numeroCuenta = '000 - 000000 - 00',
    this.saldoDisponible = '9.980.000,00',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenW * 0.04,
              vertical: screenH * 0.01,
            ),
            child: Row(
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
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(right: screenW * 0.05),
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
                const Spacer(),
                SizedBox(width: screenW * 0.15),
              ],
            ),
          ),
          SizedBox(height: screenH * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transferir plata',
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: screenW * 0.035,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: screenW * 0.01),
                Text(
                  'Producto destino',
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
                    fontSize: screenW * 0.065,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenH * 0.03),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOption(
                    context,
                    screenW,
                    screenH,
                    isDark,
                    'Tus productos Bancolombia',
                    () {},
                  ),
                  SizedBox(height: screenH * 0.025),
                  Text(
                    'Productos inscritos',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.015),
                  _buildOption(
                    context,
                    screenW,
                    screenH,
                    isDark,
                    'De Bancolombia',
                    () {},
                  ),
                  SizedBox(height: screenH * 0.015),
                  _buildOption(
                    context,
                    screenW,
                    screenH,
                    isDark,
                    'De otros bancos',
                    () {},
                  ),
                  SizedBox(height: screenH * 0.015),
                  _buildOption(
                    context,
                    screenW,
                    screenH,
                    isDark,
                    'Inscribir productos',
                    () {},
                  ),
                  SizedBox(height: screenH * 0.025),
                  Text(
                    'Productos no inscritos',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.015),
                  _buildOption(
                    context,
                    screenW,
                    screenH,
                    isDark,
                    'De Bancolombia',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => EnviobancolombiaScreen(
                            valorTransferencia: valorTransferencia,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenH * 0.015),
                  _buildOption(
                    context,
                    screenW,
                    screenH,
                    isDark,
                    'De Nequi',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => EnvioNequiScreen(
                            valorTransferencia: valorTransferencia,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenW * 0.05,
              vertical: screenH * 0.02,
            ),
            child: Row(
              children: [
                Text(
                  'Paso 3 de 4',
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: screenW * 0.035,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(width: screenW * 0.03),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE85D04),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
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
    );
  }

  Widget _buildOption(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenW * 0.04,
          vertical: screenH * 0.02,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'OpenSansRegular',
                  fontSize: screenW * 0.04,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: screenW * 0.06,
              color: isDark ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ENVIO NEQUI SCREEN ============
class EnvioNequiScreen extends StatefulWidget {
  final String valorTransferencia;
  const EnvioNequiScreen({Key? key, required this.valorTransferencia})
    : super(key: key);
  @override
  State<EnvioNequiScreen> createState() => _EnvioNequiScreenState();
}

class _EnvioNequiScreenState extends State<EnvioNequiScreen> {
  final TextEditingController _celularController = TextEditingController();

  void _navegarAConfirmacion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ConfirmacionTransferenciaScreen(
          valorTransferencia: widget.valorTransferencia,
          numeroCelular: _celularController.text,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _celularController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEnabled = _celularController.text.length == 10;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  onTap: isEnabled ? () {} : null,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transferir a productos no inscritos Nequi',
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: screenW * 0.035,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: screenW * 0.01),
                Text(
                  'Producto destino',
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
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
              padding: EdgeInsets.all(screenW * 0.04),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF454648) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresa el número de celular',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.01),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/pic-phone.svg',
                        width: screenW * 0.05,
                        height: screenW * 0.05,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white : Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: screenW * 0.02),
                      Expanded(
                        child: TextField(
                          controller: _celularController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: TextStyle(
                            fontFamily: 'RegularCustom',
                            fontSize: screenW * 0.05,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: '',
                            counterText: '',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  Container(height: 2, color: const Color(0xFFFFD700)),
                  SizedBox(height: screenH * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingresa un número sin caracteres especiales',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.03,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${_celularController.text.length}/10',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.03,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
            child: SizedBox(
              width: double.infinity,
              height: screenH * 0.06,
              child: ElevatedButton(
                onPressed: isEnabled ? _navegarAConfirmacion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? const Color(0xFFFFD700)
                      : (isDark
                            ? const Color(0xFF5A5A5C)
                            : const Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continuar',
                  style: TextStyle(
                    fontFamily: 'OpenSansSemibold',
                    fontSize: screenW * 0.045,
                    color: isEnabled ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: screenH * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenW * 0.05,
              vertical: screenH * 0.02,
            ),
            child: Row(
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
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
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
    );
  }
}

// ============ CONFIRMACION TRANSFERENCIA SCREEN ============
class ConfirmacionTransferenciaScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCelular;
  final String numeroCuenta;

  const ConfirmacionTransferenciaScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCelular,
    this.numeroCuenta = '000 - 000000 - 00',
  }) : super(key: key);

  @override
  State<ConfirmacionTransferenciaScreen> createState() =>
      _ConfirmacionTransferenciaScreenState();
}

class _ConfirmacionTransferenciaScreenState
    extends State<ConfirmacionTransferenciaScreen> {
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
                      'Transferir a Nequi',
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
                              'Nequi',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Text(
                              widget.numeroCelular,
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
                                  builder: (c) => ComprobanteScreen(
                                    valorTransferencia:
                                        widget.valorTransferencia,
                                    numeroCelular: widget.numeroCelular,
                                    numeroCuenta: widget.numeroCuenta,
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

// ============ COMPROBANTE SCREEN ============
class ComprobanteScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCelular;
  final String numeroCuenta;

  const ComprobanteScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCelular,
    this.numeroCuenta = '*0000',
  }) : super(key: key);

  @override
  State<ComprobanteScreen> createState() => _ComprobanteScreenState();
}

class _ComprobanteScreenState extends State<ComprobanteScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _comprobanteKey = GlobalKey();
  bool _showCompactHeader = false;
  String _numeroCuentaPersonalizado = '';

  // Generar número de comprobante aleatorio de 6 dígitos
  String get _numeroComprobante {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  String get _displayNumeroCuenta => _numeroCuentaPersonalizado.isNotEmpty
      ? _numeroCuentaPersonalizado
      : widget.numeroCuenta;

  // Obtener fecha y hora actual formateada
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

  // Formatear número de celular: xxx xxx xxxx
  String _formatearCelular(String numero) {
    final limpio = numero.replaceAll(RegExp(r'\D'), '');
    if (limpio.length >= 10) {
      return '${limpio.substring(0, 3)} ${limpio.substring(3, 6)} ${limpio.substring(6, 10)}';
    }
    return numero;
  }

  // Obtener últimos 4 dígitos de la cuenta
  String get _ultimos4Digitos {
    final limpio = _displayNumeroCuenta.replaceAll(RegExp(r'\D'), '');
    if (limpio.length >= 4) {
      return '*${limpio.substring(limpio.length - 4)}';
    }
    return '*0000';
  }

  // Formatear valor con puntos cada 3 dígitos
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
    // Limpiar el valor de transferencia (quitar puntos y caracteres no numéricos)
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
      'descripcion': 'ENVIO A NEQUI',
      'valor': valor,
      'tipo': 'debito',
    };

    movimientos.insert(0, nuevoMovimiento);
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

      debugPrint('Cerrando sesión para usuario: $loggedUsername');

      if (loggedUsername.isNotEmpty) {
        // Obtener el saldo actual de Firebase
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(loggedUsername)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final saldoFirebase = (data?['saldo'] is num)
              ? (data!['saldo'] as num).toDouble()
              : 0.0;

          // Sumar el saldo del home al saldo de Firebase
          final nuevoSaldo = saldoFirebase + saldoHome;

          debugPrint('Actualizando Firebase - saldo: $nuevoSaldo');

          // Actualizar Firebase: saldo, limpiar device_id y session_token
          await FirebaseFirestore.instance
              .collection('users')
              .doc(loggedUsername)
              .update({
                'saldo': nuevoSaldo,
                'device_id': '',
                'session_token': '',
                'session_timestamp': 0,
              });

          debugPrint('Firebase actualizado correctamente');
        }
      }

      // Limpiar SharedPreferences
      await prefs.setDouble('saldo_reserva', 0);
      await prefs.remove('logged_username');
      await prefs.remove('session_token');

      debugPrint('SharedPreferences limpiado');

      // Navegar al splash (LogoPantalla)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LogoPantalla()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      // Aún así navegar al splash
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

      // Crear el widget del comprobante completo
      final comprobanteWidget = _buildComprobanteCompleto(screenW, isDark);

      // Renderizar offscreen
      final RenderRepaintBoundary boundary = await _createImageFromWidget(
        comprobanteWidget,
        screenW,
      );

      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // Para web: descargar la imagen
        await downloadHelper.downloadImage(
          pngBytes,
          'comprobante_bancolombia.png',
        );
      } else {
        // Para móvil: compartir la imagen
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
          // Trazo de fondo
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
          // Contenido
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenW * 0.02),
              // Header con CIB y Cerrar sesión
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: screenW * 0.3),
                    // Logo CIB centrado
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
                    // Cerrar sesión a la derecha
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
              // Círculo con check
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
              // Transferencia exitosa
              Text(
                '¡Transferencia exitosa!',
                style: TextStyle(
                  fontFamily: 'OpenSansBold',
                  fontSize: screenW * 0.055,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenW * 0.02),
              // Comprobante No.
              Text(
                'Comprobante No. $_numeroComprobante',
                style: TextStyle(
                  fontFamily: 'OpenSansRegular',
                  fontSize: screenW * 0.04,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenW * 0.01),
              // Fecha/hora
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
              _buildCardForCapture(
                screenW,
                isDark,
                'Datos de la transferencia',
                'Valor de la transferencia',
                '\$ ${_formatearValor(widget.valorTransferencia)}',
              ),
              SizedBox(height: screenW * 0.04),
              // Card Producto destino
              _buildCardForCapture(
                screenW,
                isDark,
                'Producto destino',
                'Nequi',
                _formatearCelular(widget.numeroCelular),
              ),
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
              child: Text(
                'Producto origen',
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
              const SizedBox(height: 4),
              Text(
                item['label']!,
                textAlign: TextAlign.center,
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

    // Valores responsivos para el icono trazo-comprobante
    final double iconSize = screenW * 1.0;
    final double iconTopPosition = screenH * 0.2;

    // Valores responsivos para el círculo
    final double circleSize = screenW * 0.15;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      body: RepaintBoundary(
        key: _comprobanteKey,
        child: Stack(
          children: [
            // Fondo
            Container(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F4),
            ),
            // Icono trazo-comprobante FIJO (no se mueve con scroll)
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
            // Contenido scrolleable
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SizedBox(height: screenH * 0.01),
                    // Header con CIB centrado y Cerrar sesión a la derecha
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenW * 0.04,
                        right: screenW * 0.01,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: screenW * 0.35,
                          ), // Espacio para balancear
                          // Icono CIB.svg centrado
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
                          // Cerrar sesión a la derecha
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
                    // Círculo con check
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
                    // Texto "¡Transferencia exitosa!"
                    Text(
                      '¡Transferencia exitosa!',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.055,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenH * 0.01),
                    // Comprobante No.
                    Text(
                      'Comprobante No. $_numeroComprobante',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.04,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenH * 0.005),
                    // Fecha/hora
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
                    // Card "Datos de la transferencia"
                    _buildCard(
                      context,
                      screenW,
                      screenH,
                      isDark,
                      'Datos de la transferencia',
                      'Valor de la transferencia',
                      '\$ ${_formatearValor(widget.valorTransferencia)}',
                    ),
                    SizedBox(height: screenH * 0.02),
                    // Card "Producto destino"
                    _buildCard(
                      context,
                      screenW,
                      screenH,
                      isDark,
                      'Producto destino',
                      'Nequi',
                      _formatearCelular(widget.numeroCelular),
                    ),
                    SizedBox(height: screenH * 0.02),
                    // Card "Producto origen" personalizado
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
                    // Espacio para el navbar
                    SizedBox(height: screenH * 0.15),
                  ],
                ),
              ),
            ),
            // Barra de navegación inferior FIJA
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
            // Header oscuro
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
            // Contenido
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
                  // Nuevo saldo disponible
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
