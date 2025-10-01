<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Log para debugging - SOLO PARA DEBUG
error_log("=== DEBUG GUARDAR VIAJE ===");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
    exit;
}

// Obtener datos RAW
$raw_input = file_get_contents('php://input');
error_log("Datos RAW recibidos: " . $raw_input);

$input = json_decode($raw_input, true);
error_log("Datos JSON decodificados: " . json_encode($input));

if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("Error JSON: " . json_last_error_msg());
    http_response_code(400);
    echo json_encode(['error' => 'JSON inválido: ' . json_last_error_msg()]);
    exit;
}

// Mostrar estructura de datos
echo json_encode([
    'debug' => true,
    'received_data' => $input,
    'available_fields' => array_keys($input ?? []),
    'message' => 'Datos recibidos correctamente'
]);
?>