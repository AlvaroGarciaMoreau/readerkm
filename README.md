# ReaderKM 📱🚗

Una aplicación Flutter para Android que permite leer automáticamente los datos del cuadro de instrumentos de tu vehículo usando la cámara del móvil y OCR (Reconocimiento Óptico de Caracteres), calculando el costo del viaje basado en el consumo de combustible.

## 🌟 Características Principales

- **📸 Escaneo automático**: Utiliza la cámara para capturar el cuadro de instrumentos
- **🤖 OCR inteligente**: Extrae automáticamente kilómetros recorridos y consumo (km/L)
- **💰 Cálculo de costos**: Calcula el gasto en combustible del viaje
- **⚙️ Configuración persistente**: Guarda el precio de la gasolina para futuros cálculos
- **📊 Historial de viajes**: Mantiene un registro de todos tus viajes
- **✏️ Edición manual**: Permite corregir datos extraídos automáticamente
- **📱 Interfaz intuitiva**: Diseño limpio y fácil de usar

## 🚗 Vehículo de Referencia

Este proyecto fue desarrollado y probado específicamente con un **Hyundai Tucson Híbrido 2025** como vehículo de referencia. Los algoritmos de reconocimiento de texto están optimizados para detectar el formato específico del cuadro de instrumentos de este modelo, aunque pueden funcionar con otros vehículos que muestren datos similares.

### Datos Reconocidos del Tucson Híbrido 2025:
- **Kilómetros del viaje**: Lectura del odómetro parcial (Trip A/B)
- **Consumo instantáneo**: Valor en km/L mostrado en la pantalla digital
- **Formato típico**: "15.8 km/L" y valores de kilometraje

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
- Al abrir la app, toca el icono de engranaje (⚙️) en la barra superior
- Introduce el precio actual de la gasolina en €/L
- Este precio se guardará automáticamente para futuros cálculos

### 2. Escanear el Cuadro de Instrumentos
- Toca el botón "Escanear Cuadro de Instrumentos"
- Permite el acceso a la cámara cuando se solicite
- Encuadra el cuadro de instrumentos de tu vehículo dentro del marco blanco
- Asegúrate de que sean visibles:
  - Los kilómetros del viaje (Trip A o Trip B)
  - El consumo en km/L
- Toca el botón de captura (📷)

### 3. Revisar y Confirmar Datos
- La app mostrará los datos extraídos automáticamente
- **Detección automática**: Verás qué datos se detectaron correctamente (✅) o fallaron (❌)
- **Edición manual**: Puedes corregir cualquier valor si es necesario
- **Cálculo en tiempo real**: El costo se actualiza automáticamente
- Toca "Guardar Viaje" para registrar el viaje

### 4. Historial
- Consulta todos tus viajes guardados en la pantalla principal
- Cada entrada muestra: fecha, distancia, consumo, precio y costo total

## 🔧 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── screens/
│   ├── home_screen.dart      # Pantalla principal con historial
│   └── camera_screen.dart    # Pantalla de cámara y OCR
└── test_extraction.dart      # Pruebas de extracción de datos
```

## 🎯 Algoritmo de Reconocimiento

El sistema utiliza múltiples patrones regex para maximizar la precisión:

### Detección de Consumo (km/L):
- `(\d+(?:[.,]\d+)?)\s*km\s*/\s*[lL]` - Formato estándar: "15.8 km/L"
- `(\d+(?:[.,]\d+)?)\s*[kK][mM]/[lL]` - Formato alternativo: "15.8 KM/L"

### Detección de Kilómetros:
- Identificación inteligente de valores pequeños (viaje) vs. grandes (totales)
- Filtrado automático para evitar confusión con valores de consumo

## 🐛 Solución de Problemas

### La cámara no funciona
- Verifica que la app tenga permisos de cámara
- Reinicia la aplicación si es necesario

### OCR no detecta los datos
- Asegúrate de que haya buena iluminación
- El cuadro de instrumentos debe estar limpio y sin reflejos
- Mantén el móvil estable durante la captura
- Los números deben ser claramente visibles

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

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

**Álvaro García Moreau** - [@AlvaroGarciaMoreau](https://github.com/AlvaroGarciaMoreau)

## 🙏 Agradecimientos

- Google ML Kit por el potente motor de OCR
- Flutter team por el excelente framework
- La comunidad de Flutter por los plugins utilizados

---

**Nota**: Esta aplicación fue desarrollada como ejemplo educativo y está optimizada para el cuadro de instrumentos del Hyundai Tucson Híbrido 2025. Los resultados pueden variar con otros modelos de vehículos.
