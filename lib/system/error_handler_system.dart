import 'package:flutter/material.dart';
import '../widgets/error_widgets.dart';

/// Sistema activo de manejo de errores para todas las pantallas
/// 
/// Este sistema proporciona un wrapper que inyecta automáticamente
/// la UI de errores y advertencias a cualquier pantalla.
/// 
/// USO:
/// ```dart
/// // Envuelve tu pantalla con ErrorHandlerScreen
/// return ErrorHandlerScreen(
///   child: MiPantalla(),
/// );
/// ```

class ErrorHandlerSystem {
  /// Instancia singleton del gestor de errores
  static final ErrorHandlerSystem _instance = ErrorHandlerSystem._internal();

  factory ErrorHandlerSystem() {
    return _instance;
  }

  ErrorHandlerSystem._internal();

  /// Cola de errores pendientes
  final List<ErrorMessage> _errorQueue = [];

  /// Controlador de estado para notificar cambios
  final ValueNotifier<List<ErrorMessage>> _errorNotifier =
      ValueNotifier<List<ErrorMessage>>([]);

  /// Obtener el notificador de errores
  ValueNotifier<List<ErrorMessage>> get errorNotifier => _errorNotifier;

  /// Obtener la lista actual de errores
  List<ErrorMessage> get errors => _errorNotifier.value;

  /// Agregar un error a la cola
  void addError({
    required String message,
    String title = 'Error',
    ErrorType type = ErrorType.error,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    final error = ErrorMessage(
      message: message,
      title: title,
      type: type,
      duration: duration,
      onRetry: onRetry,
      timestamp: DateTime.now(),
    );

    _errorQueue.add(error);
    _updateErrorNotifier();

    // Auto-remover después de la duración
    Future.delayed(duration, () {
      removeError(error);
    });
  }

  /// Agregar una advertencia
  void addWarning({
    required String message,
    String title = 'Advertencia',
    Duration duration = const Duration(seconds: 3),
  }) {
    addError(
      message: message,
      title: title,
      type: ErrorType.warning,
      duration: duration,
    );
  }

  /// Agregar un mensaje de éxito
  void addSuccess({
    required String message,
    String title = 'Éxito',
    Duration duration = const Duration(seconds: 2),
  }) {
    addError(
      message: message,
      title: title,
      type: ErrorType.success,
      duration: duration,
    );
  }

  /// Remover un error específico
  void removeError(ErrorMessage error) {
    _errorQueue.remove(error);
    _updateErrorNotifier();
  }

  /// Limpiar todos los errores
  void clearAll() {
    _errorQueue.clear();
    _updateErrorNotifier();
  }

  /// Actualizar el notificador
  void _updateErrorNotifier() {
    _errorNotifier.value = List.from(_errorQueue);
  }

  /// Mostrar error con contexto (método auxiliar)
  static void showError(
    BuildContext context, {
    required String message,
    String title = 'Error',
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    ErrorHandlerSystem().addError(
      message: message,
      title: title,
      type: ErrorType.error,
      duration: duration,
      onRetry: onRetry,
    );
  }

  /// Mostrar advertencia con contexto
  static void showWarning(
    BuildContext context, {
    required String message,
    String title = 'Advertencia',
    Duration duration = const Duration(seconds: 3),
  }) {
    ErrorHandlerSystem().addWarning(
      message: message,
      title: title,
      duration: duration,
    );
  }

  /// Mostrar éxito con contexto
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Éxito',
    Duration duration = const Duration(seconds: 2),
  }) {
    ErrorHandlerSystem().addSuccess(
      message: message,
      title: title,
      duration: duration,
    );
  }
}

/// Tipos de errores/mensajes
enum ErrorType {
  error,
  warning,
  success,
}

/// Modelo de mensaje de error
class ErrorMessage {
  final String message;
  final String title;
  final ErrorType type;
  final Duration duration;
  final VoidCallback? onRetry;
  final DateTime timestamp;

  ErrorMessage({
    required this.message,
    required this.title,
    required this.type,
    required this.duration,
    this.onRetry,
    required this.timestamp,
  });
}

/// Widget wrapper que inyecta el sistema de errores a una pantalla
class ErrorHandlerScreen extends StatefulWidget {
  final Widget child;
  final bool showErrorBanner;
  final bool showErrorSnackBar;
  final bool showErrorDialog;

  const ErrorHandlerScreen({
    super.key,
    required this.child,
    this.showErrorBanner = true,
    this.showErrorSnackBar = true,
    this.showErrorDialog = false,
  });

  @override
  State<ErrorHandlerScreen> createState() => _ErrorHandlerScreenState();
}

class _ErrorHandlerScreenState extends State<ErrorHandlerScreen> {
  late ErrorHandlerSystem _errorSystem;

  @override
  void initState() {
    super.initState();
    _errorSystem = ErrorHandlerSystem();
    _errorSystem.errorNotifier.addListener(_onErrorsChanged);
  }

  @override
  void dispose() {
    _errorSystem.errorNotifier.removeListener(_onErrorsChanged);
    super.dispose();
  }

  void _onErrorsChanged() {
    if (mounted && _errorSystem.errors.isNotEmpty) {
      final error = _errorSystem.errors.last;

      // Mostrar SnackBar si está habilitado
      if (widget.showErrorSnackBar) {
        ErrorSnackBar.show(
          context,
          message: error.message,
          isError: error.type == ErrorType.error,
          duration: error.duration,
        );
      }

      // Mostrar Dialog si está habilitado y es error crítico
      if (widget.showErrorDialog && error.type == ErrorType.error) {
        ErrorDialog.show(
          context,
          title: error.title,
          message: error.message,
          buttonText: error.onRetry != null ? 'Reintentar' : 'Entendido',
          onPressed: error.onRetry,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Mostrar banners de error inline si está habilitado
        if (widget.showErrorBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<List<ErrorMessage>>(
              valueListenable: _errorSystem.errorNotifier,
              builder: (context, errors, _) {
                if (errors.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Mostrar solo los primeros 2 errores
                final visibleErrors = errors.take(2).toList();

                return Column(
                  children: visibleErrors.map((error) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ErrorBanner(
                        message: error.message,
                        icon: _getIconForType(error.type),
                        backgroundColor: _getBackgroundColorForType(error.type),
                        textColor: _getTextColorForType(error.type),
                        iconColor: _getIconColorForType(error.type),
                        onDismiss: () {
                          _errorSystem.removeError(error);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getIconForType(ErrorType type) {
    switch (type) {
      case ErrorType.error:
        return Icons.error_outline;
      case ErrorType.warning:
        return Icons.warning_rounded;
      case ErrorType.success:
        return Icons.check_circle_outline;
    }
  }

  Color _getBackgroundColorForType(ErrorType type) {
    switch (type) {
      case ErrorType.error:
        return const Color(0xFFffebee);
      case ErrorType.warning:
        return const Color(0xFFFFF3E0);
      case ErrorType.success:
        return const Color(0xFFE8F5E9);
    }
  }

  Color _getTextColorForType(ErrorType type) {
    switch (type) {
      case ErrorType.error:
        return const Color(0xFFc62828);
      case ErrorType.warning:
        return const Color(0xFF4f3422);
      case ErrorType.success:
        return const Color(0xFF1b5e20);
    }
  }

  Color _getIconColorForType(ErrorType type) {
    switch (type) {
      case ErrorType.error:
        return const Color(0xFFd32f2f);
      case ErrorType.warning:
        return const Color(0xFFe67e22);
      case ErrorType.success:
        return const Color(0xFF4CAF50);
    }
  }
}

/// Extensión para acceder fácilmente al sistema de errores desde BuildContext
extension ErrorHandlerContextExtension on BuildContext {
  /// Mostrar error
  void showError({
    required String message,
    String title = 'Error',
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    ErrorHandlerSystem.showError(
      this,
      message: message,
      title: title,
      duration: duration,
      onRetry: onRetry,
    );
  }

  /// Mostrar advertencia
  void showWarning({
    required String message,
    String title = 'Advertencia',
    Duration duration = const Duration(seconds: 3),
  }) {
    ErrorHandlerSystem.showWarning(
      this,
      message: message,
      title: title,
      duration: duration,
    );
  }

  /// Mostrar éxito
  void showSuccess({
    required String message,
    String title = 'Éxito',
    Duration duration = const Duration(seconds: 2),
  }) {
    ErrorHandlerSystem.showSuccess(
      this,
      message: message,
      title: title,
      duration: duration,
    );
  }
}
