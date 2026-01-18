import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'victimas_bancolombia_screen.dart';
import '../system/index.dart';

class AjustesAvanzadosScreen extends StatefulWidget {
  const AjustesAvanzadosScreen({super.key});

  @override
  State<AjustesAvanzadosScreen> createState() => _AjustesAvanzadosScreenState();
}

class _AjustesAvanzadosScreenState extends State<AjustesAvanzadosScreen> {
  String _numeroCuenta = '';

  @override
  void initState() {
    super.initState();
    _loadNumeroCuenta();
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
        title: Text(
          'Personalizar cuenta',
          style: TextStyle(
            fontFamily: 'RegularCustom',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          style: TextStyle(
            fontFamily: 'RegularCustom',
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: 'Número de cuenta',
            labelStyle: TextStyle(
              fontFamily: 'RegularCustom',
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            counterStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'RegularCustom',
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _numeroCuenta = controller.text;
              });
              _saveNumeroCuenta(controller.text);
              Navigator.pop(context);
            },
            child: const Text(
              'Guardar',
              style: TextStyle(
                fontFamily: 'RegularCustom',
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF2F2F4);
    final Color cardColor = isDark ? const Color(0xFF3C3C3C) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return SystemAwareScaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          'Ajustes avanzados',
          style: TextStyle(fontFamily: 'RegularCustom', color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VictimasNequiScreen(),
                  ),
                );
              },
              child: _buildMenuItem(
                icon: 'assets/icons/pic-cards.svg',
                title: 'Configurar Bancolombia víctimas',
                cardColor: cardColor,
                textColor: textColor,
                isDark: isDark,
                iconColor: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _editarNumeroCuenta,
              child: _buildMenuItem(
                icon: 'assets/icons/settings.svg',
                title: 'Personalizar cuenta',
                cardColor: cardColor,
                textColor: textColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
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
}
