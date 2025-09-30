<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Verificar que se proporcionen los parámetros necesarios
if (!isset($_GET['token']) || !isset($_GET['file'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Token y archivo requeridos']);
    exit;
}

$token = $_GET['token'];
$filename = $_GET['file'];

// Validar el nombre del archivo para evitar ataques de path traversal
if (strpos($filename, '..') !== false || strpos($filename, '/') !== false || strpos($filename, '\\') !== false) {
    http_response_code(400);
    echo json_encode(['error' => 'Nombre de archivo inválido']);
    exit;
}

// Construir la ruta del archivo
$filePath = 'trip_images/' . $filename;

// Verificar que el archivo existe
if (!file_exists($filePath)) {
    http_response_code(404);
    echo json_encode(['error' => 'Archivo no encontrado']);
    exit;
}

// Verificar token (por ahora simple verificación de longitud)
if (strlen($token) < 32) {
    http_response_code(401);
    echo json_encode(['error' => 'Token inválido']);
    exit;
}

// Determinar el tipo MIME
$fileExtension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
switch ($fileExtension) {
    case 'jpg':
    case 'jpeg':
        $mimeType = 'image/jpeg';
        break;
    case 'png':
        $mimeType = 'image/png';
        break;
    default:
        $mimeType = 'application/octet-stream';
}

// Configurar headers para servir la imagen
header('Content-Type: ' . $mimeType);
header('Content-Length: ' . filesize($filePath));
header('Cache-Control: public, max-age=86400'); // Cache por 1 día
header('Content-Disposition: inline; filename="' . basename($filename) . '"');

// Servir el archivo
readfile($filePath);
?>