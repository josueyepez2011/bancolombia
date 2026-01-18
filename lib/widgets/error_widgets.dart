import 'package:flutter/material.dart';

/// Widget personalizado para mostrar errores en forma de banner inline
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon = Icons.warning_rounded,
    this.backgroundColor = const Color(0xFFfff3e0),
    this.textColor = const Color(0xFF4f3422),
    this.iconColor = const Color(0xFFe67e22),
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(top: screenHeight * 0.008),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.012,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: iconColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: screenWidth * 0.05,
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: iconColor,
                size: screenWidth * 0.045,
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget personalizado para mostrar diálogos de error
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de error
            Container(
              width: screenWidth * 0.15,
              height: screenWidth * 0.15,
              decoration: BoxDecoration(
                color: const Color(0xFFd32f2f).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: const Color(0xFFd32f2f), // Rojo en ambos modos
                size: screenWidth * 0.1,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            // Título
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFd32f2f), // Rojo en ambos modos
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            // Mensaje
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF808080),
              ),
            ),
            SizedBox(height: screenWidth * 0.05),
            // Botón
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onPressed?.call();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // Verde fuerte
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

/// Widget personalizado para mostrar SnackBars de error con animación desde arriba
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool isError = true,
  }) {
    final overlay = Overlay.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedErrorSnackBar(
        message: message,
        isError: isError,
        duration: duration,
        screenWidth: screenWidth,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );
    
    overlay.insert(overlayEntry);
  }
}

class _AnimatedErrorSnackBar extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final double screenWidth;
  final VoidCallback onDismiss;

  const _AnimatedErrorSnackBar({
    required this.message,
    required this.isError,
    required this.duration,
    required this.screenWidth,
    required this.onDismiss,
  });

  @override
  State<_AnimatedErrorSnackBar> createState() => _AnimatedErrorSnackBarState();
}

class _AnimatedErrorSnackBarState extends State<_AnimatedErrorSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Auto-dismiss después de la duración especificada
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(widget.screenWidth * 0.04),
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.screenWidth * 0.04,
                    vertical: widget.screenWidth * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isError
                        ? const Color(0xFFd32f2f)
                        : const Color(0xFF4CAF50), // Verde fuerte
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: Colors.white,
                        size: widget.screenWidth * 0.06,
                      ),
                      SizedBox(width: widget.screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: widget.screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: widget.screenWidth * 0.02),
                      Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.8),
                        size: widget.screenWidth * 0.05,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget personalizado para mostrar un bottom sheet de error
class ErrorBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  final IconData icon;

  const ErrorBottomSheet({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.buttonText = 'Try Again',
    this.onPressed,
    this.icon = Icons.error_outline,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Something went wrong',
    required String message,
    String buttonText = 'Try Again',
    VoidCallback? onPressed,
    IconData icon = Icons.error_outline,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => ErrorBottomSheet(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior
          Container(
            width: screenWidth * 0.12,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF48484A) : const Color(0xFFe0e0e0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          // Icono
          Container(
            width: screenWidth * 0.2,
            height: screenWidth * 0.2,
            decoration: BoxDecoration(
              color: const Color(0xFFd32f2f).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFd32f2f), // Rojo en ambos modos
              size: screenWidth * 0.12,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // Título
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFd32f2f), // Rojo en ambos modos
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          // Mensaje
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF808080),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          // Botón
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onPressed?.call();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }
}
