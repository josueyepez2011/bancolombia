import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../system/index.dart';

class QrGuardadosScreen extends StatefulWidget {
  const QrGuardadosScreen({super.key});

  @override
  State<QrGuardadosScreen> createState() => _QrGuardadosScreenState();
}

class _QrGuardadosScreenState extends State<QrGuardadosScreen> {
  List<Map<String, dynamic>> _qrGuardados = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQrGuardados();
  }

  Future<void> _loadQrGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final qrListJson = prefs.getString('qr_guardados') ?? '[]';
    setState(() {
      _qrGuardados = List<Map<String, dynamic>>.from(jsonDecode(qrListJson));
    });
  }

  Future<void> _saveQrGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qr_guardados', jsonEncode(_qrGuardados));
  }

  Future<String?> _readQrFromImage(Uint8List bytes) async {
    try {
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('https://grand-cajeta-32e7cd.netlify.app/api/read-qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'].toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error leyendo QR: $e');
      return null;
    }
  }

  Future<void> _agregarQr() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final qrText = await _readQrFromImage(bytes);

          if (qrText == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se encontró código QR en la imagen'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          // Verificar si ya existe
          final existe = _qrGuardados.any((qr) => qr['qrText'] == qrText);
          if (existe) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Este código QR ya está guardado'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          // Guardar imagen en base64
          final imageBase64 = base64Encode(bytes);

          // Mostrar diálogo para ingresar datos
          if (mounted) {
            _mostrarDialogoNuevoQr(qrText, imageBase64);
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarDialogoNuevoQr(String qrText, String imageBase64) {
    final nombreController = TextEditingController();
    final cuentaController = TextEditingController();
    String tipoCuenta = 'ahorros';

    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
              title: Text(
                'Nuevo QR Bancolombia',
                style: TextStyle(
                  fontFamily: 'OpenSansBold',
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre/Alias
                    TextField(
                      controller: nombreController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Alias para identificar',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Número de cuenta
                    TextField(
                      controller: cuentaController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Número de cuenta (11 dígitos)',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tipo de cuenta
                    Text(
                      'Tipo de cuenta',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => tipoCuenta = 'ahorros');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tipoCuenta == 'ahorros'
                                    ? const Color(0xFFFFD700)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: tipoCuenta == 'ahorros'
                                      ? const Color(0xFFFFD700)
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Ahorros',
                                  style: TextStyle(
                                    color: tipoCuenta == 'ahorros'
                                        ? Colors.black
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                    fontWeight: tipoCuenta == 'ahorros'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => tipoCuenta = 'corriente');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tipoCuenta == 'corriente'
                                    ? const Color(0xFFFFD700)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: tipoCuenta == 'corriente'
                                      ? const Color(0xFFFFD700)
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Corriente',
                                  style: TextStyle(
                                    color: tipoCuenta == 'corriente'
                                        ? Colors.black
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                    fontWeight: tipoCuenta == 'corriente'
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (nombreController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa un alias')),
                      );
                      return;
                    }
                    if (cuentaController.text.length != 11) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El número de cuenta debe tener 11 dígitos',
                          ),
                        ),
                      );
                      return;
                    }

                    final nuevoQr = {
                      'qrText': qrText,
                      'nombre': nombreController.text.trim(),
                      'numeroCuenta': cuentaController.text.trim(),
                      'tipoCuenta': tipoCuenta,
                      'imageBase64': imageBase64,
                    };

                    setState(() {
                      _qrGuardados.add(nuevoQr);
                    });
                    _saveQrGuardados();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR guardado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminarQr(int index) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
          title: Text(
            '¿Eliminar QR?',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Se eliminará "${_qrGuardados[index]['nombre']}"',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _qrGuardados.removeAt(index);
                });
                _saveQrGuardados();
                Navigator.pop(context);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatNumeroCuenta(String numero) {
    if (numero.length != 11) return numero;
    return '${numero.substring(0, 3)}-${numero.substring(3, 9)}-${numero.substring(9)}';
  }

  void _mostrarQrFlotante(Map<String, dynamic> qr) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final imageBase64 = qr['imageBase64'] as String?;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenedor del QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre
                  Text(
                    qr['nombre'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Imagen del QR
                  if (imageBase64 != null && imageBase64.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(imageBase64),
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Info de cuenta
                  Text(
                    '${qr['tipoCuenta'] == 'ahorros' ? 'Ahorros' : 'Corriente'}',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatNumeroCuenta(qr['numeroCuenta'] ?? ''),
                    style: const TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botón cerrar
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white24
                      : Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: isDark ? Colors.white : Colors.black,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenW = MediaQuery.of(context).size.width;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QRs Bancolombia',
          style: TextStyle(
            fontFamily: 'OpenSansBold',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Botón agregar
          Padding(
            padding: EdgeInsets.all(screenW * 0.04),
            child: GestureDetector(
              onTap: _isLoading ? null : _agregarQr,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenW * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    else
                      const Icon(Icons.add, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? 'Cargando...' : 'Agregar código QR',
                      style: const TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Lista de QRs
          Expanded(
            child: _qrGuardados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 80,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay QRs guardados',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega un QR de Bancolombia\npara usarlo en transferencias',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                    itemCount: _qrGuardados.length,
                    itemBuilder: (context, index) {
                      final qr = _qrGuardados[index];
                      final imageBase64 = qr['imageBase64'] as String?;
                      return GestureDetector(
                        onLongPress: () => _mostrarQrFlotante(qr),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3C3C3C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Imagen del QR o icono por defecto
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    imageBase64 != null &&
                                        imageBase64.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(imageBase64),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.qr_code,
                                        color: Color(0xFFFFD700),
                                        size: 22,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      qr['nombre'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${qr['tipoCuenta'] == 'ahorros' ? 'Ahorros' : 'Corriente'} • ${_formatNumeroCuenta(qr['numeroCuenta'] ?? '')}',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansRegular',
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                onPressed: () => _eliminarQr(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
