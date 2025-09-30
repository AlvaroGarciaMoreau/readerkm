# ReaderKM 📱🚗

Una aplicación Flutter para Android que permite leer automáticamente los datos del cuadro de instrumentos de tu vehículo usando la cámara del móvil y OCR (Reconocimiento Óptico de Caracteres), calculando el costo del viaje basado en el consumo de combustible.

## 🌟 Características Principales

- **📸 Escaneo automático**: Utiliza la cámara para capturar el cuadro de instrumentos
- **🤖 OCR inteligente**: Extrae automáticamente kilómetros recorridos, consumo (km/L y L/100km), tiempo de viaje y odómetro total
- **☁️ Sincronización remota**: Guarda, lee y borra viajes en una base de datos MariaDB remota mediante backend PHP seguro
- **📧 Sincronización por email**: Cada usuario puede sincronizar sus viajes usando su correo electrónico
- **💾 Almacenamiento local**: Modo offline disponible para guardar viajes localmente sin conexión
- **🗑️ Borrado seguro**: Permite eliminar viajes individuales de forma remota y segura
- **💰 Cálculo avanzado de costos**: Calcula el gasto en combustible y consumo en L/100km usando fórmulas detalladas
- **🧮 Calculadora integrada**: Herramienta independiente para cálculos manuales de combustible
- **⚙️ Configuración persistente**: Guarda el precio de la gasolina para futuros cálculos
- **📊 Historial completo**: Mantiene un registro detallado de todos tus viajes con información extendida
- **✏️ Edición manual**: Permite corregir datos extraídos automáticamente
- **⏱️ Análisis temporal**: Captura y muestra el tiempo de duración de cada viaje
- **📏 Seguimiento del odómetro**: Registra los kilómetros totales del vehículo
- **🎨 Interfaz moderna**: Diseño de tarjetas mejorado con información clara y organizada
- **🛡️ Manejo robusto de errores**: Gestión avanzada de errores de red y respuestas del servidor
- **⏰ Advertencias inteligentes**: Sistema de notificaciones para configuración de email
- **🔄 Prevención de duplicados**: Sistema avanzado para evitar registros duplicados

## 🚗 Vehículo de Referencia

Este proyecto fue desarrollado y probado específicamente con un **Hyundai Tucson Híbrido 2025** como vehículo de referencia. Los algoritmos de reconocimiento de texto están optimizados para detectar el formato específico del cuadro de instrumentos de este modelo, aunque pueden funcionar con otros vehículos que muestren datos similares.

### Datos Reconocidos del Tucson Híbrido 2025:
- **Kilómetros del viaje**: Lectura del odómetro parcial (Trip A/B) - valor con icono de flecha →
- **Consumo instantáneo**: Valor en km/L o L/100km mostrado en la pantalla digital con icono de surtidor +
- **Tiempo de viaje**: Duración del trayecto en formato hh:mm con icono de reloj ⏰
- **Kilómetros totales**: Lectura del odómetro total del vehículo (valores >1000 km)
- **Autonomía**: Se ignora correctamente la autonomía restante (valor con surtidor ⛽)
- **Formatos reconocidos**: "13.7 km/L", "6.8 L/100km", "10.1 km", "0:16 h:m", "1077 km"
- **Detección dual**: Reconoce automáticamente tanto km/L como L/100km

## 🛠️ Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo multiplataforma
- **Dart**: Lenguaje de programación
- **Camera Plugin**: Acceso a la cámara del dispositivo
- **Google ML Kit**: Reconocimiento de texto (OCR)
- **SharedPreferences**: Persistencia de datos local
- **Permission Handler**: Gestión de permisos
- **HTTP**: Comunicación con backend remoto
- **JSON**: Serialización de datos

## 📋 Requisitos

- **Android SDK**: Versión 36 o superior
- **NDK**: Versión 27.0.12077973
- **Flutter**: Versión 3.0 o superior
- **Permisos necesarios**:
  - Cámara (para escanear el cuadro de instrumentos)
  - Internet (para sincronización remota)

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
- Al abrir la app, se mostrará un diálogo para configurar tu email (opcional)
- Toca el icono de gasolina (⛽) en la barra superior
- Introduce el precio actual de la gasolina en €/L
- Este precio se guardará automáticamente para futuros cálculos

### 2. Configuración de Sincronización (Opcional)
- Toca el icono de configuración (⚙️) en la barra superior
- Introduce tu correo electrónico para sincronizar viajes entre dispositivos
- Deja vacío para usar solo almacenamiento local
- **Nota**: Sin email configurado, los viajes se guardan solo localmente

### 3. Calculadora Manual (Opcional)
- Toca el icono de calculadora (🧮) en la barra superior
- Introduce distancia, consumo (km/L o L/100km) y precio de combustible
- La calculadora te mostrará los resultados instantáneamente:
  - Litros por 100km
  - Litros usados
  - Costo total del viaje
- Ideal para cálculos rápidos sin necesidad de escanear

### 4. Escanear el Cuadro de Instrumentos
- Toca el botón "Escanear Cuadro"
- Permite el acceso a la cámara cuando se solicite
- Encuadra el cuadro de instrumentos de tu vehículo dentro del marco blanco
- Asegúrate de que sean claramente visibles:
  - Los kilómetros del viaje (Trip A o Trip B) con icono de flecha →
  - El consumo en km/L o L/100km con icono de surtidor +
  - El tiempo de viaje con icono de reloj ⏰ (opcional)
  - Los kilómetros totales del odómetro (opcional)
- Toca el botón de captura (📷)

### 5. Revisar y Confirmar Datos
- La app mostrará los datos extraídos automáticamente con indicadores de detección:
  - ✅ **Kilómetros de viaje**: Valor detectado del odómetro parcial
  - ✅ **Consumo**: Valor en km/L o L/100km detectado automáticamente
  - ✅ **Tiempo de viaje**: Duración detectada (si está visible)
  - ✅ **Km totales**: Odómetro total detectado (si está visible)
- **Detección inteligente**: El sistema ignora automáticamente la autonomía restante
- **Edición manual**: Puedes corregir cualquier valor si es necesario
- **Cálculo en tiempo real**: El costo total y L/100km se actualiza automáticamente
- **Prevención de duplicados**: El sistema detecta y previene registros duplicados
- Toca "Guardar Viaje" para registrar el viaje

### 6. Historial Completo
- Consulta todos tus viajes guardados en la pantalla principal
- Cada tarjeta muestra información organizada:
  - **Header**: Fecha, hora y botón eliminar
  - **Información principal**: Distancia, consumo y costo total en tarjetas separadas
  - **Información adicional**: Tiempo y odómetro (si están disponibles)
  - **Precio combustible**: Información del precio utilizado

## 🎨 Nueva Interfaz de Tarjetas

La aplicación ahora presenta un diseño de tarjetas moderno y organizado:

### Estructura de la Tarjeta:
```
┌─────────────────────────────────────────┐
│ 🚗 24/08/2024 a las 12:46        🗑️    │
│                                         │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │ 📏      │ │ ⛽       │ │ 💶      │    │
│ │Distancia│ │Consumo  │ │ Total   │    │
│ │ 15.2 km │ │ 6.5 L/  │ │ 12.50 € │    │
│ │         │ │ 100km   │ │         │    │
│ │         │ │(15.4 km/│ │         │    │
│ │         │ │  L)     │ │         │    │
│ └─────────┘ └─────────┘ └─────────┘    │
│                                         │
│ ⏰ Tiempo: 25 min  🚗 Odómetro: 1250 km │
│ 💰 Precio combustible: 1.50 €/L         │
└─────────────────────────────────────────┘
```

### Características del nuevo diseño:
- **Sin números de índice**: Eliminado el círculo confuso con números
- **Información organizada**: Datos agrupados lógicamente
- **Iconos descriptivos**: Cada tipo de dato tiene su icono representativo
- **Colores diferenciados**: Distancia (azul), consumo (naranja), total (verde)
- **Información destacada**: El costo total se resalta visualmente
- **Datos opcionales**: Solo se muestran si están disponibles

## 🔧 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada con configuración de orientación
├── models/
│   └── trip_data.dart          # Modelo de datos de viajes con campos extendidos
├── services/
│   └── preferences_service.dart # Servicio de persistencia de datos
├── widgets/
│   ├── trip_card.dart          # Widget de tarjeta de viaje rediseñado
│   └── camera_scan_section.dart # Widget de sección de escaneo
├── utils/
│   └── dialog_utils.dart       # Utilidades para diálogos centralizados
├── screens/
│   ├── home_screen.dart        # Pantalla principal con manejo de errores mejorado
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

#### ⛽ **Consumo (km/L y L/100km)**:
- **Patrones km/L**: `13.7 km/L`, `13.7km/L`, `13.7 KM/L`
- **Patrones L/100km**: `6.8 L/100km`, `6.8l/100km`, `6.8hookm` (errores OCR)
- **Rango válido km/L**: 5 - 50 km/L (típico para híbridos)
- **Rango válido L/100km**: 2 - 20 L/100km
- **Detección dual**: Reconoce automáticamente ambas unidades
- **Conversión automática**: Calcula equivalencias entre unidades

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

La app está conectada a un backend PHP seguro que gestiona el almacenamiento, lectura y borrado de viajes en una base de datos MariaDB remota. Los usuarios pueden sincronizar sus datos usando su correo electrónico.

### Funcionalidades de la base de datos:
- **Guardar viaje**: Al confirmar un viaje, los datos se envían al backend y se almacenan en la base de datos remota
- **Leer historial**: Al abrir la app, se consulta el backend y se muestra el historial de viajes del usuario
- **Borrar viaje**: Se puede eliminar cualquier viaje individualmente; la operación es segura y solo afecta al usuario correspondiente
- **Separación por email**: Todos los datos están aislados por correo electrónico, garantizando privacidad y seguridad
- **Respuestas robustas**: El backend siempre responde en formato JSON, incluso ante errores, para evitar fallos en la app

### Estructura de la tabla `viajes`:
| id | email | distance | consumption | consumptionUnit | fuelPrice | totalCost | litersPer100Km | travelTime | totalKm | fecha |
|----|-------|----------|-------------|-----------------|-----------|-----------|----------------|------------|---------|-------|

**Campos actualizados:**
- `consumptionUnit`: Almacena la unidad original (km/L o L/100km)
- `litersPer100Km`: Siempre calculado y almacenado para consistencia

### Seguridad y robustez:
- El backend valida todos los datos recibidos y nunca expone información sensible
- No existe opción de borrado masivo, solo individual y autenticado por email
- El código PHP está preparado para manejar errores de conexión y devolver mensajes claros a la app

## 🛡️ Manejo Avanzado de Errores

La aplicación incluye un sistema robusto de manejo de errores:

### Errores de Red:
- **Timeouts**: Configurados a 30 segundos para todas las operaciones
- **Errores de conexión**: Mensajes específicos para problemas de red
- **Respuestas inválidas**: Manejo de respuestas HTML en lugar de JSON
- **Errores del servidor**: Información detallada sobre códigos de estado

### Validaciones:
- **ID de viaje**: Validación antes de eliminar viajes
- **Formato JSON**: Manejo de respuestas malformadas del servidor
- **Contexto de widget**: Verificaciones de `mounted` para evitar errores de UI
- **Prevención de duplicados**: Sistema que detecta y previene registros duplicados basado en:
  - Misma distancia, consumo y costo total
  - Registro dentro de una ventana de 5 minutos
  - Validación antes del guardado local y remoto

### Mensajes de Usuario:
- **Advertencias de email**: Notificaciones sobre configuración de sincronización
- **Errores específicos**: Mensajes claros para cada tipo de problema
- **Confirmaciones**: Feedback positivo para operaciones exitosas

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

### Errores de sincronización
- Verifica tu conexión a internet
- Asegúrate de que el email esté configurado correctamente
- Los viajes se guardan localmente si hay problemas de red
- Revisa los mensajes de error específicos en la aplicación

### Viajes duplicados
- **Prevención automática**: El sistema detecta automáticamente viajes duplicados
- **Criterios de detección**: Misma distancia, consumo, costo y fecha dentro de 5 minutos
- **Mensaje de confirmación**: Te notificará si intentas registrar un viaje que ya existe
- **Protección**: Evita registros accidentales múltiples del mismo trayecto

### No se pueden eliminar viajes
- Los viajes recién creados necesitan sincronizarse primero
- Verifica que tengas conexión a internet
- Los viajes locales se pueden eliminar inmediatamente

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para contribuir:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 🔄 Historial de Versiones

### v2.2.0 - Correcciones y Estabilidad (Septiembre 2025)
- ✅ **Corrección de errores críticos**: Resueltos todos los errores de compilación
- ✅ **Arquitectura refactorizada**: `main.dart`, `PreferencesService` y `TripCard` completamente implementados
- ✅ **Prevención de duplicados mejorada**: Sistema robusto para evitar viajes duplicados
- ✅ **Calculadora restaurada**: Icono y funcionalidad de calculadora manual reintegrados
- ✅ **Soporte dual de unidades**: Reconocimiento automático de km/L y L/100km
- ✅ **Gestión de estado mejorada**: Prevención de guardados múltiples simultáneos
- ✅ **Manejo de errores perfeccionado**: Bloques try-finally para limpieza garantizada
- ✅ **Base de código estabilizada**: Sin errores de compilación, solo advertencias menores

### v2.1.0 - Interfaz Moderna y Manejo de Errores
- ✅ Rediseño completo de tarjetas de viaje
- ✅ Eliminación de círculos con números
- ✅ Manejo avanzado de errores de red
- ✅ Validación de IDs antes de eliminar viajes
- ✅ Mensajes de error específicos y claros
- ✅ Timeouts configurados para operaciones de red
- ✅ Manejo de respuestas HTML del servidor
- ✅ Verificaciones de contexto de widget

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
