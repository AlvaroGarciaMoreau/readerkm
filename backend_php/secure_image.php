<?php
// Script para servir imágenes con autenticación por token

if (!isset($_GET['token']) || !isset($_GET['file'])) {
    http_response_code(403);
    die('Acceso denegado: Token o archivo no especificado');
}

$token = $_GET['token'];
$filename = $_GET['file'];

// Validar token
if (!validateImageToken($token, $filename)) {
    http_response_code(403);
    die('Token inválido o expirado');
}

// Directorio de imágenes protegidas
$uploadDir = './trip_images/';
$safePath = realpath($uploadDir . basename($filename));
$uploadDirReal = realpath($uploadDir);

// Verificar que el archivo existe y está en el directorio correcto (prevenir directory traversal)
if (!$safePath || !$uploadDirReal || strpos($safePath, $uploadDirReal) !== 0) {
    http_response_code(404);
    die('Archivo no encontrado');
}

if (!file_exists($safePath)) {
    http_response_code(404);
    die('Archivo no encontrado en el servidor');
}

// Verificar que es una imagen válida
$imageInfo = getimagesize($safePath);
if (!$imageInfo) {
    http_response_code(400);
    die('Archivo corrupto o no es una imagen');
}

// Servir la imagen con headers apropiados
$mimeType = $imageInfo['mime'];
$fileSize = filesize($safePath);

header("Content-Type: $mimeType");
header("Content-Length: $fileSize");
header("Cache-Control: private, max-age=86400"); // Cache por 24 horas
header("Expires: " . gmdate('D, d M Y H:i:s', time() + 86400) . ' GMT');

// Headers adicionales de seguridad
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");

// Log de acceso
error_log("ReaderKM: Acceso a imagen - Archivo: $filename, IP: " . $_SERVER['REMOTE_ADDR']);

// Servir archivo
readfile($safePath);

function validateImageToken($token, $filename) {
    try {
        $tokenData = base64_decode($token);
        $parts = explode('|', $tokenData);
        
        if (count($parts) !== 4) {
            return false;
        }
        
        $email = $parts[0];
        $timestamp = $parts[1];
        $expiration = $parts[2];
        $hash = $parts[3];
        
        // Verificar expiración
        if (time() > $expiration) {
            return false;
        }
        
        // Verificar hash
        $expectedHash = hash('sha256', $email . $filename . $timestamp . $expiration . 'readerkm_secret_2025');
        return hash_equals($expectedHash, $hash);
        
    } catch (Exception $e) {
        return false;
    }
}
?>