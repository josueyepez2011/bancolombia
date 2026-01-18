import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../system/index.dart';
import '../utils/download_helper_factory.dart';
import 'home.dart';
import 'transacciones.dart';
import 'ajuste.dart';

class SelectQrScreen extends StatefulWidget {
  const SelectQrScreen({super.key});

  @override
  State<SelectQrScreen> createState() => _SelectQrScreenState();
}

class _SelectQrScreenState extends State<SelectQrScreen> {
  bool _isProcessing = false;

  // API Key de Groq
  static const String _groqApiKey =
      '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';

  // Leer QR - Local en móvil, API en web
  Future<String?> _readQrFromImage(Uint8List bytes) async {
    if (kIsWeb) {
      // Web: usar API externa (no hay soporte local confiable)
      return _readQrFromApi(bytes);
    } else {
      // Android/iOS: lectura local con mobile_scanner
      return _readQrLocal(bytes);
    }
  }

  // Lectura local con mobile_scanner (Android/iOS)
  Future<String?> _readQrLocal(Uint8List bytes) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/temp_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(bytes);

      final controller = MobileScannerController();
      final barcodes = await controller.analyzeImage(tempFile.path);
      await controller.dispose();

      // Limpiar archivo temporal
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (barcodes != null && barcodes.barcodes.isNotEmpty) {
        return barcodes.barcodes.first.rawValue;
      }
      return null;
    } catch (e) {
      debugPrint('Error leyendo QR local: $e');
      return null;
    }
  }

  // Lectura via API (solo para Web)
  Future<String?> _readQrFromApi(Uint8List bytes) async {
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
      debugPrint('Error leyendo QR API: $e');
      return null;
    }
  }

  // Enviar texto del QR a Groq para extraer el nombre
  Future<String> _extractNameWithGroq(
    String qrText, {
    bool soloNombre = false,
  }) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      // Detectar si contiene la palabra NEQUI (case insensitive)
      final bool isNequi = qrText.toUpperCase().contains('NEQUI');

      // Detectar si es QR EMV de pagos Bancolombia/Bre-B
      final bool isEmvPayment =
          qrText.startsWith('000201') && qrText.contains('CO.COM.RBM');

      String promptContent;
      if (soloNombre) {
        promptContent =
            'Del siguiente contenido de un código QR, extrae ÚNICAMENTE el nombre del destinatario, beneficiario o comercio. Responde SOLO con el nombre, sin explicaciones ni texto adicional:\n\n$qrText';
      } else if (isNequi) {
        promptContent =
            'Extrae del QR de NEQUI el nombre y teléfono (10 dígitos que empiezan por 3, antes de "0703CEL").\n\nEjemplo entrada: "5925CLAUDIA MARCELA LOZANOFL6012BOGOTA6221021031232472260703CEL"\nEjemplo salida: CLAUDIA MARCELA LOZANO - 3123247226\n\nIMPORTANTE: Responde ÚNICAMENTE con formato "NOMBRE - TELEFONO". Sin explicaciones.\n\nQR: $qrText';
      } else if (isEmvPayment) {
        promptContent =
            'Analiza este QR EMV Bancolombia/Bre-B.\n\nVALIDACIÓN: Debe contener "CO.COM.RBM". Si no, responde "QR NO VÁLIDO".\n\nEXTRAE:\n1. NOMBRE DEL COMERCIO: Texto legible que representa el nombre del negocio/comercio.\n2. LLAVE: Número de exactamente 10 dígitos consecutivos ubicado cerca de "CO.COM.RBM.CU".\n\nResponde ÚNICAMENTE: NOMBRE - LLAVE\n\nQR: $qrText';
      } else {
        promptContent =
            'Del siguiente contenido de un código QR, extrae ÚNICAMENTE el nombre del destinatario o beneficiario. Responde SOLO con el nombre, sin explicaciones ni texto adicional:\n\n$qrText';
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': promptContent},
          ],
          'max_tokens': 100,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] ?? '';
        return text.trim().isEmpty ? 'No disponible' : text.trim();
      }

      return 'Error: ${response.statusCode}';
    } catch (e) {
      debugPrint('Error Groq: $e');
      return 'Error: $e';
    }
  }

  Future<void> _openCameraScanner() async {
    if (_isProcessing) return;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => _CameraScannerScreen()),
    );

    if (result != null && mounted) {
      // Navegar a la misma pantalla de carga que usa la galería
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _LoadingQrScreen(
            qrTextDirect: result,
            extractNameWithGroq: _extractNameWithGroq,
          ),
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      Uint8List? bytes;

      if (kIsWeb) {
        // En web usamos FilePicker con withData
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );

        if (result != null && result.files.isNotEmpty) {
          bytes = result.files.first.bytes;
        }
      } else {
        // En Android/iOS usamos FilePicker sin withData y leemos el archivo
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final filePath = result.files.first.path;
          if (filePath != null) {
            final file = await File(filePath).readAsBytes();
            bytes = file;
          }
        }
      }

      if (bytes != null && mounted) {
        // Navegar INMEDIATAMENTE a la pantalla de carga
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _LoadingQrScreen(
              imageBytes: bytes!,
              readQrFromImage: _readQrFromImage,
              extractNameWithGroq: _extractNameWithGroq,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al acceder a la galería: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenW = MediaQuery.of(context).size.width;
    final Color bgColor = isDark
        ? const Color(0xFF282827)
        : const Color(0xFFF2F2F4);

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
          Positioned.fill(
            child: IgnorePointer(
              child: TransformableSvg(
                asset: 'assets/trazos/trazo_transfer.svg',
                offsetX: 0.44,
                offsetY: 0.88,
                scale: 1.39,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenW * 0.04,
                    vertical: screenW * 0.03,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.rotate(
                                angle: 3.14159,
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
                      ),
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
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenW * 0.06),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transferir con código QR',
                      style: TextStyle(
                        fontFamily: 'RegularCustom',
                        fontSize: screenW * 0.03,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Elige cómo escanear el QR',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.055,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenW * 0.06),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                  child: Column(
                    children: [
                      _buildQrOption(
                        context,
                        isDark: isDark,
                        leftIcon: 'assets/icons/pic-camera.svg',
                        leftIconSize: screenW * 0.06,
                        title: 'Cámara',
                        subtitle: 'Escanea el QR con la cámara del celular',
                        onTap: _openCameraScanner,
                      ),
                      SizedBox(height: screenW * 0.04),
                      _buildQrOption(
                        context,
                        isDark: isDark,
                        leftIcon: 'assets/icons/pic_picture.svg',
                        leftIconSize: screenW * 0.05,
                        title: 'Imagen',
                        subtitle: 'Selecciona una imagen de tu galería',
                        onTap: _pickImageFromGallery,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _QrBottomNavBar(isDark: isDark),
      ),
    );
  }

  Widget _buildQrOption(
    BuildContext context, {
    required bool isDark,
    required String leftIcon,
    required double leftIconSize,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final double screenW = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenW * 0.04,
          vertical: screenW * 0.03,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF454648) : Colors.white,
          borderRadius: BorderRadius.circular(screenW * 0.03),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              leftIcon,
              width: leftIconSize,
              height: leftIconSize,
              colorFilter: ColorFilter.mode(
                isDark ? Colors.white : Colors.black,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: screenW * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: screenW * 0.04,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: screenW * 0.03,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/icons/pic-chevron-right.png',
              width: screenW * 0.04,
              height: screenW * 0.04,
              color: isDark ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de carga a pantalla completa
class _LoadingQrScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? qrTextDirect;
  final Future<String?> Function(Uint8List)? readQrFromImage;
  final Future<String> Function(String, {bool soloNombre}) extractNameWithGroq;

  const _LoadingQrScreen({
    this.imageBytes,
    this.qrTextDirect,
    this.readQrFromImage,
    required this.extractNameWithGroq,
  });

  @override
  State<_LoadingQrScreen> createState() => _LoadingQrScreenState();
}

class _LoadingQrScreenState extends State<_LoadingQrScreen> {
  bool _isEnabled = false;
  String? _nombre;
  bool _esNequi = false;
  bool _showConfigError = false; // Para mostrar card de error de configuración

  // Datos de cuenta (se cargan de SharedPreferences)
  String _numeroCuenta = '';
  double _saldoDisponible = 0;

  // Datos del QR guardado (si coincide)
  Map<String, dynamic>? _qrGuardado;
  String _numeroCuentaDestino = '';
  String _tipoCuentaDestino = '';

  // Controller para el valor a transferir
  final TextEditingController _valorController = TextEditingController();
  String _valorFormateado = '';

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

  // Formatear número de cuenta: 34771103385 -> 347 - 711033 - 85
  String _formatNumeroCuenta(String numero) {
    if (numero.length < 11) return numero;
    return '${numero.substring(0, 3)} - ${numero.substring(3, 9)} - ${numero.substring(9)}';
  }

  // Formatear valor con puntos cada 3 dígitos
  String _formatValorInput(String value) {
    String digits = value.replaceAll('.', '');
    if (digits.isEmpty) return '';
    String result = '';
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      count++;
      result = digits[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }

  void _onValorChanged(String value) {
    String digits = value.replaceAll('.', '');
    if (digits.length > 12) {
      digits = digits.substring(0, 12);
    }
    final formatted = _formatValorInput(digits);
    setState(() {
      _valorFormateado = formatted;
    });
    _valorController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDatosCuenta();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processQr();
    });
  }

  Future<void> _loadDatosCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    String customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';

    // Si no hay número personalizado, generar uno aleatorio
    if (customAccount.isEmpty || customAccount.length != 11) {
      final random = math.Random();
      final part1 = random.nextInt(900) + 100; // 3 dígitos
      final part2 = random.nextInt(900000) + 100000; // 6 dígitos
      final part3 = random.nextInt(90) + 10; // 2 dígitos
      customAccount = '$part1$part2$part3';
    }

    setState(() {
      _numeroCuenta = customAccount;
      _saldoDisponible = prefs.getDouble('saldo_reserva') ?? 0;
    });
  }

  Future<void> _processQr() async {
    try {
      if (!mounted) return;

      String? qrText;

      // Si tenemos texto directo del QR (de la cámara), usarlo
      if (widget.qrTextDirect != null) {
        qrText = widget.qrTextDirect;
      } else if (widget.imageBytes != null && widget.readQrFromImage != null) {
        // Si tenemos imagen, leer el QR de ella
        qrText = await widget.readQrFromImage!(widget.imageBytes!);
      }

      if (qrText == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró ningún código QR en la imagen'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // PRIMERO: Buscar si el QR ya está guardado
      Map<String, dynamic>? qrGuardadoEncontrado;
      String numeroCuentaDestino = '';
      String tipoCuentaDestino = '';
      String nombre = '';
      bool esNequi = false;

      final prefs = await SharedPreferences.getInstance();
      final qrListJson = prefs.getString('qr_guardados') ?? '[]';
      final List<Map<String, dynamic>> qrGuardados =
          List<Map<String, dynamic>>.from(jsonDecode(qrListJson));

      // Buscar si el QR coincide con alguno guardado
      for (final qr in qrGuardados) {
        if (qr['qrText'] == qrText) {
          qrGuardadoEncontrado = qr;
          numeroCuentaDestino = qr['numeroCuenta'] ?? '';
          tipoCuentaDestino = qr['tipoCuenta'] ?? 'ahorros';
          nombre = qr['nombre'] ?? '';
          esNequi = false; // Si está guardado, NO es Nequi
          break;
        }
      }

      // Si encontró QR guardado, enviar a IA solo para extraer el nombre
      if (qrGuardadoEncontrado != null) {
        // Llamar a la IA solo para extraer el nombre (sin teléfono ni llave)
        nombre = await widget.extractNameWithGroq(qrText, soloNombre: true);

        debugPrint('========== QR GUARDADO ENCONTRADO ==========');
        debugPrint('Texto QR: $qrText');
        debugPrint('Nombre (de IA): $nombre');
        debugPrint('Número cuenta: $numeroCuentaDestino');
        debugPrint('Tipo cuenta: $tipoCuentaDestino');
        debugPrint('Es Nequi: $esNequi');
        debugPrint('=============================================');

        if (!mounted) return;

        setState(() {
          _nombre = nombre;
          _esNequi = esNequi;
          _qrGuardado = qrGuardadoEncontrado;
          _numeroCuentaDestino = numeroCuentaDestino;
          _tipoCuentaDestino = tipoCuentaDestino;
          _isEnabled = true;
        });
        return;
      }

      // Si NO está guardado, usar la IA para extraer datos completos
      nombre = await widget.extractNameWithGroq(qrText);

      // Detectar si es QR EMV de pagos Bancolombia/Bre-B (tiene CO.COM.RBM)
      final bool isApiKey =
          qrText.startsWith('000201') && qrText.contains('CO.COM.RBM');

      // Detectar si es Nequi (SOLO si contiene la palabra NEQUI)
      esNequi = qrText.toUpperCase().contains('NEQUI');

      // Si es Nequi, asignar automáticamente el tipo de cuenta como 'nequi'
      if (esNequi) {
        tipoCuentaDestino = 'nequi';
      }

      // Imprimir resultado en terminal
      debugPrint('========== RESULTADO QR (IA) ==========');
      debugPrint('Texto QR original: $qrText');
      debugPrint('Resultado extraído: $nombre');
      debugPrint('Es Nequi: $esNequi');
      debugPrint('Es ApiKey (Bre-B): $isApiKey');
      debugPrint('========================================');

      if (!mounted) return;

      // Si es ApiKey (QR EMV Bre-B), navegar a pantalla Bre-B
      if (isApiKey) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BreBScreen(nombre: nombre, qrText: qrText!),
          ),
        );
        return;
      }

      // Si no es Nequi y no es ApiKey, mostrar card de error (necesita configuración)
      if (!esNequi) {
        setState(() {
          _showConfigError = true;
        });
        return;
      }

      setState(() {
        _nombre = nombre;
        _esNequi = esNequi;
        _qrGuardado = qrGuardadoEncontrado;
        _numeroCuentaDestino = numeroCuentaDestino;
        _tipoCuentaDestino = tipoCuentaDestino;
        _isEnabled = true;
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;

    final Color bgColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F5F5);

    return SystemAwareScaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenW * 0.04,
                    vertical: screenW * 0.03,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancelar
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.close,
                              size: screenW * 0.05,
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
                      // Logo
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
                      // Continuar
                      GestureDetector(
                        onTap: _isEnabled
                            ? () {
                                debugPrint(
                                  'Procesando transferencia a: $_nombre',
                                );
                              }
                            : null,
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
                SizedBox(height: screenW * 0.04),
                // Transferir con código QR
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transferir con código QR',
                        style: TextStyle(
                          fontFamily: 'RegularCustom',
                          fontSize: screenW * 0.035,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: screenW * 0.01),
                      Text(
                        'Valor',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.06,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenW * 0.06),
                // Número de cuenta y Saldo disponible - títulos alineados
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Número de cuenta',
                        style: TextStyle(
                          fontFamily: 'RegularCustom',
                          fontSize: screenW * 0.035,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Saldo disponible',
                        style: TextStyle(
                          fontFamily: 'RegularCustom',
                          fontSize: screenW * 0.035,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenW * 0.02),
                // Valores de cuenta y saldo
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Número de cuenta
                      Text(
                        _formatNumeroCuenta(_numeroCuenta),
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.04,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      // Saldo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$ ${_formatNumber(_saldoDisponible)},',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.048,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: screenW * 0.008),
                            child: Text(
                              '00',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.032,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenW * 0.06),
                // Contenedor con signo de pesos y campo de texto
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                  child: Container(
                    width: double.infinity,
                    height: screenW * 0.32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF454648) : Colors.white,
                      borderRadius: BorderRadius.circular(screenW * 0.03),
                    ),
                    child: Stack(
                      children: [
                        // Línea en la mitad
                        Positioned(
                          left: screenW * 0.04,
                          right: screenW * 0.04,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                        // Signo de pesos y campo de texto
                        Positioned(
                          left: screenW * 0.06,
                          right: screenW * 0.06,
                          bottom: screenW * 0.16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '\$',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.07,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(width: screenW * 0.02),
                              Expanded(
                                child: TextField(
                                  controller: _valorController,
                                  keyboardType: TextInputType.number,
                                  onChanged: _onValorChanged,
                                  style: TextStyle(
                                    fontFamily: 'OpenSansRegular',
                                    fontSize: screenW * 0.05,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ingrese el valor a transferir',
                                    hintStyle: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.045,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Espacio restante
                const Expanded(child: SizedBox()),
                // Contenedor con botón y paso 1 de 1
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenW * 0.05,
                    vertical: screenW * 0.04,
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
                            _isEnabled && _valorController.text.isNotEmpty
                            ? () {
                                // Obtener el valor ingresado (quitar puntos y convertir a número)
                                final valorTexto = _valorController.text
                                    .replaceAll('.', '');
                                final valorIngresado =
                                    double.tryParse(valorTexto) ?? 0;

                                // Validar que el valor no sea mayor al saldo disponible
                                if (valorIngresado > _saldoDisponible) {
                                  // Mostrar alerta de saldo insuficiente
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Saldo insuficiente'),
                                      content: Text(
                                        'El valor ingresado (\$${_valorController.text}) supera tu saldo disponible (\$${_formatNumber(_saldoDisponible)}).',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Entendido'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                debugPrint(
                                  'Procesando transferencia a: $_nombre',
                                );
                                debugPrint('Valor: ${_valorController.text}');

                                // Extraer el número de celular y nombre del resultado (formato: "Nombre - Teléfono")
                                String numeroCelular = '';
                                String nombreDestinatario = '';
                                if (_nombre != null &&
                                    _nombre!.contains(' - ')) {
                                  final partes = _nombre!.split(' - ');
                                  nombreDestinatario = partes.first.trim();
                                  numeroCelular = partes.last.trim();
                                } else if (_nombre != null) {
                                  nombreDestinatario = _nombre!;
                                }

                                // Navegar a la pantalla de confirmación
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ConfirmacionTransferenciaQrScreen(
                                          valorTransferencia:
                                              _valorController.text,
                                          numeroCelular: _esNequi
                                              ? numeroCelular
                                              : _numeroCuentaDestino,
                                          numeroCuenta: _formatNumeroCuenta(
                                            _numeroCuenta,
                                          ),
                                          nombreDestinatario:
                                              nombreDestinatario,
                                          esNequi: _esNequi,
                                          tipoCuentaDestino: _tipoCuentaDestino,
                                        ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, screenW * 0.12),
                          backgroundColor:
                              _isEnabled && _valorController.text.isNotEmpty
                              ? const Color(0xFFFFD700)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color:
                                  _isEnabled && _valorController.text.isNotEmpty
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
                                _isEnabled && _valorController.text.isNotEmpty
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: screenW * 0.03),
                      // Paso 1 de 1 con línea amarilla
                      Row(
                        children: [
                          Text(
                            'Paso 1 de 1',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.035,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(width: screenW * 0.03),
                          Container(
                            width: screenW * 0.65,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card de error de configuración
          if (_showConfigError)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: screenW * 0.08),
                    padding: EdgeInsets.all(screenW * 0.06),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF454648) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: screenW * 0.15,
                          color: const Color(0xFFFFD700),
                        ),
                        SizedBox(height: screenH * 0.02),
                        Text(
                          'Configura QR Bancolombia',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.05,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenH * 0.01),
                        Text(
                          'Este código QR no está configurado. Por favor, agrégalo en Ajustes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: screenH * 0.03),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              padding: EdgeInsets.symmetric(
                                vertical: screenH * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Entendido',
                              style: TextStyle(
                                fontFamily: 'OpenSansSemibold',
                                fontSize: screenW * 0.04,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============ CONFIRMACION TRANSFERENCIA QR SCREEN ============
class ConfirmacionTransferenciaQrScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCelular;
  final String numeroCuenta;
  final String nombreDestinatario;
  final bool esNequi;
  final String tipoCuentaDestino;

  const ConfirmacionTransferenciaQrScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCelular,
    this.numeroCuenta = '000 - 000000 - 00',
    this.nombreDestinatario = '',
    this.esNequi = false,
    this.tipoCuentaDestino = '',
  }) : super(key: key);

  @override
  State<ConfirmacionTransferenciaQrScreen> createState() =>
      _ConfirmacionTransferenciaQrScreenState();
}

class _ConfirmacionTransferenciaQrScreenState
    extends State<ConfirmacionTransferenciaQrScreen> {
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

  // Formatear número de cuenta destino: 12345678901 -> 123-456789-01
  String _formatNumeroCuentaDestino(String numero) {
    if (numero.length != 11) return numero;
    return '${numero.substring(0, 3)}-${numero.substring(3, 9)}-${numero.substring(9)}';
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
                            angle: 3.14159,
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
                      widget.esNequi
                          ? 'Transferir a Nequi'
                          : 'Transferir a Bancolombia',
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
                      // Datos código QR
                      Text(
                        'Datos código QR',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.045,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenH * 0.015),
                      // Descripción del QR
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
                              'Descripción del QR',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Text(
                              widget.nombreDestinatario,
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize: screenW * 0.04,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenH * 0.01),
                      // Valor a transferir
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
                      SizedBox(height: screenH * 0.01),
                      // Costo de la transferencia
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
                              'Costo de la transferencia',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$ 0,',
                                  style: TextStyle(
                                    fontFamily: 'OpenSansBold',
                                    fontSize: screenW * 0.045,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: screenW * 0.005,
                                  ),
                                  child: Text(
                                    '00',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.03,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
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
                              widget.esNequi
                                  ? 'Nequi'
                                  : 'Cuenta ${widget.tipoCuentaDestino == 'corriente' ? 'Corriente' : 'Ahorros'} Bancolombia',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Text(
                              widget.esNequi
                                  ? widget.numeroCelular
                                  : _formatNumeroCuentaDestino(
                                      widget.numeroCelular,
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
                        onPressed: () async {
                          setState(() => _showCircle = true);

                          // Descontar el saldo
                          final prefs = await SharedPreferences.getInstance();
                          final saldoActual =
                              prefs.getDouble('saldo_reserva') ?? 0;
                          final valorLimpio = widget.valorTransferencia
                              .replaceAll(RegExp(r'\D'), '');
                          final valorTransferido =
                              double.tryParse(valorLimpio) ?? 0;
                          final nuevoSaldo = saldoActual - valorTransferido;
                          await prefs.setDouble(
                            'saldo_reserva',
                            nuevoSaldo > 0 ? nuevoSaldo : 0,
                          );

                          // Guardar el movimiento en movimientos_bancolombia
                          final movimientosJson =
                              prefs.getString('movimientos_bancolombia') ??
                              '[]';
                          final List<dynamic> movimientos = jsonDecode(
                            movimientosJson,
                          );
                          final nuevoMovimiento = {
                            'fecha': DateTime.now().toIso8601String(),
                            'descripcion': widget.esNequi
                                ? 'PAGO QR NEQUI'
                                : 'PAGO BANCOLOMBIA',
                            'valor': valorTransferido,
                            'tipo': 'debito',
                          };
                          movimientos.insert(0, nuevoMovimiento);
                          await prefs.setString(
                            'movimientos_bancolombia',
                            jsonEncode(movimientos),
                          );

                          Future.delayed(const Duration(seconds: 9), () {
                            if (mounted) {
                              setState(() => _showCircle = false);
                              // Navegar al comprobante
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ComprobanteQrScreen(
                                    valorTransferencia:
                                        widget.valorTransferencia,
                                    numeroCelular: widget.numeroCelular,
                                    nombreDestinatario:
                                        widget.nombreDestinatario,
                                    esNequi: widget.esNequi,
                                    tipoCuentaDestino: widget.tipoCuentaDestino,
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
          // Círculo centrado con loading
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

// ============ COMPROBANTE QR SCREEN ============
class ComprobanteQrScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCelular;
  final String nombreDestinatario;
  final bool esNequi;
  final String tipoCuentaDestino;
  final String numeroCuenta;

  const ComprobanteQrScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCelular,
    this.nombreDestinatario = '',
    this.esNequi = false,
    this.tipoCuentaDestino = '',
    this.numeroCuenta = '',
  }) : super(key: key);

  @override
  State<ComprobanteQrScreen> createState() => _ComprobanteQrScreenState();
}

class _ComprobanteQrScreenState extends State<ComprobanteQrScreen> {
  String _numeroCuentaPersonalizado = '';

  String get _numeroComprobante {
    final random = math.Random();
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

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

  String _formatearCuentaDestino(String cuenta) {
    final limpio = cuenta.replaceAll(RegExp(r'\D'), '');
    if (limpio.length == 11) {
      return '${limpio.substring(0, 3)}-${limpio.substring(3, 9)}-${limpio.substring(9, 11)}';
    }
    return cuenta;
  }

  String get _ultimos4Digitos {
    final cuenta = _numeroCuentaPersonalizado.isNotEmpty
        ? _numeroCuentaPersonalizado
        : widget.numeroCuenta;
    final limpio = cuenta.replaceAll(RegExp(r'\D'), '');
    if (limpio.length >= 4) {
      return '*${limpio.substring(limpio.length - 4)}';
    }
    return '*0000';
  }

  @override
  void initState() {
    super.initState();
    _loadNumeroCuentaPersonalizado();
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
          'comprobante_qr_bancolombia.png',
        );
      } else {
        // Para móvil: compartir la imagen
        await downloadHelper.downloadImage(
          pngBytes,
          'comprobante_qr_bancolombia.png',
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
                widget.nombreDestinatario,
                'Valor de la transferencia',
                '\$ ${_formatearValor(widget.valorTransferencia)}',
              ),
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

  Widget _buildCardForCapture(
    double screenW,
    bool isDark,
    String title,
    String? descripcionQr,
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
                  if (descripcionQr != null && descripcionQr.isNotEmpty) ...[
                    Text(
                      'Descripción del QR',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.035,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenW * 0.01),
                    Text(
                      descripcionQr.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.045,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenW * 0.03),
                  ],
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
                  SizedBox(height: screenW * 0.03),
                  Text(
                    'Costo de la transferencia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.01),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$ 0,',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.05,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: screenW * 0.005),
                        child: Text(
                          '00',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
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
                  // Solo mostrar nombre si NO es Nequi
                  if (!widget.esNequi) ...[
                    Text(
                      widget.nombreDestinatario.isNotEmpty
                          ? widget.nombreDestinatario
                          : 'Destinatario',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.045,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenW * 0.01),
                  ],
                  Text(
                    widget.esNequi
                        ? 'Nequi'
                        : '${widget.tipoCuentaDestino == 'corriente' ? 'Corriente' : 'Ahorros'} - Bancolombia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.01),
                  Text(
                    widget.esNequi
                        ? widget.numeroCelular
                        : _formatearCuentaDestino(widget.numeroCelular),
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
                  SizedBox(height: screenW * 0.01),
                  Text(
                    'Ahorros',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.01),
                  Text(
                    _ultimos4Digitos,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenW * 0.03),
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
                  SizedBox(height: screenW * 0.01),
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

  Widget _buildNavBarForCapture(double screenW, bool isDark) {
    return Container(
      height: 80,
      margin: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItemForCapture(
            icon: 'assets/icons/home.svg',
            label: 'Inicio',
            isDark: isDark,
            screenW: screenW,
          ),
          _buildNavItemForCapture(
            icon: 'assets/icons/pic-cards.svg',
            label: 'Transacciones',
            isDark: isDark,
            screenW: screenW,
          ),
          _buildNavItemForCapture(
            icon: 'assets/icons/pic-explore.svg',
            label: 'Explorar',
            isDark: isDark,
            screenW: screenW,
          ),
          _buildNavItemForCapture(
            icon: 'assets/icons/pic-hand-holding-document.svg',
            label: 'Trámites',
            isDark: isDark,
            screenW: screenW,
          ),
          _buildNavItemForCapture(
            icon: 'assets/icons/settings.svg',
            label: 'Ajustes',
            isDark: isDark,
            screenW: screenW,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItemForCapture({
    required String icon,
    required String label,
    required bool isDark,
    required double screenW,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          icon,
          width: screenW * 0.06,
          height: screenW * 0.06,
          colorFilter: ColorFilter.mode(
            isDark ? Colors.white : Colors.black,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'OpenSansRegular',
            fontSize: screenW * 0.025,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double circleSize = screenW * 0.15;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      body: Stack(
        children: [
          // Trazo de fondo
          Positioned(
            top: screenH * 0.2,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: SvgPicture.asset(
                  'assets/trazos/trazo-comprobante.svg',
                  width: screenW,
                  height: screenW,
                ),
              ),
            ),
          ),
          // Contenido
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenH * 0.02),
                // Header - CIB centrado con Cerrar sesión
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
                            width: screenW * 0.1,
                            height: screenW * 0.1,
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
                SizedBox(height: screenH * 0.04),
                // Círculo de éxito
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
                // Card Datos de la transferencia
                _buildCardDatos(screenW, screenH, isDark),
                SizedBox(height: screenH * 0.02),
                // Card Producto destino
                _buildCardDestino(screenW, screenH, isDark),
                SizedBox(height: screenH * 0.02),
                // Card Producto origen
                _buildCardOrigen(screenW, screenH, isDark),
                SizedBox(height: screenH * 0.03),
                // Botones de acción
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenW * 0.04),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF454648) : Colors.white,
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
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const SelectQrScreen(),
                              ),
                              (route) => false,
                            );
                          },
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
        ],
      ),
      bottomNavigationBar: _QrBottomNavBar(isDark: isDark),
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

  Widget _buildCardDatos(double screenW, double screenH, bool isDark) {
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
                  // Descripción del QR (siempre se muestra)
                  Text(
                    'Descripción del QR',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenH * 0.005),
                  Text(
                    widget.nombreDestinatario.isNotEmpty
                        ? widget.nombreDestinatario.toUpperCase()
                        : 'DESTINATARIO',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenH * 0.02),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$ 0,',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.05,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: screenW * 0.005),
                        child: Text(
                          '00',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDestino(double screenW, double screenH, bool isDark) {
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
                  // Solo mostrar nombre si NO es Nequi
                  if (!widget.esNequi) ...[
                    Text(
                      widget.nombreDestinatario.isNotEmpty
                          ? widget.nombreDestinatario
                          : 'Destinatario',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: screenW * 0.045,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenH * 0.005),
                  ],
                  Text(
                    widget.esNequi
                        ? 'Nequi'
                        : '${widget.tipoCuentaDestino == 'corriente' ? 'Corriente' : 'Ahorros'} - Bancolombia',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenH * 0.005),
                  Text(
                    widget.esNequi
                        ? widget.numeroCelular
                        : _formatearCuentaDestino(widget.numeroCelular),
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

  Widget _buildCardOrigen(double screenW, double screenH, bool isDark) {
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
}

// Pantalla de escáner de cámara
class _CameraScannerScreen extends StatefulWidget {
  @override
  State<_CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<_CameraScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      // Esperar un momento para que la cámara se inicialice
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al inicializar la cámara: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _hasScanned = true;
        debugPrint('QR detectado: ${barcode.rawValue}');
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mostrar error si hay
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Error al acceder a la cámara',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                        });
                        _initializeCamera();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Cámara
            if (_controller != null)
              MobileScanner(
                controller: _controller!,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error: ${error.errorDetails?.message ?? error.toString()}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            // Overlay con marco de escaneo
            CustomPaint(painter: _ScannerOverlayPainter(), child: Container()),
            // Línea de escaneo animada
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final double scanAreaSize = screenW * 0.7;
                final double left = (screenW - scanAreaSize) / 2;
                final double screenH = MediaQuery.of(context).size.height;
                final double top = (screenH - scanAreaSize) / 2;
                final double lineY = top + (_animation.value * scanAreaSize);

                return Stack(
                  children: [
                    // Estela (gradiente detrás de la línea)
                    Positioned(
                      left: left + 20,
                      top: top,
                      child: Container(
                        width: scanAreaSize - 40,
                        height: _animation.value * scanAreaSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFD700).withOpacity(0.02),
                              const Color(0xFFFFD700).withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Línea principal
                    Positioned(
                      left: left + 20,
                      top: lineY,
                      child: Container(
                        width: scanAreaSize - 40,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFD700),
                              const Color(0xFFFFD700),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.1, 0.9, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          // Header
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenW * 0.03,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close,
                          size: screenW * 0.05,
                          color: Colors.white,
                        ),
                        SizedBox(width: screenW * 0.02),
                        Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.045,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/CIB.svg',
                    width: screenW * 0.08,
                    height: screenW * 0.08,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: screenW * 0.2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para el overlay del escáner
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    // Dibujar fondo oscuro con hueco en el centro
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
          const Radius.circular(12),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Dibujar esquinas del marco
    final Paint cornerPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerLength = 30;
    final double radius = 12;

    // Esquina superior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(
          Offset(left + radius, top),
          radius: Radius.circular(radius),
        )
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top)
        ..lineTo(left + scanAreaSize - radius, top)
        ..arcToPoint(
          Offset(left + scanAreaSize, top + radius),
          radius: Radius.circular(radius),
        )
        ..lineTo(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanAreaSize - cornerLength)
        ..lineTo(left, top + scanAreaSize - radius)
        ..arcToPoint(
          Offset(left + radius, top + scanAreaSize),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
        ..lineTo(left + scanAreaSize - radius, top + scanAreaSize)
        ..arcToPoint(
          Offset(left + scanAreaSize, top + scanAreaSize - radius),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pantalla Bre-B para pagos con QR EMV (ApiKey)
class BreBScreen extends StatefulWidget {
  final String nombre;
  final String qrText;

  const BreBScreen({super.key, required this.nombre, required this.qrText});

  @override
  State<BreBScreen> createState() => _BreBScreenState();
}

class _BreBScreenState extends State<BreBScreen> {
  String _numeroCuenta = '';
  double _saldoDisponible = 0;
  final TextEditingController _valorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDatosCuenta();
  }

  Future<void> _loadDatosCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _numeroCuenta = prefs.getString('numero_cuenta_personalizado') ?? '';
      _saldoDisponible = prefs.getDouble('saldo_reserva') ?? 0;
    });
  }

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

  String _formatNumeroCuenta(String numero) {
    if (numero.length < 11) return numero;
    return '${numero.substring(0, 3)} - ${numero.substring(3, 9)} - ${numero.substring(9)}';
  }

  void _onValorChanged(String value) {
    String digits = value.replaceAll('.', '');
    if (digits.length > 12) {
      digits = digits.substring(0, 12);
    }
    String result = '';
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      count++;
      result = digits[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    _valorController.value = TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenW = MediaQuery.of(context).size.width;

    final Color bgColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F5F5);

    // Extraer nombre y llave del resultado de la IA
    String nombreComercio = '';
    String llaveComercio = '';
    if (widget.nombre.contains(' - ')) {
      final partes = widget.nombre.split(' - ');
      nombreComercio = partes.first.trim();
      llaveComercio = partes.last.trim();
    } else {
      nombreComercio = widget.nombre;
    }

    return SystemAwareScaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenW * 0.03,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close,
                          size: screenW * 0.05,
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
                  SvgPicture.asset(
                    'assets/icons/bre-b-green.svg',
                    width: screenW * 0.12,
                    height: screenW * 0.12,
                  ),
                  SizedBox(width: screenW * 0.2),
                ],
              ),
            ),
            SizedBox(height: screenW * 0.04),
            // Título
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pago con QR Bre-B',
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenW * 0.01),
                  Text(
                    nombreComercio,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.06,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (llaveComercio.isNotEmpty)
                    Text(
                      'Llave: $llaveComercio',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.035,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: screenW * 0.06),
            // Cuenta y saldo
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Número de cuenta',
                        style: TextStyle(
                          fontFamily: 'RegularCustom',
                          fontSize: screenW * 0.035,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatNumeroCuenta(_numeroCuenta),
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
                      Text(
                        'Saldo disponible',
                        style: TextStyle(
                          fontFamily: 'RegularCustom',
                          fontSize: screenW * 0.035,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$ ${_formatNumber(_saldoDisponible)},00',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.04,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenW * 0.06),
            // Campo de valor
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenW * 0.04),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF454648) : Colors.white,
                  borderRadius: BorderRadius.circular(screenW * 0.03),
                ),
                child: Row(
                  children: [
                    Text(
                      '\$',
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.07,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(width: screenW * 0.02),
                    Expanded(
                      child: TextField(
                        controller: _valorController,
                        keyboardType: TextInputType.number,
                        onChanged: _onValorChanged,
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.05,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ingrese el valor a pagar',
                          hintStyle: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Botón continuar
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenW * 0.04),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF454648) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ElevatedButton(
                onPressed: _valorController.text.isNotEmpty
                    ? () {
                        // TODO: Implementar lógica de pago Bre-B
                        debugPrint(
                          'Pago Bre-B: $nombreComercio - ${_valorController.text}',
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, screenW * 0.12),
                  backgroundColor: _valorController.text.isNotEmpty
                      ? const Color(0xFF00C853)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: _valorController.text.isNotEmpty
                          ? const Color(0xFF00C853)
                          : Colors.white,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continuar',
                  style: TextStyle(
                    fontFamily: 'OpenSansSemibold',
                    fontSize: screenW * 0.045,
                    color: _valorController.text.isNotEmpty
                        ? Colors.white
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Barra de navegación para pantallas de QR (sin selección)
class _QrBottomNavBar extends StatefulWidget {
  final bool isDark;

  const _QrBottomNavBar({required this.isDark});

  @override
  State<_QrBottomNavBar> createState() => _QrBottomNavBarState();
}

class _QrBottomNavBarState extends State<_QrBottomNavBar> {
  int selectedIndex = -1; // Ninguno seleccionado

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
        ? const Color(0xFF282827)
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
                    // Inicio
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  } else if (index == 1) {
                    // Transacciones
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransaccionesScreen(),
                      ),
                    );
                  } else if (index == 4) {
                    // Ajustes
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AjusteScreen(),
                      ),
                    );
                  } else {
                    // Otros índices (2 y 3) no hacen nada por ahora
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
