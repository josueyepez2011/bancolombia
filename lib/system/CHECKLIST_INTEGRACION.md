s# ✅ Checklist de Integración del Sistema de Errores

## 📋 Guía Paso a Paso

### Fase 1: Preparación

- [ ] Revisar `lib/system/error_handler_system.dart`
- [ ] Revisar `lib/system/ERROR_HANDLER_SYSTEM_README.md`
- [ ] Revisar `lib/system/COMPARATIVA_ANTES_DESPUES.md`
- [ ] Entender el flujo del sistema

### Fase 2: Integración en Pantallas

#### Pantalla: `lib/screen/home.dart`
- [ ] Agregar import: `import '../system/index.dart';`
- [ ] Envolver Scaffold con `ErrorHandlerScreen`
- [ ] Reemplazar `ErrorSnackBar.show()` con `context.showError()`
- [ ] Reemplazar `ErrorSnackBar.show(..., isError: false)` con `context.showSuccess()`
- [ ] Reemplazar `ErrorDialog.show()` con `context.showError()`
- [ ] Agregar `onRetry` donde sea necesario
- [ ] Probar que los errores se muestren correctamente
- [ ] Verificar que no haya conflictos con otros widgets

#### Pantalla: `lib/screen/login.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/register.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/profile.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/settings.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/transacciones.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/transferir_plata_screen.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/movimiento_screen.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/select_qr.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Pantalla: `lib/screen/ajuste.dart`
- [ ] Agregar import
- [ ] Envolver Scaffold
- [ ] Reemplazar ErrorSnackBar
- [ ] Reemplazar ErrorDialog
- [ ] Agregar reintentos
- [ ] Probar

#### Otras pantallas (agregar según sea necesario)
- [ ] Pantalla: ________________
- [ ] Pantalla: ________________
- [ ] Pantalla: ________________

### Fase 3: Validación

- [ ] Compilar sin errores
- [ ] No hay warnings de imports no usados
- [ ] Todos los `ErrorSnackBar.show()` fueron reemplazados
- [ ] Todos los `ErrorDialog.show()` fueron reemplazados
- [ ] Los errores se muestran correctamente
- [ ] Las advertencias se muestran correctamente
- [ ] Los mensajes de éxito se muestran correctamente
- [ ] Los reintentos funcionan correctamente
- [ ] La cola de errores funciona (múltiples errores)
- [ ] Los errores se auto-limpian después de la duración

### Fase 4: Testing

#### Test de Errores
- [ ] Mostrar error simple
- [ ] Mostrar error con reintento
- [ ] Mostrar múltiples errores simultáneamente
- [ ] Verificar que se limpian automáticamente

#### Test de Advertencias
- [ ] Mostrar advertencia simple
- [ ] Verificar color naranja
- [ ] Verificar icono de advertencia

#### Test de Éxito
- [ ] Mostrar mensaje de éxito
- [ ] Verificar color verde
- [ ] Verificar icono de check

#### Test de UI
- [ ] Banners se muestran correctamente
- [ ] SnackBars se muestran desde arriba
- [ ] Diálogos se muestran en el centro (si está habilitado)
- [ ] Los textos son legibles
- [ ] Los iconos son visibles
- [ ] Los botones funcionan

#### Test de Rendimiento
- [ ] No hay lag al mostrar errores
- [ ] La app no se congela
- [ ] La memoria se libera correctamente

### Fase 5: Documentación

- [ ] Actualizar README del proyecto
- [ ] Documentar cambios en CHANGELOG
- [ ] Agregar ejemplos en la documentación
- [ ] Documentar cualquier cambio especial

### Fase 6: Limpieza

- [ ] Remover imports no usados de `error_widgets.dart`
- [ ] Remover archivos de ejemplo si no se necesitan
- [ ] Verificar que no haya código duplicado
- [ ] Limpiar comentarios temporales

---

## 🔍 Verificación Final

### Checklist de Verificación

```dart
// ✅ Verificar que esto funciona:

// 1. Error simple
context.showError(message: 'Error de prueba');

// 2. Advertencia
context.showWarning(message: 'Advertencia de prueba');

// 3. Éxito
context.showSuccess(message: 'Éxito de prueba');

// 4. Error con reintento
context.showError(
  message: 'Error con reintento',
  onRetry: () => print('Reintentando...'),
);

// 5. Múltiples errores
context.showError(message: 'Error 1');
context.showError(message: 'Error 2');
context.showError(message: 'Error 3');
```

### Verificación de Compilación

```bash
# Ejecutar análisis
flutter analyze

# Compilar
flutter build apk

# O para iOS
flutter build ios
```

---

## 📊 Progreso

### Resumen de Pantallas

| Pantalla | Estado | Notas |
|----------|--------|-------|
| home.dart | ⬜ | Pendiente |
| login.dart | ⬜ | Pendiente |
| register.dart | ⬜ | Pendiente |
| profile.dart | ⬜ | Pendiente |
| settings.dart | ⬜ | Pendiente |
| transacciones.dart | ⬜ | Pendiente |
| transferir_plata_screen.dart | ⬜ | Pendiente |
| movimiento_screen.dart | ⬜ | Pendiente |
| select_qr.dart | ⬜ | Pendiente |
| ajuste.dart | ⬜ | Pendiente |

**Leyenda:**
- ⬜ Pendiente
- 🟨 En progreso
- ✅ Completado

---

## 💡 Tips Útiles

### Tip 1: Buscar y Reemplazar
```
Buscar: ErrorSnackBar.show(
Reemplazar con: context.showError(
```

### Tip 2: Buscar ErrorDialog
```
Buscar: ErrorDialog.show(
Reemplazar con: context.showError(
```

### Tip 3: Buscar ErrorBanner
```
Buscar: ErrorBanner(
Reemplazar con: context.showWarning(
```

### Tip 4: Verificar Imports
```dart
// Agregar al inicio de cada pantalla
import '../system/index.dart';
```

### Tip 5: Envolver Scaffold
```dart
// Cambiar de:
return Scaffold(...)

// A:
return ErrorHandlerScreen(
  child: Scaffold(...),
)
```

---

## 🚨 Problemas Comunes

### Problema 1: "ErrorHandlerScreen no encontrado"
**Solución:** Verificar que el import sea correcto
```dart
import '../system/index.dart';
```

### Problema 2: "context.showError no existe"
**Solución:** Verificar que ErrorHandlerScreen envuelve el widget
```dart
return ErrorHandlerScreen(
  child: Scaffold(...),
);
```

### Problema 3: "Los errores no aparecen"
**Solución:** Verificar que showErrorBanner o showErrorSnackBar esté en true
```dart
ErrorHandlerScreen(
  showErrorBanner: true,
  showErrorSnackBar: true,
  child: Scaffold(...),
)
```

### Problema 4: "Múltiples errores se superponen"
**Solución:** Es normal, el sistema muestra máximo 2 simultáneamente

### Problema 5: "Los errores no se limpian"
**Solución:** Se limpian automáticamente después de la duración

---

## 📞 Soporte

Si tienes problemas:

1. Revisar `lib/system/ERROR_HANDLER_SYSTEM_README.md`
2. Revisar `lib/system/error_handler_integration_guide.dart`
3. Revisar `lib/system/COMPARATIVA_ANTES_DESPUES.md`
4. Revisar ejemplos en `lib/system/EJEMPLO_INTEGRACION_HOME.dart`

---

## ✨ Próximos Pasos

Una vez completada la integración:

1. **Optimizar** - Revisar y optimizar el código
2. **Documentar** - Actualizar documentación del proyecto
3. **Testing** - Realizar testing completo
4. **Deploy** - Desplegar a producción
5. **Monitorear** - Monitorear errores en producción

---

**Última actualización:** 2026-01-17
**Estado:** Sistema listo para integración ✅
