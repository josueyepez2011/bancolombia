import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens_transferencia.dart';
import 'home.dart';
import 'ajuste.dart';
import 'select_qr.dart';
import '../system/index.dart';

class TransferirPlataScreen extends StatelessWidget {
  const TransferirPlataScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        backgroundColor: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF2F2F4),
        body: Column(
        children: [
          // Header con Volver, logo y Ayuda
          _buildHeader(context, screenW, screenH, isDark),
          SizedBox(height: screenH * 0.02),
          // Título "Transacciones" y "Transferir plata"
          _buildTitle(screenW, isDark),
          SizedBox(height: screenH * 0.03),
          // Lista de opciones
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
              child: Column(
                children: [
                  // 1. Transferir plata
                  _buildOptionTile(
                    context: context,
                    screenW: screenW,
                    screenH: screenH,
                    isDark: isDark,
                    iconWidget: SvgPicture.asset(
                      'assets/icons/pic-send-money-from.svg',
                      width: screenW * 0.07,
                      height: screenW * 0.07,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Transferir plata',
                    subtitle: null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductoOrigenScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenH * 0.015),
                  // 2. Transferir con llaves
                  _buildOptionTile(
                    context: context,
                    screenW: screenW,
                    screenH: screenH,
                    isDark: isDark,
                    iconWidget: SvgPicture.asset(
                      'assets/icons/pic-key.svg',
                      width: screenW * 0.07,
                      height: screenW * 0.07,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Transferir con llaves',
                    subtitle: 'Con Bre-B, gratis y de una',
                    onTap: () {},
                  ),
                  SizedBox(height: screenH * 0.015),
                  // 3. Transferir con código QR
                  _buildOptionTile(
                    context: context,
                    screenW: screenW,
                    screenH: screenH,
                    isDark: isDark,
                    iconWidget: SvgPicture.asset(
                      'assets/icons/pic-qr-scan.svg',
                      width: screenW * 0.07,
                      height: screenW * 0.07,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Transferir con código QR',
                    subtitle: null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectQrScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenH * 0.015),
                  // 4. Enviar regalo
                  _buildOptionTile(
                    context: context,
                    screenW: screenW,
                    screenH: screenH,
                    isDark: isDark,
                    iconWidget: SvgPicture.asset(
                      'assets/icons/pic-hand-holding-box.svg',
                      width: screenW * 0.07,
                      height: screenW * 0.07,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Enviar regalo',
                    subtitle: null,
                    onTap: () {},
                  ),
                  SizedBox(height: screenH * 0.015),
                  // 5. A otro banco con Transfiya
                  _buildOptionTile(
                    context: context,
                    screenW: screenW,
                    screenH: screenH,
                    isDark: isDark,
                    iconWidget: SvgPicture.asset(
                      'assets/icons/pic-send-money.svg',
                      width: screenW * 0.07,
                      height: screenW * 0.07,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'A otro banco con Transfiya',
                    subtitle: null,
                    onTap: () {},
                  ),
                  SizedBox(height: screenH * 0.015),
                  // 6. Inscribir productos
                  _buildOptionTile(
                    context: context,
                    screenW: screenW,
                    screenH: screenH,
                    isDark: isDark,
                    iconWidget: SvgPicture.asset(
                      'assets/icons/pic-file-add.svg',
                      width: screenW * 0.07,
                      height: screenW * 0.07,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Inscribir productos',
                    subtitle: null,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          // Trazo decorativo
          _buildBottomDecoration(screenW, screenH),
          // Barra de navegación inferior
          _buildBottomNavBar(context, screenW, isDark),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenW * 0.04,
        vertical: screenH * 0.01,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Volver
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
          // Logo CIB
          Padding(
            padding: EdgeInsets.only(right: screenW * 0.05),
            child: SvgPicture.asset(
              'assets/icons/CIB.svg',
              width: screenW * 0.08,
              height: screenW * 0.08,
              colorFilter: isDark
                  ? const ColorFilter.mode(Color(0xFFF2F2F4), BlendMode.srcIn)
                  : null,
            ),
          ),
          // Ayuda
          Row(
            children: [
              Text(
                'Ayuda',
                style: TextStyle(
                  fontFamily: 'OpenSansRegular',
                  fontSize: screenW * 0.04,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(width: screenW * 0.01),
              Container(
                width: screenW * 0.06,
                height: screenW * 0.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white : Colors.black,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: screenW * 0.035,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(double screenW, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transacciones',
            style: TextStyle(
              fontFamily: 'OpenSansRegular',
              fontSize: screenW * 0.035,
              color: isDark ? Colors.grey : Colors.grey[600],
            ),
          ),
          SizedBox(height: screenW * 0.01),
          Text(
            'Transferir plata',
            style: TextStyle(
              fontFamily: 'OpenSansBold',
              fontSize: screenW * 0.065,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required double screenW,
    required double screenH,
    required bool isDark,
    required Widget iconWidget,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
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
            // Icono
            SizedBox(
              width: screenW * 0.1,
              child: Center(child: iconWidget),
            ),
            SizedBox(width: screenW * 0.03),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: screenW * 0.04,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: screenH * 0.005),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'OpenSansRegular',
                        fontSize: screenW * 0.03,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Flecha
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

  Widget _buildBottomDecoration(double screenW, double screenH) {
    return SizedBox(
      height: screenH * 0.12,
      width: double.infinity,
      child: SvgPicture.asset(
        'assets/trazos/trazo_transfer.svg',
        width: screenW,
        fit: BoxFit.cover,
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const HomeScreen()),
              );
            },
          ),
          _buildNavItem(
            icon: 'assets/icons/pic-cards.svg',
            label: 'Transacciones',
            isDark: isDark,
            screenW: screenW,
            isSelected: true,
            onTap: () {},
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
        ? Colors.black
        : (isDark ? Colors.white : Colors.black);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(0),
              )
            : null,
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
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
