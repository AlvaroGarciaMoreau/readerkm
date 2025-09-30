# 📋 INSTRUCCIONES PARA CONFIGURAR EL HOSTING

## 🔧 **1. Estructura de directorios en tu servidor**

Crea esta estructura en tu hosting:

```
/home/usuario/  (o el directorio raíz de tu cuenta)
├── public_html/
│   └── ReaderKM/
│       └── fotos/
│           ├── upload_image.php
│           ├── secure_image.php
│           ├── delete_image.php
│           └── .htaccess
└── fotos_privadas/      ← IMPORTANTE: Fuera de public_html
    └── trip_images/     (se crea automáticamente)
```

## 🚀 **2. Subir archivos PHP**

### **A) Sube estos archivos a `public_html/ReaderKM/fotos/`:**
- `upload_image.php`
- `secure_image.php` 
- `delete_image.php`
- `.htaccess`

### **B) Crear directorio privado:**
```bash
# Conéctate por SSH o usa el administrador de archivos
mkdir -p /home/usuario/fotos_privadas/trip_images
chmod 700 /home/usuario/fotos_privadas/trip_images
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
chmod 700 /home/usuario/fotos_privadas
chmod 700 /home/usuario/fotos_privadas/trip_images
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
   curl https://www.moreausoft.com/ReaderKM/fotos/../fotos_privadas/trip_images/
   # Debe devolver error 403 o 404
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
1. Verificar permisos del directorio `fotos_privadas`
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
ls -la /home/usuario/fotos_privadas/trip_images/ | wc -l
du -sh /home/usuario/fotos_privadas/trip_images/
```

---

## ⚡ **RESUMEN RÁPIDO:**

1. Subir 4 archivos PHP a `public_html/ReaderKM/fotos/`
2. Crear directorio `fotos_privadas` fuera de public_html
3. Configurar permisos (700 para directorios privados)
4. Probar con la app

**¡Listo! Las fotos se guardarán de forma segura en tu hosting.** 🎉