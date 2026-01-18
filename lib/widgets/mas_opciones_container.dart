import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MasOpcionesContainer extends StatelessWidget {
  final bool isDark;
  final double offsetY;

  const MasOpcionesContainer({
    super.key,
    required this.isDark,
    this.offsetY = 5.5,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final smallFontSize = (screenH * 0.016).clamp(12.0, 12.0);

    return SizedBox(
      height: screenH * 0.35,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
          width: screenW * 0.9,
          margin: EdgeInsets.symmetric(horizontal: screenW * 0.05),
          padding: EdgeInsets.all(screenH * 0.015),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF454648) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              // Primera fila - 3 círculos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleOption(
                    context,
                    'Organiza tu plata',
                    'assets/icons/pic_apunt.png',
                    const Color(0xFFACA0D2),
                    smallFontSize,
                    isDark,
                    isImage: true,
                  ),
                  _buildCircleOption(
                    context,
                    'Hogar y\nservicios',
                    'assets/icons/home.svg',
                    const Color(0xFF9AD1C9),
                    smallFontSize,
                    isDark,
                    isImage: false,
                  ),
                  _buildCircleOption(
                    context,
                    'Transporte',
                    'assets/icons/car.png',
                    const Color(0xFFF7E4A3),
                    smallFontSize,
                    isDark,
                    isImage: true,
                    offsetY: -7.0,
                  ),
                ],
              ),
              SizedBox(height: screenH * 0.015),
              // Segunda fila - 2 círculos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleOption(
                    context,
                    'Beneficios y\ncompras',
                    'assets/icons/pic-star.svg',
                    const Color(0xFFF1AA99),
                    smallFontSize,
                    isDark,
                    isImage: false,
                    offsetX: -1.5,
                  ),
                  _buildCircleOption(
                    context,
                    'Trámites y\nsolicitudes',
                    'assets/icons/pic-hand-holding-document.svg',
                    const Color(0xFF73CBEB),
                    smallFontSize,
                    isDark,
                    isImage: false,
                    offsetX:- 3.5,
                  ),
                  SizedBox(width: screenW * 0.15),
                ],
              ),
              SizedBox(height: screenH * 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleOption(
    BuildContext context,
    String label,
    String asset,
    Color circleColor,
    double fontSize,
    bool isDark, {
    required bool isImage,
    double offsetY = 0.0,
    double offsetX = 0.0,
  }) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Column(
        children: [
          Container(
            width: (screenH * 0.1).clamp(35.0, 50.0),
            height: (screenH * 0.1).clamp(35.0, 50.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
            ),
            child: Center(
              child: isImage
                  ? Image.asset(
                      asset,
                      width: (screenH * 0.07).clamp(40.0, 55.0),
                      height: (screenH * 0.07).clamp(40.0, 55.0),
                      fit: BoxFit.contain,
                      color: isDark ? Colors.black : Colors.black,
                    )
                  : SvgPicture.asset(
                      asset,
                      width: (screenH * 0.05).clamp(20.0, 30.0),
                      height: (screenH * 0.05).clamp(20.0, 30.0),
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.black : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
            ),
          ),
          SizedBox(height: (screenH * 0.001).clamp(0.5, 2.0)),
          SizedBox(
            width: screenW * 0.18,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'RegularCustom',
                fontSize: fontSize,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
