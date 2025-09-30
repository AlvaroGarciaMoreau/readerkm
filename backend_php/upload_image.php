<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
    exit;
}

// Verificar que se recibió un archivo
if (!isset($_FILES['image'])) {
    http_response_code(400);
    echo json_encode(['error' => 'No se recibió ninguna imagen']);
    exit;
}

// Directorio de subida protegido (fuera del DocumentRoot público)
$uploadDir = '../fotos_privadas/trip_images/';

// Crear directorio si no existe
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0700, true); // Solo el propietario puede leer/escribir
}

$file = $_FILES['image'];
$email = $_POST['email'] ?? 'unknown';

// Validar archivo
$allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
if (!in_array($file['type'], $allowedTypes)) {
    http_response_code(400);
    echo json_encode(['error' => 'Tipo de archivo no permitido. Solo JPEG y PNG.']);
    exit;
}

// Límite de tamaño (5MB)
if ($file['size'] > 5 * 1024 * 1024) {
    http_response_code(400);
    echo json_encode(['error' => 'Archivo muy grande. Máximo 5MB.']);
    exit;
}

// Validar que sea realmente una imagen
$imageInfo = getimagesize($file['tmp_name']);
if (!$imageInfo) {
    http_response_code(400);
    echo json_encode(['error' => 'El archivo no es una imagen válida']);
    exit;
}

// Generar nombre único y seguro
$timestamp = time();
$extension = pathinfo($file['name'], PATHINFO_EXTENSION);
$secureHash = hash('sha256', $email . $timestamp . 'readerkm_secret_2025');
$fileName = "trip_{$timestamp}_{$secureHash}.{$extension}";
$filePath = $uploadDir . $fileName;

// Mover archivo
if (move_uploaded_file($file['tmp_name'], $filePath)) {
    // Generar token de acceso con expiración de 30 días
    $accessToken = generateImageToken($email, $fileName);
    
    // Log de subida exitosa
    error_log("ReaderKM: Imagen subida - Email: $email, Archivo: $fileName, Tamaño: " . formatBytes($file['size']));
    
    echo json_encode([
        'success' => true,
        'filename' => $fileName,
        'url' => "https://www.moreausoft.com/ReaderKM/fotos/secure_image.php?token={$accessToken}&file={$fileName}",
        'access_token' => $accessToken,
        'size' => $file['size'],
        'timestamp' => $timestamp
    ]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Error al guardar archivo en el servidor']);
}

function generateImageToken($email, $filename) {
    $timestamp = time();
    $expiration = $timestamp + (30 * 24 * 60 * 60); // 30 días
    $hash = hash('sha256', $email . $filename . $timestamp . $expiration . 'readerkm_secret_2025');
    $tokenData = base64_encode($email . '|' . $timestamp . '|' . $expiration . '|' . $hash);
    return $tokenData;
}

function formatBytes($size, $precision = 2) {
    $units = array('B', 'KB', 'MB', 'GB', 'TB');
    
    for ($i = 0; $size > 1024 && $i < count($units) - 1; $i++) {
        $size /= 1024;
    }
    
    return round($size, $precision) . ' ' . $units[$i];
}
?>