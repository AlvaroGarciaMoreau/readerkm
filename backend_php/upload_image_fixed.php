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

// Verificar que se haya subido un archivo
if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['error' => 'Error al subir la imagen']);
    exit;
}

// Verificar que se haya proporcionado el email
if (!isset($_POST['email']) || empty($_POST['email'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Email requerido']);
    exit;
}

$email = $_POST['email'];
$uploadedFile = $_FILES['image'];

// Validar tipo de archivo - CORREGIDO PARA ACEPTAR JPG Y JPEG
$allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
$fileType = $uploadedFile['type'];

// También verificar la extensión del archivo como respaldo
$fileExtension = strtolower(pathinfo($uploadedFile['name'], PATHINFO_EXTENSION));
$allowedExtensions = ['jpg', 'jpeg', 'png'];

if (!in_array($fileType, $allowedTypes) && !in_array($fileExtension, $allowedExtensions)) {
    http_response_code(400);
    echo json_encode(['error' => 'Tipo de archivo no permitido. Solo JPEG y PNG.']);
    exit;
}

// Validar tamaño de archivo (máximo 10MB)
if ($uploadedFile['size'] > 10 * 1024 * 1024) {
    http_response_code(400);
    echo json_encode(['error' => 'Archivo demasiado grande. Máximo 10MB.']);
    exit;
}

// Crear directorio si no existe
$uploadDir = 'trip_images/';
if (!file_exists($uploadDir)) {
    if (!mkdir($uploadDir, 0755, true)) {
        http_response_code(500);
        echo json_encode(['error' => 'Error al crear directorio']);
        exit;
    }
}

// Generar nombre único para el archivo
$fileExtension = pathinfo($uploadedFile['name'], PATHINFO_EXTENSION);
$fileName = uniqid() . '.' . $fileExtension;
$filePath = $uploadDir . $fileName;

// Mover archivo a destino final
if (!move_uploaded_file($uploadedFile['tmp_name'], $filePath)) {
    http_response_code(500);
    echo json_encode(['error' => 'Error al guardar imagen']);
    exit;
}

// Generar token para acceso a la imagen
$token = bin2hex(random_bytes(32));
$expiryTime = time() + (30 * 24 * 60 * 60); // 30 días

// Respuesta exitosa
echo json_encode([
    'success' => true,
    'filename' => $fileName,
    'token' => $token,
    'expires' => $expiryTime,
    'url' => 'secure_image.php?token=' . $token . '&file=' . urlencode($fileName)
]);
?>