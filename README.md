# ReaderKM 📱🚗

Una aplicación Flutter para Android que permite leer automáticamente los datos del cuadro de instrumentos de tu vehículo usando la cámara del móvil y OCR (Reconocimiento Óptico de Caracteres), calculando el costo del viaje basado en el consumo de combustible.

## 🌟 Características Principales

- **📸 Escaneo automático**: Utiliza la cámara para capturar el cuadro de instrumentos
- **🤖 OCR inteligente**: Extrae automáticamente kilómetros recorridos, consumo (km/L), tiempo de viaje y odómetro total
- **� Sincronización remota**: Guarda, lee y borra viajes en una base de datos MariaDB remota mediante backend PHP seguro
- **🔐 Separación por usuario**: Cada usuario tiene su propio historial de viajes gracias a un identificador UUID único
- **🗑️ Borrado seguro**: Permite eliminar viajes individuales de forma remota y segura
- **�💰 Cálculo avanzado de costos**: Calcula el gasto en combustible y consumo en L/100km usando fórmulas detalladas
- **⚙️ Configuración persistente**: Guarda el precio de la gasolina para futuros cálculos
- **📊 Historial completo**: Mantiene un registro detallado de todos tus viajes con información extendida, sincronizado con la nube
- **✏️ Edición manual**: Permite corregir datos extraídos automáticamente
- **⏱️ Análisis temporal**: Captura y muestra el tiempo de duración de cada viaje
- **📏 Seguimiento del odómetro**: Registra los kilómetros totales del vehículo
- **📱 Interfaz intuitiva**: Diseño limpio, modular y fácil de usar

## 🚗 Vehículo de Referencia

Este proyecto fue desarrollado y probado específicamente con un **Hyundai Tucson Híbrido 2025** como vehículo de referencia. Los algoritmos de reconocimiento de texto están optimizados para detectar el formato específico del cuadro de instrumentos de este modelo, aunque pueden funcionar con otros vehículos que muestren datos similares.

### Datos Reconocidos del Tucson Híbrido 2025:
- **Kilómetros del viaje**: Lectura del odómetro parcial (Trip A/B) - valor con icono de flecha →
- **Consumo instantáneo**: Valor en km/L mostrado en la pantalla digital con icono de surtidor +
- **Tiempo de viaje**: Duración del trayecto en formato hh:mm con icono de reloj ⏰
- **Kilómetros totales**: Lectura del odómetro total del vehículo (valores >1000 km)
- **Autonomía**: Se ignora correctamente la autonomía restante (valor con surtidor ⛽)
- **Formatos reconocidos**: "13.7 km/L", "10.1 km", "0:16 h:m", "1077 km"

## 🛠️ Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo multiplataforma
- **Dart**: Lenguaje de programación
- **Camera Plugin**: Acceso a la cámara del dispositivo
- **Google ML Kit**: Reconocimiento de texto (OCR)
- **SharedPreferences**: Persistencia de datos local
- **Permission Handler**: Gestión de permisos

## 📋 Requisitos

- **Android SDK**: Versión 36 o superior
- **NDK**: Versión 27.0.12077973
- **Flutter**: Versión 3.0 o superior
- **Permisos necesarios**:
  - Cámara (para escanear el cuadro de instrumentos)

## 🚀 Instalación

1. **Clona el repositorio**:
   ```bash
   git clone https://github.com/AlvaroGarciaMoreau/readerkm.git
   cd readerkm
   ```

2. **Instala las dependencias**:
   ```bash
   flutter pub get
   ```

3. **Configura el entorno Android**:
   - Asegúrate de tener Android SDK 36 instalado
   - Configura NDK versión 27.0.12077973

4. **Ejecuta la aplicación**:
   ```bash
   flutter run
   ```

## 📖 Cómo Usar

### 1. Configuración Inicial
- Al abrir la app, toca el icono de gasolina (⛽) en la barra superior
- Introduce el precio actual de la gasolina en €/L
- Este precio se guardará automáticamente para futuros cálculos

### 2. Escanear el Cuadro de Instrumentos
- Toca el botón "Escanear Cuadro"
- Permite el acceso a la cámara cuando se solicite
- Encuadra el cuadro de instrumentos de tu vehículo dentro del marco blanco
- Asegúrate de que sean claramente visibles:
  - Los kilómetros del viaje (Trip A o Trip B) con icono de flecha →
  - El consumo en km/L con icono de surtidor +
  - El tiempo de viaje con icono de reloj ⏰ (opcional)
  - Los kilómetros totales del odómetro (opcional)
- Toca el botón de captura (📷)

### 3. Revisar y Confirmar Datos
- La app mostrará los datos extraídos automáticamente con indicadores de detección:
  - ✅ **Kilómetros de viaje**: Valor detectado del odómetro parcial
  - ✅ **Consumo**: Valor en km/L detectado automáticamente
  - ✅ **Tiempo de viaje**: Duración detectada (si está visible)
  - ✅ **Km totales**: Odómetro total detectado (si está visible)
- **Detección inteligente**: El sistema ignora automáticamente la autonomía restante
- **Edición manual**: Puedes corregir cualquier valor si es necesario
- **Cálculo en tiempo real**: El costo total y L/100km se actualiza automáticamente
- Toca "Guardar Viaje" para registrar el viaje

### 4. Historial Completo
- Consulta todos tus viajes guardados en la pantalla principal
- Cada entrada muestra información detallada:
  - Fecha y hora del viaje
  - Distancia recorrida
  - Consumo en km/L y L/100km
  - Precio del combustible utilizado
  - Costo total del viaje
  - Tiempo de duración (si se detectó)
  - Kilómetros del odómetro (si se detectó)

## 🔧 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada con configuración de orientación
├── models/
│   └── trip_data.dart          # Modelo de datos de viajes con campos extendidos
├── services/
│   └── preferences_service.dart # Servicio de persistencia de datos
├── widgets/
│   ├── trip_card.dart          # Widget de tarjeta de viaje con información completa
│   └── camera_scan_section.dart # Widget de sección de escaneo
├── utils/
│   └── dialog_utils.dart       # Utilidades para diálogos centralizados
├── screens/
│   ├── home_screen.dart        # Pantalla principal refactorizada
│   └── camera_screen.dart      # Pantalla de cámara con OCR mejorado
└── test_extraction.dart        # Pruebas de extracción de datos
```

## 🎯 Algoritmo de Reconocimiento OCR Avanzado

El sistema utiliza un algoritmo de reconocimiento contextual específicamente optimizado para el Hyundai Tucson Híbrido 2025:

### Reconocimiento Inteligente por Contexto:
- **Análisis posicional**: Examina el texto línea por línea para identificar contextos
- **Filtrado inteligente**: Ignora automáticamente la autonomía restante (ej: "280 km" con surtidor)
- **Validación por rangos**: Cada tipo de dato tiene rangos de validación específicos

### Detección Específica por Tipo:

#### 🚗 **Kilómetros de Viaje**:
- Busca valores cerca del contexto "viaje actual"
- Rango válido: 0.1 - 999 km
- Prioriza valores pequeños típicos de trayectos

#### ⛽ **Consumo (km/L)**:
- Patrones: `13.7 km/L`, `13.7km/L`, `13.7 KM/L`
- Rango válido: 5 - 50 km/L (típico para híbridos)
- Reconoce múltiples formatos y variaciones

#### ⏱️ **Tiempo de Viaje**:
- Formato: `0:16`, `1:30 h:m`, `2:45`
- Validación: horas (0-23), minutos (0-59)
- Asociado con iconos de reloj

#### 🔢 **Kilómetros Totales**:
- Valores ≥ 1000 km (típico del odómetro)
- Localización: parte inferior del cuadro
- Diferenciación automática de valores de viaje

### Cálculos Automáticos y Fórmulas:
- **Litros consumidos**: `litros = distancia / consumo`  
- **Costo total**: `costo = litros × precio combustible`  
- **Consumo en L/100km**: `L/100km = (litros / distancia) × 100`  
Todos los cálculos se realizan automáticamente al guardar el viaje y se almacenan en la base de datos.
## 🌐 Integración con Base de Datos Remota

La app está conectada a un backend PHP seguro que gestiona el almacenamiento, lectura y borrado de viajes en una base de datos MariaDB remota. Cada usuario tiene su propio historial gracias a un identificador UUID único que se genera y almacena localmente.

### Funcionalidades de la base de datos:
- **Guardar viaje**: Al confirmar un viaje, los datos se envían al backend y se almacenan en la base de datos remota.
- **Leer historial**: Al abrir la app, se consulta el backend y se muestra el historial de viajes del usuario.
- **Borrar viaje**: Se puede eliminar cualquier viaje individualmente; la operación es segura y solo afecta al usuario correspondiente.
- **Separación por usuario**: Todos los datos están aislados por UUID, garantizando privacidad y seguridad.
- **Respuestas robustas**: El backend siempre responde en formato JSON, incluso ante errores, para evitar fallos en la app.

### Estructura de la tabla `viajes`:
| id | user_uuid | distance | consumption | fuelPrice | totalCost | litersPer100Km | travelTime | totalKm | fecha |
|----|-----------|----------|-------------|-----------|-----------|---------------|------------|---------|-------|

### Seguridad y robustez
- El backend valida todos los datos recibidos y nunca expone información sensible.
- No existe opción de borrado masivo, solo individual y autenticado por UUID.
- El código PHP está preparado para manejar errores de conexión y devolver mensajes claros a la app.

## 🐛 Solución de Problemas

### La cámara no funciona
- Verifica que la app tenga permisos de cámara
- Reinicia la aplicación si es necesario

### OCR no detecta los datos correctamente
- Asegúrate de que haya buena iluminación uniforme
- El cuadro de instrumentos debe estar limpio y sin reflejos
- Mantén el móvil estable durante la captura
- Los números deben ser claramente visibles y legibles
- Evita sombras o brillos que puedan interferir
- Si persisten errores, utiliza la edición manual

### La app confunde diferentes tipos de kilómetros
- El algoritmo está optimizado para ignorar la autonomía automáticamente
- Si detecta valores incorrectos, verifica que el contexto "viaje actual" sea visible
- Los valores pequeños (<1000) se interpretan como viaje, los grandes (≥1000) como totales

### Datos faltantes en el historial
- **Tiempo de viaje**: Solo se muestra si fue detectado en el cuadro
- **Km totales**: Solo aparece si el odómetro total era visible durante el escaneo
- Los datos opcionales no afectan el cálculo de costos

### Datos incorrectos extraídos
- Utiliza la función de edición manual en el diálogo de resultados
- Los campos se pueden corregir antes de guardar el viaje

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para contribuir:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 🔄 Historial de Versiones

### v2.0.0 - Reconocimiento OCR Avanzado
- ✅ Algoritmo OCR específico para Hyundai Tucson Híbrido 2025
- ✅ Detección de tiempo de viaje y kilómetros totales
- ✅ Cálculo de consumo en L/100km
- ✅ Refactorización completa de la arquitectura
- ✅ Filtrado inteligente de datos irrelevantes
- ✅ Interfaz mejorada con más información

### v1.0.0 - Versión Inicial
- ✅ Reconocimiento básico de km y consumo
- ✅ Cálculo de costos de combustible
- ✅ Historial de viajes
- ✅ Configuración de precios

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

**Álvaro García Moreau** - [@AlvaroGarciaMoreau](https://github.com/AlvaroGarciaMoreau)

## 🙏 Agradecimientos

- Google ML Kit por el potente motor de OCR
- Flutter team por el excelente framework
- La comunidad de Flutter por los plugins utilizados
- Hyundai por el diseño claro y legible del cuadro de instrumentos

---

**Nota**: Esta aplicación fue desarrollada y está específicamente optimizada para el cuadro de instrumentos del **Hyundai Tucson Híbrido 2025**. El algoritmo de reconocimiento OCR ha sido entrenado con los patrones específicos de este modelo. Los resultados pueden variar con otros modelos de vehículos, aunque la funcionalidad básica debería mantenerse para cuadros con formatos similares.
