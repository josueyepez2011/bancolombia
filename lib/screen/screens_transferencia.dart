import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'producto_destino_screen.dart';
import '../system/index.dart';

// ============ PRODUCTO ORIGEN SCREEN ============
class ProductoOrigenScreen extends StatefulWidget {
  const ProductoOrigenScreen({Key? key}) : super(key: key);
  @override
  State<ProductoOrigenScreen> createState() => _ProductoOrigenScreenState();
}

class _ProductoOrigenScreenState extends State<ProductoOrigenScreen> {
  int _selectedTab = 0;
  String _numeroCuenta = '000 - 000000 - 00';
  double _saldoDisponible = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty && customAccount.length == 11) {
      setState(() {
        _numeroCuenta =
            '${customAccount.substring(0, 3)}-${customAccount.substring(3, 9)}-${customAccount.substring(9, 11)}';
      });
    }
    setState(() {
      _saldoDisponible = prefs.getDouble('saldo_reserva') ?? 0;
    });
  }

  String _formatNumber(double number) {
    String numStr = number.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = '.$result';
      }
      result = numStr[i] + result;
      count++;
    }
    return result;
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                      Icon(
                        Icons.close,
                        size: screenW * 0.06,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      SizedBox(width: screenW * 0.02),
                      Text(
                        'Cancelar',
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
                  padding: EdgeInsets.only(left: screenW * 0.15),
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
                SizedBox(width: screenW * 0.2),
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
                  'Producto origen',
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
                    fontSize: screenW * 0.065,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenH * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
            child: Text(
              'Si no vez alguno de tus productos, puede estar oculto.',
              style: TextStyle(
                fontFamily: 'OpenSansRegular',
                fontSize: screenW * 0.035,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: screenH * 0.03),
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
            child: Row(
              children: [
                _buildTab('Depósitos', 0, screenW, isDark),
                SizedBox(width: screenW * 0.06),
                _buildTab('Tarjetas de Crédito', 1, screenW, isDark),
                SizedBox(width: screenW * 0.06),
                _buildTab('Inversiones', 2, screenW, isDark),
              ],
            ),
          ),
          SizedBox(height: screenH * 0.02),
          Expanded(
            child: _selectedTab == 0
                ? _buildDepositos(context, screenW, screenH, isDark)
                : Center(
                    child: Text(
                      'Sin productos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenW * 0.05,
              vertical: screenH * 0.02,
            ),
            child: Row(
              children: [
                Text(
                  'Paso 1 de 4',
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
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
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

  Widget _buildTab(String label, int index, double screenW, bool isDark) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: isSelected ? 'OpenSansBold' : 'OpenSansRegular',
              fontSize: screenW * 0.035,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: label.length * screenW * 0.02,
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildDepositos(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ValorTransferenciaScreen(
              numeroCuenta: _numeroCuenta,
              saldoDisponible: '${_formatNumber(_saldoDisponible)},00',
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenW * 0.04),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF454648) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
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
                      _numeroCuenta,
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.03,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenH * 0.01),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: screenW * 0.04,
                          color: Colors.grey,
                        ),
                        SizedBox(width: screenW * 0.02),
                        Text(
                          'Saldo disponible',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.03,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenH * 0.005),
                    Text(
                      '\$ ${_formatNumber(_saldoDisponible)},00',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.055,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: screenW * 0.1,
                height: screenW * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: screenW * 0.06,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ VALOR TRANSFERENCIA SCREEN ============
class ValorTransferenciaScreen extends StatefulWidget {
  final String numeroCuenta;
  final String saldoDisponible;
  const ValorTransferenciaScreen({
    Key? key,
    this.numeroCuenta = '000 - 000000 - 00',
    this.saldoDisponible = '9.980.000,00',
  }) : super(key: key);
  @override
  State<ValorTransferenciaScreen> createState() =>
      _ValorTransferenciaScreenState();
}

class _ValorTransferenciaScreenState extends State<ValorTransferenciaScreen> {
  final TextEditingController _valorController = TextEditingController();

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  double _parseSaldo() {
    // Convertir el saldo de formato "9.980.000,00" a número
    String saldo = widget.saldoDisponible
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(saldo) ?? 0;
  }

  double _parseValorIngresado() {
    // Convertir el valor ingresado a número
    String valor = _valorController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(valor) ?? 0;
  }

  void _mostrarErrorSaldoInsuficiente() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
        title: Text(
          'Saldo insuficiente',
          style: TextStyle(
            fontFamily: 'OpenSansBold',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'El valor a transferir no puede ser mayor al saldo disponible (\$ ${widget.saldoDisponible})',
          style: TextStyle(
            fontFamily: 'OpenSansRegular',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                fontFamily: 'OpenSansBold',
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navegarADestino() {
    final double saldoDisponible = _parseSaldo();
    final double valorTransferencia = _parseValorIngresado();

    if (valorTransferencia > saldoDisponible) {
      _mostrarErrorSaldoInsuficiente();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ProductoDestinoScreen(
          valorTransferencia: _valorController.text,
          numeroCuenta: widget.numeroCuenta,
          saldoDisponible: widget.saldoDisponible,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEnabled = _valorController.text.isNotEmpty;

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
                  onTap: isEnabled ? _navegarADestino : null,
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
                  'Transferir plata',
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
                    fontSize: screenW * 0.045,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Valor',
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: screenW * 0.065,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenH * 0.03),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Número de cuenta',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.03,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenH * 0.005),
                    Text(
                      widget.numeroCuenta,
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.04,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_off_outlined,
                          size: screenW * 0.04,
                          color: Colors.grey,
                        ),
                        SizedBox(width: screenW * 0.01),
                        Text(
                          'Saldo disponible',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.03,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenH * 0.005),
                    Text(
                      '\$ ${widget.saldoDisponible}',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.045,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: screenH * 0.03),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
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
                  Text(
                    '\$',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.045,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: screenW * 0.03),
                  Expanded(
                    child: TextField(
                      controller: _valorController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.045,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ingresa el valor a transferir',
                        hintStyle: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.04,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
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
                onPressed: isEnabled ? _navegarADestino : null,
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
                  'Paso 2 de 4',
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
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
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
}
