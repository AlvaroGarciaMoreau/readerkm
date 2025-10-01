<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// IMPORTANTE: Cambia estos datos por los de TU base de datos
$servername = "db5018344716.hosting-data.io";           // O tu servidor de BD
$username = "dbu932428";        // Reemplaza con tu usuario real
$password = "1973Rosowo_1";       // Reemplaza con tu password real  
$dbname = "dbs14526327";          // Reemplaza con tu base de datos real    

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Error de conexión: ' . $e->getMessage()]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['email']) || empty($input['email'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Email requerido']);
    exit;
}

try {
    // CONSULTA ACTUALIZADA - Usando nombres reales de columnas (camelCase)
    $sql = "SELECT 
        id,
        distance,
        consumption,
        fuelPrice,
        totalCost,
        litersPer100Km,
        travelTime,
        totalKm,
        fecha as date,
        image_url as imageUrl,
        image_filename as imageFilename
    FROM viajes 
    WHERE email = ? 
    ORDER BY fecha DESC";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$input['email']]);
    
    $viajes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Convertir fecha a timestamp para Flutter
    foreach ($viajes as &$viaje) {
        if (isset($viaje['date'])) {
            $viaje['date'] = strtotime($viaje['date']) * 1000; // Convertir a milliseconds
        }
    }
    
    echo json_encode([
        'success' => true,
        'viajes' => $viajes
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Error al obtener viajes: ' . $e->getMessage()]);
}
?>