# Actualización: Litros por 100km - ReaderKM

## Resumen de Cambios

Se ha añadido exitosamente el cálculo de "litros a los 100 km" (L/100km) en la aplicación ReaderKM. Este es un indicador estándar de consumo de combustible muy útil para comparar eficiencia.

## Archivos Modificados

### 📁 `lib/models/trip_data.dart`
- ✅ **Nuevo campo**: `litersPer100Km` (double)
- ✅ **Constructor actualizado**: Incluye el nuevo parámetro requerido
- ✅ **Serialización JSON**: Métodos `toJson()` y `fromJson()` actualizados
- ✅ **Compatibilidad**: Valor por defecto (0.0) para datos existentes

### 📁 `lib/screens/camera_screen.dart`
- ✅ **Cálculo en tiempo real**: Se muestra L/100km en la sección "Cálculo del Gasto"
- ✅ **Fórmula aplicada**: `(litros consumidos / kilómetros recorridos) * 100`
- ✅ **Widget `_buildCostCalculation()`**: Nuevo campo visual con estilo azul
- ✅ **Método `_saveTrip()`**: Cálculo y guardado del nuevo dato

### 📁 `lib/widgets/trip_card.dart`
- ✅ **Historial mejorado**: Muestra L/100km en cada tarjeta de viaje
- ✅ **Información completa**: Añadida línea adicional con el consumo estándar

## Funcionalidad Añadida

### 🧮 **Cálculo Automático**
- **Fórmula**: `L/100km = (Litros Consumidos ÷ Kilómetros Recorridos) × 100`
- **Ejemplo**: Si consumes 5 litros en 100 km → 5.00 L/100km
- **Actualización en tiempo real**: Se recalcula automáticamente al cambiar los valores

### 📊 **Visualización**
1. **En la ventana de datos extraídos**:
   ```
   💰 Cálculo del Gasto:
   Litros consumidos: 4.50 L
   Costo total: €6.75
   Consumo: 6.43 L/100km  ← NUEVO
   ```

2. **En el historial de viajes**:
   ```
   25.5 km
   Consumo: 15.8 km/L
   Precio: €1.50/L
   L/100km: 6.33  ← NUEVO
   28/7/2025 a las 14:30
   ```

### 🔄 **Compatibilidad**
- **Datos existentes**: Los viajes guardados anteriormente mostrarán 0.00 L/100km
- **Nuevos viajes**: Incluirán automáticamente el cálculo correcto
- **Sin pérdida de datos**: Todos los viajes previos se mantienen intactos

## Beneficios del Nuevo Indicador

### 📈 **Estándar Internacional**
- Medida universalmente reconocida para consumo de combustible
- Facilita comparaciones con especificaciones del fabricante
- Formato usado en la mayoría de países europeos

### 🔍 **Análisis Mejorado**
- Complementa la medida km/L existente
- Permite detectar patrones de consumo más fácilmente
- Útil para seguimiento de eficiencia del vehículo

### 👤 **Experiencia de Usuario**
- Información más completa en cada viaje
- Datos presentados de forma clara y organizada
- Cálculo automático sin intervención del usuario

## Ejemplo de Uso

**Datos de entrada:**
- Kilómetros del viaje: 70 km
- Consumo del vehículo: 14.0 km/L
- Precio combustible: €1.45/L

**Resultados calculados:**
- Litros consumidos: 5.00 L
- Costo total: €7.25
- **Consumo: 7.14 L/100km** ← Nuevo indicador

Este nuevo cálculo proporciona una perspectiva adicional valiosa sobre el consumo de combustible, complementando perfectamente los datos ya existentes en la aplicación.
