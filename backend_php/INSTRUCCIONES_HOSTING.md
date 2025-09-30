# 📋 INSTRUCCIONES PARA CONFIGURAR EL HOSTING

## 🔧 **1. Estructura de directorios en tu servidor**

Para hostings compartidos que NO permiten crear directorios fuera de public_html:

```
public_html/
└── ReaderKM/
    └── fotos/
        ├── upload_image.php
        ├── secure_image.php
        ├── delete_image.php
        ├── .htaccess
        └── trip_images/         ← Directorio protegido DENTRO de public_html
            └── .htaccess        ← Protección adicional
```

## 🚀 **2. Subir archivos PHP**

### **A) Sube estos archivos a `public_html/ReaderKM/fotos/`:**
- `upload_image.php`
- `secure_image.php` 
- `delete_image.php`
- `.htaccess`

### **B) Crear directorio protegido:**
1. **Crear directorio:** `public_html/ReaderKM/fotos/trip_images/`
2. **Subir archivo de protección:** Copia `trip_images_htaccess` como `trip_images/.htaccess`

```bash
# Via administrador de archivos o FTP:
# 1. Crear directorio: public_html/ReaderKM/fotos/trip_images/
# 2. Subir trip_images_htaccess como: public_html/ReaderKM/fotos/trip_images/.htaccess
```

## ⚙️ **3. Configuración de permisos**

### **Archivos PHP:**
```bash
chmod 644 upload_image.php
chmod 644 secure_image.php  
chmod 644 delete_image.php
chmod 644 .htaccess
```

### **Directorio de imágenes:**
```bash
chmod 755 public_html/ReaderKM/fotos/trip_images/
chmod 644 public_html/ReaderKM/fotos/trip_images/.htaccess
```

## 🔐 **4. Configuración de seguridad**

### **A) Editar .htaccess (ya incluido):**
- Bloquea acceso directo a imágenes
- Previene listado de directorios
- Añade headers de seguridad

### **B) Verificar que funciona:**
1. **Test de subida:**
   ```bash
   curl -X POST https://www.moreausoft.com/ReaderKM/fotos/upload_image.php \
        -F "image=@test_image.jpg" \
        -F "email=test@example.com"
   ```

2. **Test de acceso directo (debe fallar):**
   ```bash
   curl https://www.moreausoft.com/ReaderKM/fotos/trip_images/
   # Debe devolver error 403 "Acceso denegado"
   ```

## 📱 **5. Configuración en la app Flutter**

La app ya está configurada para usar:
- **URL base:** `https://www.moreausoft.com/ReaderKM/fotos`
- **Subida:** `upload_image.php`
- **Visualización:** `secure_image.php`
- **Eliminación:** `delete_image.php`

## 🛠️ **6. Características de seguridad implementadas**

### **✅ Lo que SÍ funciona:**
- Imágenes completamente privadas
- Acceso solo con token válido
- Tokens con expiración (30 días)
- Validación de tipo de archivo
- Límite de tamaño (5MB)
- Protección contra directory traversal
- Logs de acceso y subidas

### **❌ Lo que NO pueden hacer terceros:**
- Acceder directamente a imágenes
- Listar archivos del directorio
- Subir archivos sin email válido
- Eliminar archivos de otros usuarios

## 🔍 **7. Monitoreo y logs**

### **Ver logs de acceso:**
```bash
tail -f /var/log/error.log | grep "ReaderKM"
```

### **Logs que se generan:**
- ✅ Subida exitosa: "ReaderKM: Imagen subida - Email: xxx, Archivo: xxx"
- 🔍 Acceso a imagen: "ReaderKM: Acceso a imagen - Archivo: xxx, IP: xxx"
- ❌ Eliminación: "ReaderKM: Imagen eliminada - Email: xxx, Archivo: xxx"

## 🚨 **8. Solución de problemas**

### **Error: "No se pudo subir imagen"**
1. Verificar permisos del directorio `trip_images` (debe ser 755)
2. Comprobar que PHP tiene permisos de escritura
3. Verificar límites de PHP (upload_max_filesize, post_max_size)

### **Error: "Token inválido"**
1. Verificar que la clave secreta coincide en ambos archivos
2. Comprobar que el tiempo del servidor es correcto

### **Error: "Imagen no carga"**
1. Verificar que `secure_image.php` tiene permisos de lectura
2. Comprobar que el token no ha expirado

## 🎯 **9. Testing rápido**

Para probar que todo funciona correctamente:

1. **Abrir la app ReaderKM**
2. **Configurar un email** en ajustes
3. **Tomar foto** con la cámara
4. **Guardar viaje** - debería mostrar "Imagen guardada en la nube"
5. **Ver el viaje** en la lista - debería mostrar la imagen

## 📊 **10. Estadísticas de uso**

Para ver cuántas imágenes se han subido:
```bash
ls -la public_html/ReaderKM/fotos/trip_images/ | wc -l
du -sh public_html/ReaderKM/fotos/trip_images/
```

---

## ⚡ **RESUMEN RÁPIDO:**

1. Subir 4 archivos PHP a `public_html/ReaderKM/fotos/`
2. Crear directorio `trip_images` dentro de `fotos/`
3. Subir archivo de protección como `trip_images/.htaccess`
4. Configurar permisos (755 para directorio, 644 para archivos)
5. Probar con la app

**¡Listo! Las fotos se guardarán de forma segura en tu hosting.** 🎉