import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../system/index.dart';

class MovimientoScreen extends StatefulWidget {
  const MovimientoScreen({super.key});

  @override
  State<MovimientoScreen> createState() => _MovimientoScreenState();
}

class _MovimientoScreenState extends State<MovimientoScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = true;
  bool _isManualToggle = false;
  bool _isAnimating = true;
  bool _isLoading = true; // Para el shimmer
  String _numeroCuenta = '000 - 000000 - 00';
  double _saldoDisponible = 0;
  Timer? _autoCollapseTimer;
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _loadNumeroCuenta();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -1.5708, end: -4.7124).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _autoCollapseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _isAnimating = true;
          _isLoading = false; // Termina el shimmer
        });
        _shimmerController.stop();
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
      }
    });
  }

  Future<void> _loadNumeroCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty && customAccount.length == 11) {
      setState(() {
        _numeroCuenta =
            '${customAccount.substring(0, 3)} - ${customAccount.substring(3, 9)} - ${customAccount.substring(9, 11)}';
      });
    }
    setState(() {
      _saldoDisponible = prefs.getDouble('saldo_reserva') ?? 0;
    });
  }

  String _formatNumber(double number) {
    if (number == 0) return '0';
    final intPart = number.toInt();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return formatted;
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_isAnimating) return;
    _autoCollapseTimer?.cancel();
    _isManualToggle = true;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.value = 0;
    } else {
      _animationController.value = 1;
    }
  }

  void _navigateToDetalles() {
    if (_isAnimating) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DetallesMovimientosScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF282827)
        : const Color(0xFFF2F2F4);
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        backgroundColor: bgColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
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
            SizedBox(height: screenH * 0.02),
            Padding(
              padding: EdgeInsets.only(left: screenW * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transacciones',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.035,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Saldos y movimientos',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.065,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenH * 0.02),
            // Tarjeta expandible
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
              child: AnimatedContainer(
                duration: Duration(milliseconds: _isManualToggle ? 200 : 200),
                curve: _isManualToggle ? Curves.easeOut : Curves.easeInOut,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF454648) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header "Cuentas"
                    GestureDetector(
                      onTap: _toggleExpanded,
                      child: AnimatedContainer(
                        duration: Duration(
                          milliseconds: _isManualToggle ? 200 : 200,
                        ),
                        curve: _isManualToggle
                            ? Curves.easeOut
                            : Curves.easeInOut,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenW * 0.04,
                          vertical: screenW * 0.035,
                        ),
                        decoration: BoxDecoration(
                          color: _isExpanded
                              ? (isDark
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFF3C3C3C))
                              : (isDark
                                    ? const Color(0xFF454648)
                                    : Colors.white),
                          borderRadius: _isExpanded
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                )
                              : BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 350),
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize: screenW * 0.045,
                                color: _isExpanded
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                              child: const Text('Cuentas'),
                            ),
                            AnimatedBuilder(
                              animation: _rotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationAnimation.value,
                                  child: Image.asset(
                                    'assets/icons/pic-chevron-right.png',
                                    width: screenW * 0.04,
                                    height: screenW * 0.04,
                                    color: _isExpanded
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Contenido expandido
                    if (_isManualToggle)
                      _isExpanded
                          ? _buildExpandedContent(isDark, screenW, screenH)
                          : const SizedBox.shrink()
                    else
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: _buildExpandedContent(
                          isDark,
                          screenW,
                          screenH,
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(bool isDark, double screenW, double screenH) {
    return Padding(
      padding: EdgeInsets.all(screenW * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuenta de Ahorros',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.045,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenW * 0.012),
                  // Número de cuenta con shimmer
                  _isLoading
                      ? _buildShimmerBox(screenW * 0.5, screenW * 0.04, isDark)
                      : Text(
                          'Ahorros $_numeroCuenta',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.04,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                  SizedBox(height: screenW * 0.03),
                  // Saldo disponible con shimmer
                  _isLoading
                      ? _buildShimmerBox(screenW * 0.3, screenW * 0.035, isDark)
                      : Text(
                          'Saldo disponible',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                  SizedBox(height: screenW * 0.01),
                  // Monto con shimmer
                  _isLoading
                      ? _buildShimmerBox(screenW * 0.4, screenW * 0.055, isDark)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$ ${_formatNumber(_saldoDisponible)},',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.055,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: screenW * 0.008),
                              child: Text(
                                '00',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.035,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: screenW * 0.02),
                child: Container(
                  width: screenW * 0.09,
                  height: screenW * 0.09,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white54 : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    size: screenW * 0.05,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenH * 0.015),
          Center(
            child: GestureDetector(
              onTap: _navigateToDetalles,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detalles y movimientos',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.04,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(width: screenW * 0.02),
                  Image.asset(
                    'assets/icons/pic-chevron-right.png',
                    width: screenW * 0.035,
                    height: screenW * 0.035,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height + 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      Colors.white70.withOpacity(0.3),
                      Colors.white70.withOpacity(0.5),
                      Colors.white70.withOpacity(0.3),
                    ]
                  : [
                      Colors.grey.shade400,
                      Colors.grey.shade300,
                      Colors.grey.shade400,
                    ],
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Pantalla de Detalles y Movimientos
class DetallesMovimientosScreen extends StatefulWidget {
  const DetallesMovimientosScreen({super.key});

  @override
  State<DetallesMovimientosScreen> createState() =>
      _DetallesMovimientosScreenState();
}

class _DetallesMovimientosScreenState extends State<DetallesMovimientosScreen> {
  String _numeroCuenta = '000 - 000000 - 00';
  double _saldoDisponible = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  List<Map<String, dynamic>> _movimientos = [];

  @override
  void initState() {
    super.initState();
    _loadDatos();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final screenH = MediaQuery.of(context).size.height;
    final expandedHeight = screenH * 0.35;
    final collapsedHeight = screenH * 0.12;

    double limitScroll;

    if (_movimientos.length < 7) {
      // Menos de 7 movimientos: limitar hasta que el header se colapse
      limitScroll = expandedHeight - collapsedHeight;
    } else {
      // 7 o más movimientos: limitar al 50% del máximo
      final maxExtent = _scrollController.position.maxScrollExtent;
      limitScroll = maxExtent * 0.5;
    }

    if (_scrollController.offset > limitScroll) {
      _scrollController.jumpTo(limitScroll);
    }

    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty && customAccount.length == 11) {
      setState(() {
        _numeroCuenta =
            '${customAccount.substring(0, 3)} - ${customAccount.substring(3, 9)} - ${customAccount.substring(9, 11)}';
      });
    }
    setState(() {
      _saldoDisponible = prefs.getDouble('saldo_reserva') ?? 0;
    });

    // Cargar movimientos
    final movimientosJson = prefs.getString('movimientos_bancolombia') ?? '[]';
    final List<dynamic> movimientosList = json.decode(movimientosJson);
    setState(() {
      _movimientos = movimientosList
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    });
  }

  String _formatNumber(double number) {
    if (number == 0) return '0';
    final intPart = number.toInt();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return formatted;
  }

  String _formatFecha(String fechaIso) {
    final fecha = DateTime.parse(fechaIso);
    final meses = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return '${fecha.day.toString().padLeft(2, '0')} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF282827)
        : const Color(0xFFF2F2F4);
    final Color headerColor = isDark ? const Color(0xFF454648) : Colors.white;
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;

    // Calcular posición del círculo
    final double expandedHeight = screenH * 0.35;
    final double collapsedHeight = screenH * 0.12;
    final double circleInitialTop =
        expandedHeight + topPadding + screenW * 0.06;
    final double circleMinTop = collapsedHeight + topPadding + screenW * 0.06;
    final double circleTop = (circleInitialTop - _scrollOffset).clamp(
      circleMinTop,
      circleInitialTop,
    );

    return SystemAwareScaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: screenH * 0.35,
                collapsedHeight: screenH * 0.12,
                pinned: true,
                backgroundColor: headerColor,
                flexibleSpace: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (_) {},
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxHeight = screenH * 0.35 + topPadding;
                      final double minHeight = screenH * 0.12;
                      final double currentHeight = constraints.maxHeight;
                      final double expandRatio =
                          ((currentHeight - minHeight) /
                                  (maxHeight - minHeight))
                              .clamp(0.0, 1.0);

                      return Container(
                        color: headerColor,
                        child: Stack(
                          children: [
                            // Header fijo (siempre visible)
                            Positioned(
                              top: topPadding * 0.3,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenW * 0.04,
                                  vertical: screenW * 0.03,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Botón Volver - icono siempre visible, texto desaparece
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Transform.rotate(
                                              angle: 3.14159,
                                              child: Image.asset(
                                                'assets/icons/pic-chevron-right.png',
                                                width: screenW * 0.045,
                                                height: screenW * 0.045,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: screenW * 0.02),
                                            // Solo el texto desaparece
                                            Opacity(
                                              opacity: expandRatio,
                                              child: Text(
                                                'Volver',
                                                style: TextStyle(
                                                  fontFamily: 'OpenSansRegular',
                                                  fontSize: screenW * 0.045,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Icono CIB (visible cuando expandido)
                                    Opacity(
                                      opacity: expandRatio,
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
                                    // Texto "Cuenta de Ahorros" (visible solo cuando colapsado)
                                    Opacity(
                                      opacity: expandRatio < 0.3
                                          ? (1 - expandRatio / 0.3)
                                          : 0,
                                      child: Text(
                                        'Cuenta de Ahorros',
                                        style: TextStyle(
                                          fontFamily: 'OpenSansRegular',
                                          fontSize: screenW * 0.045,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Contenido expandible (desaparece al colapsar)
                            Positioned(
                              top: topPadding + screenW * 0.15,
                              left: 0,
                              right: 0,
                              child: Opacity(
                                opacity: expandRatio,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: screenW * 0.04,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cuentas',
                                        style: TextStyle(
                                          fontFamily: 'OpenSansRegular',
                                          fontSize: screenW * 0.035,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Cuenta de Ahorros',
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        style: TextStyle(
                                          fontFamily: 'OpenSansBold',
                                          fontSize: screenW * 0.065,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: screenH * 0.03),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Ahorros',
                                                style: TextStyle(
                                                  fontFamily: 'OpenSansRegular',
                                                  fontSize: screenW * 0.04,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: screenW * 0.01),
                                              Text(
                                                _numeroCuenta,
                                                style: TextStyle(
                                                  fontFamily: 'OpenSansRegular',
                                                  fontSize: screenW * 0.04,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              right: screenW * 0.04,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Saldo disponible',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'OpenSansRegular',
                                                    fontSize: screenW * 0.035,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: screenW * 0.01,
                                                ),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '\$ ${_formatNumber(_saldoDisponible)},',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'OpenSansRegular',
                                                        fontSize:
                                                            screenW * 0.048,
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: screenW * 0.008,
                                                      ),
                                                      child: Text(
                                                        '00',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'OpenSansRegular',
                                                          fontSize:
                                                              screenW * 0.032,
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
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Pestañas (siempre en la parte inferior del header)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildTab('Detalles', false, screenW, isDark),
                                  SizedBox(width: screenW * 0.15),
                                  _buildTab(
                                    'Movimientos',
                                    true,
                                    screenW,
                                    isDark,
                                  ),
                                  SizedBox(width: screenW * 0.15),
                                  _buildTab('Plan', false, screenW, isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Lista de movimientos
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // Si no hay movimientos, mostrar espacios vacíos para scroll
                  if (_movimientos.isEmpty) {
                    return const SizedBox(height: 100);
                  }

                  final movimiento = _movimientos[index];
                  final valor = (movimiento['valor'] as num).toDouble();
                  final fecha = _formatFecha(movimiento['fecha']);
                  final descripcion = movimiento['descripcion'] as String;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == 0) SizedBox(height: screenW * 0.25),
                        // Fecha
                        Text(
                          fecha,
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.035,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenW * 0.01),
                        // Descripción
                        Text(
                          descripcion,
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.038,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenW * 0.02),
                        // Valor COP más abajo a la derecha
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'COP -\$ ${_formatNumber(valor)},00',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.035,
                              color: const Color(0xFFFF0000),
                            ),
                          ),
                        ),
                        SizedBox(height: screenW * 0.03),
                        // Línea divisora
                        Container(
                          height: 1,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                        SizedBox(height: screenW * 0.04),
                      ],
                    ),
                  );
                }, childCount: _movimientos.isEmpty ? 10 : _movimientos.length),
              ),
              // Espacio extra al final para colapsar completamente
              SliverToBoxAdapter(child: SizedBox(height: screenH * 0.8)),
            ],
          ),
          // Overlay que oculta los movimientos por encima de la línea (solo si hay más de 7 movimientos)
          if (_movimientos.length > 7)
            Positioned(
              top: circleTop - screenW * 0.06,
              left: 0,
              right: 0,
              height: screenW * 0.2 + 15,
              child: IgnorePointer(
                ignoring: true,
                child: Container(color: bgColor),
              ),
            ),
          // Línea debajo del círculo (ancho completo) - siempre transparente
          Positioned(
            top: circleTop + screenW * 0.15 + 8,
            left: 0,
            right: 0,
            child: Container(height: 2, color: Colors.transparent),
          ),
          // Círculo flotante (encima del overlay)
          Positioned(
            top: circleTop,
            right: screenW * 0.06,
            child: Container(
              width: screenW * 0.15,
              height: screenW * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF454648) : Colors.white,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/pic-search.svg',
                  width: screenW * 0.065,
                  height: screenW * 0.065,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          // Botones de acción en la parte inferior
          Positioned(
            bottom: screenH * 0.03,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenW * 0.04,
                vertical: screenW * 0.03,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF454648) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              margin: EdgeInsets.symmetric(horizontal: screenW * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      screenW: screenW,
                      isDark: isDark,
                      icon: 'assets/icons/pic_transfer.svg',
                      label: 'Transferir plata',
                      onTap: () {},
                      isPng: false,
                      iconWidth: screenW * 0.11,
                      iconHeight: screenW * 0.11,
                    ),
                  ),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      screenW: screenW,
                      isDark: isDark,
                      icon: 'assets/icons/pic-hand-investment.svg',
                      label: 'Ir Día a Día',
                      onTap: () {},
                      centerLabel: true,
                    ),
                  ),
                  Expanded(
                    child: _buildActionButtonIcon(
                      context: context,
                      screenW: screenW,
                      isDark: isDark,
                      iconWidget: Icon(
                        Icons.more_vert,
                        size: screenW * 0.08,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      label: 'Más',
                      onTap: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    bool isPng = false,
    bool centerLabel = false,
    double? iconWidth,
    double? iconHeight,
  }) {
    final double finalIconWidth = iconWidth ?? screenW * 0.08;
    final double finalIconHeight = iconHeight ?? screenW * 0.08;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (centerLabel) SizedBox(height: screenW * 0.015),
          Center(
            child: isPng
                ? Image.asset(
                    icon,
                    width: finalIconWidth,
                    height: finalIconHeight,
                    color: isDark ? Colors.white : Colors.black,
                  )
                : SvgPicture.asset(
                    icon,
                    width: finalIconWidth,
                    height: finalIconHeight,
                    colorFilter: ColorFilter.mode(
                      isDark ? Colors.white : Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          SizedBox(height: centerLabel ? screenW * 0.025 : screenW * 0.01),
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

  Widget _buildActionButtonIcon({
    required BuildContext context,
    required double screenW,
    required bool isDark,
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: screenW * 0.015),
          Center(child: iconWidget),
          SizedBox(height: screenW * 0.015),
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

  Widget _buildTab(String text, bool isSelected, double screenW, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: screenW * 0.03),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: isSelected ? 'OpenSansBold' : 'OpenSansRegular',
          fontSize: screenW * 0.04,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
