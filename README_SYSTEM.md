# Configuración del Sistema Android

Este archivo documenta cómo usar la configuración del sistema Android implementada en `system.dart`.

## Características Implementadas

### 1. Barra de Estado (Superior)
- ✅ Color de fondo: `#282827`
- ✅ Íconos del sistema en color blanco/claro
- ✅ Configuración persistente en toda la app

### 2. Barra de Navegación (Inferior)
- ✅ Color de fondo: `#282827`
- ✅ Íconos nativos de Android en color blanco
- ✅ Funciona con navegación por botones y gestos
- ✅ Usa íconos del sistema (no personalizados)

### 3. Áreas Seguras
- ✅ El contenido respeta la barra de estado
- ✅ El contenido respeta la barra de navegación
- ✅ Manejo automático de márgenes del sistema

## Cómo Usar

### 1. Configuración Inicial
En tu `main.dart`, asegúrate de llamar la configuración al inicio:

```dart
void main() {
  AndroidSystemConfig.configureSystemBars();
  runApp(const MainApp());
}
```

### 2. Para Pantallas Normales
Usa `SystemAwareScaffold` en lugar de `Scaffold`:

```dart
class MiPantalla extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SystemAwareScaffold(
      appBar: AppBar(title: Text('Mi Pantalla')),
      body: Column(
        children: [
          // Tu contenido aquí
          // Automáticamente respeta las barras del sistema
        ],
      ),
    );
  }
}
```

### 3. Para Contenido Fullscreen
Usa `FullScreenSystemAware` cuando necesites contenido de pantalla completa:

```dart
class PantallaCompleta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FullScreenSystemAware(
        child: Container(
          // Tu contenido fullscreen aquí
          // Respeta automáticamente las áreas del sistema
        ),
      ),
    );
  }
}
```

### 4. Información del Sistema
Puedes obtener información de las barras del sistema usando las extensiones:

```dart
// Altura de la barra de estado
double statusHeight = context.statusBarHeight;

// Altura de la barra de navegación
double navHeight = context.navigationBarHeight;

// Padding completo del sistema
EdgeInsets systemPadding = context.systemPadding;
```

## Widgets Disponibles

### `AndroidSystemConfig`
- Clase principal con la configuración del sistema
- `configureSystemBars()`: Configura las barras al inicio
- `wrapWithSystemConfig()`: Wrapper para aplicar configuración

### `SystemAwareScaffold`
- Reemplazo directo de `Scaffold`
- Maneja automáticamente las áreas seguras
- Aplica la configuración del sistema

### `FullScreenSystemAware`
- Para contenido que ocupa toda la pantalla
- Respeta las barras del sistema
- Configurable para respetar o no cada barra

### Extensiones de Context
- `statusBarHeight`: Altura de la barra de estado
- `navigationBarHeight`: Altura de la barra de navegación
- `systemPadding`: Padding completo del sistema
- `safeAreaPadding`: Áreas seguras del sistema

## Ejemplos Incluidos

El archivo `example_screens.dart` incluye ejemplos de:
- Pantalla con AppBar
- Pantalla sin AppBar
- Pantalla con BottomNavigationBar
- Pantalla fullscreen

## Notas Importantes

1. **Íconos Nativos**: La configuración usa exclusivamente los íconos nativos de Android, no íconos personalizados.

2. **Compatibilidad**: Funciona tanto con navegación por botones como por gestos.

3. **Persistencia**: La configuración se mantiene en toda la aplicación automáticamente.

4. **Áreas Seguras**: Todo el contenido respeta automáticamente las áreas del sistema.

5. **Color Consistente**: Las barras siempre man