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

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['filename']) || !isset($input['email'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Faltan parámetros: filename y email requeridos']);
    exit;
}

$filename = $input['filename'];
$email = $input['email'];

// Directorio de imágenes protegidas
$uploadDir = './trip_images/';
$filePath = $uploadDir . basename($filename);

// Verificar que el archivo existe
if (!file_exists($filePath)) {
    echo json_encode(['success' => false, 'error' => 'Archivo no encontrado']);
    exit;
}

// Verificar que el usuario tiene permisos (el nombre del archivo debe contener el hash del email)
$secureHash = hash('sha256', $email . 'readerkm_secret_2025');
if (strpos($filename, substr($secureHash, 0, 16)) === false) {
    http_response_code(403);
    echo json_encode(['error' => 'No tienes permisos para eliminar este archivo']);
    exit;
}

// Eliminar archivo
if (unlink($filePath)) {
    // Log de eliminación
    error_log("ReaderKM: Imagen eliminada - Email: $email, Archivo: $filename");
    
    echo json_encode([
        'success' => true,
        'message' => 'Archivo eliminado correctamente',
        'filename' => $filename
    ]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Error al eliminar el archivo del servidor']);
}
?>