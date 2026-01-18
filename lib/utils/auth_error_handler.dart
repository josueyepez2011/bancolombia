/// Clase utilitaria para traducir códigos de error de Firebase/Firestore a mensajes amigables en español
class AuthErrorHandler {
  /// Mapa de códigos de error de Firebase a mensajes en español
  static const Map<String, String> _errorMessages = {
    // Errores de Email/Contraseña
    'invalid-email': 'El correo electrónico no es válido',
    'user-disabled': 'Esta cuenta ha sido deshabilitada',
    'user-not-found': 'No existe una cuenta con este correo',
    'wrong-password': 'Contraseña incorrecta',
    'email-already-in-use': 'Este correo ya está registrado',
    'weak-password': 'La contraseña es muy débil. Debe tener al menos 6 caracteres',
    'operation-not-allowed': 'Esta operación no está permitida',
    'invalid-credential': 'Las credenciales no son válidas',
    
    // Errores de Red
    'network-request-failed': 'Error de conexión. Verifica tu internet',
    'too-many-requests': 'Demasiados intentos. Intenta más tarde',
    'timeout': 'La operación tardó demasiado. Intenta de nuevo',
    'unavailable': 'El servicio no está disponible. Intenta más tarde',
    
    // Errores de Google Sign In
    'account-exists-with-different-credential': 
        'Ya existe una cuenta con este correo usando otro método',
    'popup-closed-by-user': 'Inicio de sesión cancelado',
    'popup-blocked': 'El navegador bloqueó la ventana emergente',
    'cancelled-popup-request': 'Inicio de sesión cancelado',
    
    // Errores de Verificación
    'requires-recent-login': 'Por seguridad, debes iniciar sesión nuevamente',
    'expired-action-code': 'El código ha expirado',
    'invalid-action-code': 'El código no es válido',
    
    // Errores Generales
    'internal-error': 'Error interno del servidor. Intenta más tarde',
    'invalid-api-key': 'Error de configuración. Contacta a soporte',
    'app-deleted': 'La aplicación ha sido eliminada',
    'invalid-user-token': 'Tu sesión ha expirado. Inicia sesión nuevamente',
    'user-token-expired': 'Tu sesión ha expirado. Inicia sesión nuevamente',
    
    // Errores de Firestore
    'permission-denied': 'No tienes permisos para realizar esta acción',
    'not-found': 'No se encontró el recurso solicitado',
  };

  /// Obtiene un mensaje amigable a partir de una excepción
  static String getFriendlyMessage(dynamic error) {
    // Si es un String, intentar extraer el código de error
    if (error is String) {
      final code = _extractErrorCode(error);
      if (code != null && _errorMessages.containsKey(code)) {
        return _errorMessages[code]!;
      }
      return error;
    }
    
    // Si es una excepción, intentar obtener el mensaje
    if (error is Exception) {
      final errorString = error.toString();
      final code = _extractErrorCode(errorString);
      if (code != null && _errorMessages.containsKey(code)) {
        return _errorMessages[code]!;
      }
      
      // Buscar palabras clave comunes en el mensaje de error
      if (errorString.contains('network') || errorString.contains('connection')) {
        return _errorMessages['network-request-failed']!;
      }
      if (errorString.contains('timeout')) {
        return _errorMessages['timeout']!;
      }
      if (errorString.contains('permission')) {
        return _errorMessages['permission-denied']!;
      }
      
      return 'Ocurrió un error inesperado. Intenta de nuevo';
    }
    
    // Error genérico
    return 'Ocurrió un error inesperado. Intenta de nuevo';
  }

  /// Extrae el código de error de un mensaje de error
  static String? _extractErrorCode(String errorMessage) {
    // Buscar patrones comunes de códigos de error
    final patterns = [
      RegExp(r'\[([a-z-]+)\]'),
      RegExp(r'code: ([a-z-]+)'),
      RegExp(r'"code":"([a-z-]+)"'),
      RegExp(r'error/([a-z-]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(errorMessage);
      if (match != null && match.groupCount > 0) {
        return match.group(1);
      }
    }
    
    return null;
  }

  /// Verifica si un error es de tipo red/conexión
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unavailable') ||
        errorString.contains('timeout');
  }

  /// Verifica si un error requiere reautenticación
  static bool requiresReauth(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('requires-recent-login') ||
        errorString.contains('token-expired') ||
        errorString.contains('invalid-user-token');
  }
}
