import 'package:flutter/material.dart';
import 'error_widgets.dart';
import '../utils/auth_error_handler.dart';

/// Pantalla de demostración de los widgets de error
/// Muestra todos los tipos de errores con animaciones
class ErrorDemoScreen extends StatelessWidget {
  const ErrorDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFf7f4f2),
      appBar: AppBar(
        title: const Text('Demo de Errores Personalizados'),
        backgroundColor: const Color(0xFF9bb168),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text(
              'Prueba los diferentes tipos de errores',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4f3422),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.05),

            // Sección: SnackBars desde arriba
            _SectionTitle(
              title: 'SnackBars (Aparecen arriba)',
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenWidth * 0.03),

            _DemoButton(
              text: 'Error: Email inválido',
              color: const Color(0xFFd32f2f),
              icon: Icons.error_outline,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: AuthErrorHandler.getFriendlyMessage('invalid-email'),
                  isError: true,
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),

            _DemoButton(
              text: 'Error: Usuario no encontrado',
              color: const Color(0xFFd32f2f),
              icon: Icons.person_off,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: AuthErrorHandler.getFriendlyMessage(
                    'user-not-found',
                  ),
                  isError: true,
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),

            _DemoButton(
              text: 'Error: Contraseña incorrecta',
              color: const Color(0xFFd32f2f),
              icon: Icons.lock_outline,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: AuthErrorHandler.getFriendlyMessage(
                    'wrong-password',
                  ),
                  isError: true,
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),

            _DemoButton(
              text: 'Éxito: Inicio de sesión',
              color: const Color(0xFF4CAF50), // Verde fuerte
              icon: Icons.check_circle_outline,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: '¡Bienvenido! Inicio de sesión exitoso 🎉',
                  isError: false,
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),

            _DemoButton(
              text: 'Mensaje largo (5 segundos)',
              color: const Color(0xFFff9800),
              icon: Icons.timer,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message:
                      'Este es un mensaje más largo que permanecerá visible durante 5 segundos',
                  isError: true,
                  duration: const Duration(seconds: 5),
                );
              },
            ),

            SizedBox(height: screenWidth * 0.08),

            // Sección: Diálogos
            _SectionTitle(title: 'Diálogos Modales', screenWidth: screenWidth),
            SizedBox(height: screenWidth * 0.03),

            _DemoButton(
              text: 'Error Dialog',
              color: const Color(0xFF9bb168),
              icon: Icons.warning_amber_rounded,
              onPressed: () {
                ErrorDialog.show(
                  context,
                  title: 'Error de autenticación',
                  message: AuthErrorHandler.getFriendlyMessage(
                    'invalid-credential',
                  ),
                  buttonText: 'Entendido',
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),

            _DemoButton(
              text: 'Error Bottom Sheet',
              color: const Color(0xFF9bb168),
              icon: Icons.arrow_upward,
              onPressed: () {
                ErrorBottomSheet.show(
                  context,
                  title: 'Error de conexión',
                  message: AuthErrorHandler.getFriendlyMessage(
                    'network-request-failed',
                  ),
                  buttonText: 'Reintentar',
                  icon: Icons.wifi_off,
                  onPressed: () {
                    ErrorSnackBar.show(
                      context,
                      message: 'Reintentando conexión...',
                      isError: false,
                    );
                  },
                );
              },
            ),

            SizedBox(height: screenWidth * 0.08),

            // Sección: Banners inline
            _SectionTitle(title: 'Banners Inline', screenWidth: screenWidth),
            SizedBox(height: screenWidth * 0.03),

            const ErrorBanner(message: 'El correo electrónico no es válido'),
            SizedBox(height: screenWidth * 0.02),

            const ErrorBanner(message: 'Las contraseñas no coinciden'),
            SizedBox(height: screenWidth * 0.02),

            ErrorBanner(
              message: 'Este banner se puede cerrar',
              onDismiss: () {
                ErrorSnackBar.show(
                  context,
                  message: 'Banner cerrado',
                  isError: false,
                );
              },
            ),

            SizedBox(height: screenWidth * 0.08),

            // Sección: Simulación de errores de Firebase
            _SectionTitle(
              title: 'Errores de Firebase',
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenWidth * 0.03),

            _DemoButton(
              text: 'Email ya registrado',
              color: const Color(0xFFe67e22),
              icon: Icons.email,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: AuthErrorHandler.getFriendlyMessage(
                    'email-already-in-use',
                  ),
                  isError: true,
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),

            _DemoButton(
              text: 'Contraseña débil',
              color: const Color(0xFFe67e22),
              icon: Icons.security,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: AuthErrorHandler.getFriendlyMessage('weak-password'),
                  isError: true,
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),

            _DemoButton(
              text: 'Demasiados intentos',
              color: const Color(0xFFe67e22),
              icon: Icons.block,
              onPressed: () {
                ErrorSnackBar.show(
                  context,
                  message: AuthErrorHandler.getFriendlyMessage(
                    'too-many-requests',
                  ),
                  isError: true,
                );
              },
            ),

            SizedBox(height: screenWidth * 0.05),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final double screenWidth;

  const _SectionTitle({required this.title, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF9bb168).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth * 0.045,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF4f3422),
        ),
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _DemoButton({
    required this.text,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: screenWidth * 0.06),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: screenWidth * 0.04,
            ),
          ],
        ),
      ),
    );
  }
}
