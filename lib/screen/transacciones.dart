import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'ajuste.dart';
import 'home.dart';
import 'movimiento_screen.dart';
import 'transferir_plata_screen.dart';
import '../system/index.dart';

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({super.key});

  @override
  State<TransaccionesScreen> createState() => _TransaccionesScreenState();
}

class _TransaccionesScreenState extends State<TransaccionesScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF282827)
        : const Color(0xFFF2F2F4);

    return ErrorHandlerScreen(
      child: Scaffold(
        backgroundColor: bgColor,
        body: FullScreenSystemAware(
          respectStatusBar: false,
          respectNavigationBar: false,
          child: Stack(
          children: [
            // Trazo SVG - posición relativa
            Positioned(
              left: MediaQuery.of(context).size.width * -0.57,
              top: MediaQuery.of(context).size.height * -0.08,
              child: SvgPicture.asset(
                'assets/trazos/trazo_2.svg',
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.height * 0.2,
              ),
            ),
            // Contenido principal de transacciones
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono CIB centrado arriba + texto Transacciones
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/CIB.svg',
                              width: MediaQuery.of(context).size.width * 0.08,
                              height: MediaQuery.of(context).size.width * 0.08,
                              colorFilter: isDark
                                  ? const ColorFilter.mode(
                                      Color(0xFFF2F2F4),
                                      BlendMode.srcIn,
                                    )
                                  : null,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.1,
                            ),
                            Text(
                              'Transacciones',
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.065,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Grid de 12 círculos (4 filas x 3 columnas) con iconos
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Builder(
                        builder: (context) {
                          final double circleSize =
                              MediaQuery.of(context).size.width * 0.18;
                          final double iconSize = circleSize * 0.5;
                          final Color iconColor = isDark
                              ? Colors.white
                              : Colors.black;

                          // Lista de iconos en orden con etiquetas
                          final List<Map<String, dynamic>> iconData = [
                            {
                              'path': 'assets/icons/pic-file-add.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Ver saldos y\nmovimientos',
                            },
                            {
                              'path': 'assets/icons/bre-b-green.svg',
                              'isPng': false,
                              'scale': 0.35,
                              'label': 'Tus llaves',
                            },
                            {
                              'path': 'assets/icons/pic_transfer.svg',
                              'isPng': false,
                              'scale': 1.3,
                              'label': 'Transferir\nplata',
                            },
                            {
                              'path': 'assets/icons/pic-hand-holding-box.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Enviar regalo',
                            },
                            {
                              'path': 'assets/icons/pic-send-money.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'A otro banco\ncon Transfiya',
                            },
                            {
                              'path': 'assets/icons/pic-file-add.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Inscribir\nproductos',
                            },
                            {
                              'path': 'assets/icons/pic-send-money-from.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Recibir plata',
                            },
                            {
                              'path': 'assets/icons/pic-invoice.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Pagar facturas',
                            },
                            {
                              'path': 'assets/icons/pic-cards.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Pagar tarjetas\ny créditos',
                            },
                            {
                              'path': 'assets/icons/pic-hand-holding-cash.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Recargar',
                            },
                            {
                              'path': 'assets/icons/pic-withdraw-cash.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Avances y\ndesembolsos',
                            },
                            {
                              'path': 'assets/icons/pic-cards.svg',
                              'isPng': false,
                              'scale': 1.0,
                              'label': 'Agregar\ntarjetas',
                              'hasNew': true,
                            },
                          ];

                          return Column(
                            children: List.generate(4, (row) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(3, (col) {
                                    final int index = row * 3 + col;
                                    final icon = iconData[index];
                                    final double currentIconSize =
                                        iconSize * (icon['scale'] as double);
                                    return GestureDetector(
                                      onTap: () {
                                        if (index == 0) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const MovimientoScreen(),
                                            ),
                                          );
                                        }
                                        if (index == 2) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const TransferirPlataScreen(),
                                            ),
                                          );
                                        }
                                      },
                                      child: SizedBox(
                                        width: circleSize + 10,
                                        child: Column(
                                          children: [
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Container(
                                                  width: circleSize,
                                                  height: circleSize,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF5A5A5C,
                                                          )
                                                        : const Color(
                                                            0xFFE0E0E0,
                                                          ),
                                                  ),
                                                  child: Center(
                                                    child: icon['isPng']
                                                        ? Image.asset(
                                                            icon['path'],
                                                            width:
                                                                currentIconSize,
                                                            height:
                                                                currentIconSize,
                                                            color: iconColor,
                                                          )
                                                        : SvgPicture.asset(
                                                            icon['path'],
                                                            width:
                                                                currentIconSize,
                                                            height:
                                                                currentIconSize,
                                                            colorFilter:
                                                                ColorFilter.mode(
                                                                  iconColor,
                                                                  BlendMode
                                                                      .srcIn,
                                                                ),
                                                          ),
                                                  ),
                                                ),
                                                if (icon['hasNew'] == true)
                                                  Positioned(
                                                    top: 5,
                                                    right: 5,
                                                    child: Container(
                                                      width: circleSize * 0.15,
                                                      height: circleSize * 0.15,
                                                      decoration:
                                                          const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                              0xFF00A86B,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            SizedBox(
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.008,
                                            ),
                                            SizedBox(
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  (icon['hasNew'] == true
                                                      ? 0.065
                                                      : 0.05),
                                              child: icon['hasNew'] == true
                                                  ? Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          icon['label']
                                                              as String,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'RegularCustom',
                                                            fontSize:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width *
                                                                0.032,
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors.black,
                                                          ),
                                                        ),
                                                        Text(
                                                          '¡Nuevo!',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'RegularCustom',
                                                            fontSize:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width *
                                                                0.032,
                                                            color: const Color(
                                                              0xFF00A86B,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      icon['label'] as String,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'RegularCustom',
                                                        fontSize:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.032,
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),

                    // Aquí puedes agregar más contenido de transacciones
                  ],
                ),
              ),
            ),
            // Barra de navegación inferior
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              child: _TransaccionesNavBar(
                height: 80.0,
                color: isDark
                    ? const Color(0xFF282827)
                    : const Color(0xFFFFFFFF),
                borderRadius: 0.0,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// Barra de navegación para Transacciones (índice 1 seleccionado)
class _TransaccionesNavBar extends StatelessWidget {
  final double height;
  final Color color;
  final double borderRadius;
  final bool isDark;

  const _TransaccionesNavBar({
    this.height = 80.0,
    this.color = const Color(0xFFFFFFFF),
    this.borderRadius = 0.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDark ? Colors.white : Colors.black;
    const int selectedIndex = 1; // Transacciones seleccionado

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

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(icons.length, (index) {
          final bool isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                // Navegar a Home si se toca el índice 0
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
                // Ya estamos en Transacciones (índice 1), no hacer nada
                // Navegar a Ajustes si se toca el índice 4
                if (index == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AjusteScreen(),
                    ),
                  );
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
    );
  }
}
