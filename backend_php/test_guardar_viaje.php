<?php
// Script de prueba para verificar el guardado de viajes
header('Content-Type: text/html; charset=utf-8');

echo "<h2>Test de guardar_viaje_with_images.php</h2>";

// Datos de prueba
$testData = [
    'email' => 'test@example.com',
    'distance' => 100.5,
    'consumption' => 7.2,
    'consumptionUnit' => 'L/100km',
    'fuelPrice' => 1.45,
    'totalCost' => 10.44,
    'litersPer100Km' => 7.2,
    'travelTime' => '1:30',
    'totalKm' => 15000,
    'imageUrl' => 'https://example.com/image.jpg',
    'imageFilename' => 'test_image.jpg'
];

echo "<h3>Datos de prueba:</h3>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

// Realizar petición POST
$url = 'https://TU_DOMINIO.com/ReaderKM/fotos/guardar_viaje_with_images.php'; // CAMBIAR POR TU URL
$postData = json_encode($testData);

$context = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($postData)
        ],
        'content' => $postData
    ]
]);

echo "<h3>Enviando petición a: $url</h3>";

$result = file_get_contents($url, false, $context);
$httpCode = $http_response_header[0];

echo "<h3>Respuesta HTTP:</h3>";
echo "<p><strong>Código:</strong> $httpCode</p>";
echo "<p><strong>Respuesta:</strong></p>";
echo "<pre>$result</pre>";

// Verificar si la respuesta es JSON válido
$jsonResponse = json_decode($result, true);
if (json_last_error() === JSON_ERROR_NONE) {
    echo "<h3>JSON parseado correctamente:</h3>";
    echo "<pre>" . json_encode($jsonResponse, JSON_PRETTY_PRINT) . "</pre>";
    
    if (isset($jsonResponse['success']) && $jsonResponse['success'] === true) {
        echo "<p style='color: green;'><strong>✅ ÉXITO: Viaje guardado correctamente</strong></p>";
        if (isset($jsonResponse['id'])) {
            echo "<p>ID del viaje: " . $jsonResponse['id'] . "</p>";
        }
    } else {
        echo "<p style='color: red;'><strong>❌ ERROR: </strong>" . ($jsonResponse['error'] ?? 'Error desconocido') . "</p>";
    }
} else {
    echo "<p style='color: red;'><strong>❌ ERROR: Respuesta no es JSON válido</strong></p>";
}
?>