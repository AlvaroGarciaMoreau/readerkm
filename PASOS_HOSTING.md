# 📋 PASOS PARA COMPLETAR EN EL HOSTING

## 🎯 Resumen del problema resuelto
- ✅ **App actualizada**: Ahora usa `upload_image_simple.php` y `guardar_viaje_with_images.php`
- ✅ **Código corregido**: Eliminadas todas las referencias a tokens obsoletos
- 🔄 **Pendiente**: Subir archivos PHP y actualizar base de datos

## 📁 Archivos PHP a subir al hosting

### 1. Crear/Verificar en `/ReaderKM/fotos/`

```
https://www.moreausoft.com/ReaderKM/fotos/
├── upload_image_simple.php     ← Subir imagen sin tokens
├── guardar_viaje_with_images.php   ← Guardar viaje con imagen URL
├── listar_viajes_with_images.php   ← Listar viajes con imágenes
└── trip_images/               ← Carpeta imágenes (ya existe)
```

### 2. Scripts SQL a ejecutar

```sql
-- Agregar columnas para URLs de imágenes
ALTER TABLE viajes 
ADD COLUMN image_url VARCHAR(500) NULL,
ADD COLUMN image_filename VARCHAR(255) NULL;
```

## 🔧 Verificación del flujo

### Antes (con problemas):
1. App → `ImageUploadService` → `upload_image.php` (con tokens)
2. Home → `guardar_viaje.php` (sin soporte imágenes)
3. Token se perdía al reiniciar app ❌

### Ahora (solucionado):
1. App → `ImageUploadService` → `upload_image_simple.php` ✅
2. Home → `guardar_viaje_with_images.php` ✅
3. URL se guarda en BD → Persiste al reiniciar ✅

## 🧪 Prueba del sistema

1. **Capturar foto** en la app
2. **Verificar log**: "📸 Subiendo imagen..."
3. **Comprobar carpeta**: `/ReaderKM/fotos/trip_images/`
4. **Verificar BD**: Columnas `image_url` e `image_filename` pobladas
5. **Reiniciar app**: Imagen debe seguir visible

## ⚠️ Problemas conocidos resueltos

- ❌ **Antes**: Token se perdía → imagen desaparecía
- ✅ **Ahora**: URL en BD → imagen persiste
- ❌ **Antes**: Endpoint antiguo sin BD
- ✅ **Ahora**: Endpoint con integración BD

## 📞 ¿Necesitas los archivos PHP?

Los archivos están en el historial de la conversación:
- `upload_image_simple.php`
- `guardar_viaje_with_images.php` 
- `listar_viajes_with_images.php`

¡Todo el sistema está técnicamente listo! 🚀