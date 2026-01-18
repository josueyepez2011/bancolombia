import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../system/index.dart';
import '../widgets/error_widgets.dart';

class VictimasNequiScreen extends StatefulWidget {
  const VictimasNequiScreen({super.key});

  @override
  State<VictimasNequiScreen> createState() => _VictimasNequiScreenState();
}

class _VictimasNequiScreenState extends State<VictimasNequiScreen> {
  List<Map<String, String>> _victimas = [];

  @override
  void initState() {
    super.initState();
    _loadVictimas();
  }

  Future<void> _loadVictimas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('victimas_bancolombia');
      if (data != null) {
        setState(() {
          _victimas = List<Map<String, String>>.from(
            json.decode(data).map((x) => Map<String, String>.from(x)),
          );
        });
      }
    } catch (e) {
      debugPrint('Error cargando víctimas: $e');
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: 'Error al cargar las víctimas',
          isError: true,
        );
      }
    }
  }

  Future<void> _saveVictimas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('victimas_bancolombia', json.encode(_victimas));
    } catch (e) {
      debugPrint('Error guardando víctimas: $e');
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: 'Error al guardar las víctimas',
          isError: true,
        );
      }
    }
  }

  void _agregarVictima() {
    final nombreController = TextEditingController();
    final cuentaController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    int tipoProducto = 1;

    final screenH = MediaQuery.of(context).size.height;
    final titleFontSize = (screenH * 0.018).clamp(14.0, 16.0);
    final bodyFontSize = (screenH * 0.016).clamp(12.0, 14.0);
    final smallFontSize = (screenH * 0.014).clamp(10.0, 12.0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenH * 0.02,
            vertical: screenH * 0.05,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenH * 0.02),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Agregar víctima Bancolombia',
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.015),
                  TextField(
                    controller: nombreController,
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: bodyFontSize,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(
                        fontFamily: 'RegularCustom',
                        fontSize: smallFontSize,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenH * 0.01,
                        vertical: screenH * 0.008,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  SizedBox(height: screenH * 0.01),
                  TextField(
                    controller: cuentaController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: bodyFontSize,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Número de cuenta (11 dígitos)',
                      labelStyle: TextStyle(
                        fontFamily: 'RegularCustom',
                        fontSize: smallFontSize,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenH * 0.01,
                        vertical: screenH * 0.008,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      counterStyle: TextStyle(
                        fontSize: smallFontSize * 0.8,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                  SizedBox(height: screenH * 0.01),
                  Text(
                    'Tipo de producto',
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: smallFontSize,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  SizedBox(height: screenH * 0.008),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => tipoProducto = 1),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: screenH * 0.008,
                            ),
                            decoration: BoxDecoration(
                              color: tipoProducto == 1
                                  ? const Color(0xFFFFD700)
                                  : (isDark
                                        ? const Color(0xFF454648)
                                        : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'Ahorros',
                                style: TextStyle(
                                  fontFamily: 'RegularCustom',
                                  fontSize: smallFontSize,
                                  color: tipoProducto == 1
                                      ? Colors.black
                                      : (isDark ? Colors.white : Colors.black),
                                  fontWeight: tipoProducto == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenH * 0.008),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => tipoProducto = 2),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: screenH * 0.008,
                            ),
                            decoration: BoxDecoration(
                              color: tipoProducto == 2
                                  ? const Color(0xFFFFD700)
                                  : (isDark
                                        ? const Color(0xFF454648)
                                        : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'Corriente',
                                style: TextStyle(
                                  fontFamily: 'RegularCustom',
                                  fontSize: smallFontSize,
                                  color: tipoProducto == 2
                                      ? Colors.black
                                      : (isDark ? Colors.white : Colors.black),
                                  fontWeight: tipoProducto == 2
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenH * 0.015),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'RegularCustom',
                            fontSize: smallFontSize,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(width: screenH * 0.01),
                      TextButton(
                        onPressed: () {
                          if (nombreController.text.isNotEmpty &&
                              cuentaController.text.length == 11) {
                            try {
                              setState(() {
                                _victimas.add({
                                  'nombre': nombreController.text,
                                  'cuenta': cuentaController.text,
                                  'tipo': tipoProducto == 1
                                      ? 'Ahorros'
                                      : 'Corriente',
                                });
                              });
                              _saveVictimas();
                              Navigator.pop(context);
                              ErrorSnackBar.show(
                                context,
                                message: 'Víctima agregada correctamente',
                                isError: false,
                              );
                            } catch (e) {
                              debugPrint('Error agregando víctima: $e');
                              ErrorSnackBar.show(
                                context,
                                message: 'Error al agregar la víctima',
                                isError: true,
                              );
                            }
                          } else {
                            ErrorSnackBar.show(
                              context,
                              message: 'Por favor completa todos los campos correctamente',
                              isError: true,
                            );
                          }
                        },
                        child: Text(
                          'Guardar',
                          style: TextStyle(
                            fontFamily: 'RegularCustom',
                            fontSize: smallFontSize,
                            color: const Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _eliminarVictima(int index) {
    try {
      setState(() {
        _victimas.removeAt(index);
      });
      _saveVictimas();
      ErrorSnackBar.show(
        context,
        message: 'Víctima eliminada correctamente',
        isError: false,
      );
    } catch (e) {
      debugPrint('Error eliminando víctima: $e');
      ErrorSnackBar.show(
        context,
        message: 'Error al eliminar la víctima',
        isError: true,
      );
    }
  }

  String _formatearCuenta(String cuenta) {
    if (cuenta.length == 11) {
      return '${cuenta.substring(0, 3)}-${cuenta.substring(3, 9)}-${cuenta.substring(9, 11)}';
    }
    return cuenta;
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
          'Bancolombia Víctimas',
          style: TextStyle(fontFamily: 'RegularCustom', color: textColor),
        ),
      ),
      body: _victimas.isEmpty
          ? Center(
              child: Text(
                'No hay víctimas guardadas',
                style: TextStyle(
                  fontFamily: 'RegularCustom',
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _victimas.length,
              itemBuilder: (context, index) {
                final victima = _victimas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFFD700),
                        child: Text(
                          victima['nombre']![0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              victima['nombre']!,
                              style: TextStyle(
                                fontFamily: 'RegularCustom',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${victima['tipo'] ?? 'Ahorros'} - ${_formatearCuenta(victima['cuenta']!)}',
                              style: TextStyle(
                                fontFamily: 'RegularCustom',
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[400]),
                        onPressed: () => _eliminarVictima(index),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarVictima,
        backgroundColor: const Color(0xFFFFD700),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
