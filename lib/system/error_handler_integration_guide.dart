import 'package:flutter/material.dart';
import 'error_handler_system.dart';

/// Guía de integración del ErrorHandlerSystem a todas las pantallas
/// 
/// Este archivo muestra cómo integrar el sistema de errores a las pantallas
/// existentes en la carpeta lib/screen/

/// PASO 1: Importar el sistema en cada pantalla
/// ```dart
/// import '../system/index.dart';
/// ```

/// PASO 2: Envolver la pantalla con ErrorHandlerScreen
/// 
/// ANTES:
/// ```dart
/// class MiPantalla extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Mi Pantalla')),
///       body: MiContenido(),
///     );
///   }
/// }
/// ```
///
/// DESPUÉS:
/// ```dart
/// class MiPantalla extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ErrorHandlerScreen(
///       child: Scaffold(
///         appBar: AppBar(title: Text('Mi Pantalla')),
///         body: MiContenido(),
///       ),
///     );
///   }
/// }
/// ```

/// PASO 3: Usar la extensión de contexto para mostrar errores
/// 
/// ```dart
/// Future<void> _loadData() async {
///   try {
///     // Tu código aquí
///   } catch (e) {
///     if (mounted) {
///       context.showError(
///         message: 'Error al cargar datos: $e',
///         title: 'Error de carga',
///       );
///     }
///   }
/// }
/// ```

/// Ejemplo 1: Pantalla simple con ErrorHandlerScreen
class SimpleScreenExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pantalla Simple')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              context.showError(
                message: 'Este es un error de ejemplo',
                title: 'Error',
              );
            },
            child: const Text('Mostrar Error'),
          ),
        ),
      ),
    );
  }
}

/// Ejemplo 2: Pantalla con carga de datos
class DataLoadingScreenExample extends StatefulWidget {
  @override
  State<DataLoadingScreenExample> createState() =>
      _DataLoadingScreenExampleState();
}

class _DataLoadingScreenExampleState extends State<DataLoadingScreenExample> {
  bool _isLoading = false;
  List<String> _data = [];

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Simular carga de datos
      await Future.delayed(const Duration(seconds: 2));

      // Simular error aleatorio
      if (DateTime.now().millisecond % 2 == 0) {
        throw Exception('Error simulado al cargar datos');
      }

      setState(() {
        _data = ['Item 1', 'Item 2', 'Item 3'];
      });

      if (mounted) {
        context.showSuccess(
          message: 'Datos cargados correctamente',
          title: 'Éxito',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          message: 'No se pudieron cargar los datos: $e',
          title: 'Error de carga',
          onRetry: _loadData,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Carga de Datos')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _data.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_data[index]),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadData,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

/// Ejemplo 3: Pantalla con formulario y validación
class FormScreenExample extends StatefulWidget {
  @override
  State<FormScreenExample> createState() => _FormScreenExampleState();
}

class _FormScreenExampleState extends State<FormScreenExample> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      context.showWarning(
        message: 'Por favor completa todos los campos',
        title: 'Validación',
      );
      return;
    }

    try {
      // Simular envío de formulario
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        context.showSuccess(
          message: 'Formulario enviado correctamente',
          title: 'Éxito',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          message: 'Error al enviar el formulario: $e',
          title: 'Error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Formulario')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'El email es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'La contraseña es requerida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

/// Ejemplo 4: Pantalla con múltiples operaciones
class MultiOperationScreenExample extends StatefulWidget {
  @override
  State<MultiOperationScreenExample> createState() =>
      _MultiOperationScreenExampleState();
}

class _MultiOperationScreenExampleState
    extends State<MultiOperationScreenExample> {
  Future<void> _performOperation(String operationName) async {
    try {
      // Simular operación
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        context.showSuccess(
          message: '$operationName completada',
          title: 'Éxito',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          message: 'Error en $operationName: $e',
          title: 'Error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlerScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Múltiples Operaciones')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _performOperation('Operación 1'),
                child: const Text('Operación 1'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _performOperation('Operación 2'),
                child: const Text('Operación 2'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _performOperation('Operación 3'),
                child: const Text('Operación 3'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.showWarning(
                    message: 'Esta es una advertencia',
                    title: 'Advertencia',
                  );
                },
                child: const Text('Mostrar Advertencia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Checklist de integración para todas las pantallas
/// 
/// Para cada pantalla en lib/screen/:
/// 
/// ✅ 1. Importar el sistema:
///    import '../system/index.dart';
/// 
/// ✅ 2. Envolver con ErrorHandlerScreen:
///    return ErrorHandlerScreen(
///      child: Scaffold(...),
///    );
/// 
/// ✅ 3. Reemplazar ErrorSnackBar.show() con context.showError():
///    // Antes:
///    ErrorSnackBar.show(context, message: 'Error', isError: true);
///    
///    // Después:
///    context.showError(message: 'Error');
/// 
/// ✅ 4. Usar context.showSuccess() para mensajes de éxito:
///    context.showSuccess(message: 'Operación exitosa');
/// 
/// ✅ 5. Usar context.showWarning() para advertencias:
///    context.showWarning(message: 'Advertencia importante');
/// 
/// ✅ 6. Proporcionar onRetry para errores de red:
///    context.showError(
///      message: 'Error de conexión',
///      onRetry: () => _loadData(),
///    );

/// Pantallas a actualizar (checklist):
/// 
/// - [ ] lib/screen/home.dart
/// - [ ] lib/screen/login.dart
/// - [ ] lib/screen/register.dart
/// - [ ] lib/screen/profile.dart
/// - [ ] lib/screen/settings.dart
/// - [ ] lib/screen/transacciones.dart
/// - [ ] lib/screen/transferir_plata_screen.dart
/// - [ ] lib/screen/movimiento_screen.dart
/// - [ ] lib/screen/select_qr.dart
/// - [ ] lib/screen/ajuste.dart
/// - [ ] [Agregar más pantallas según sea necesario]
