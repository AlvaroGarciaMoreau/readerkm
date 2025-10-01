<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Log para debugging
error_log("Iniciando guardar_viaje_with_images.php");

// IMPORTANTE: Cambia estos datos por los de TU base de datos
$servername = "db5018344716.hosting-data.io";           // O tu servidor de BD
$username = "dbu932428";        // Reemplaza con tu usuario real
$password = "1973Rosowo_1";       // Reemplaza con tu password real  
$dbname = "dbs14526327";          // Reemplaza con tu base de datos real    

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    error_log("Conexión a BD exitosa");
} catch (PDOException $e) {
    error_log("Error de conexión: " . $e->getMessage());
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
error_log("Datos recibidos: " . json_encode($input));

if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("Error JSON: " . json_last_error_msg());
    http_response_code(400);
    echo json_encode(['error' => 'JSON inválido: ' . json_last_error_msg()]);
    exit;
}

// Validar datos requeridos (sin consumptionUnit ya que no existe en BD)
$required_fields = ['email', 'distance', 'consumption', 'fuelPrice', 'totalCost', 'litersPer100Km'];
foreach ($required_fields as $field) {
    if (!isset($input[$field])) {
        error_log("Campo faltante: $field");
        http_response_code(400);
        echo json_encode(['error' => "Campo requerido: $field"]);
        exit;
    }
}

try {
    // Verificar si la tabla tiene las columnas de imagen
    $checkColumns = $pdo->query("DESCRIBE viajes");
    $columns = $checkColumns->fetchAll(PDO::FETCH_COLUMN);
    $hasImageColumns = in_array('image_url', $columns) && in_array('image_filename', $columns);
    
    if (!$hasImageColumns) {
        error_log("Columnas de imagen no existen, usando consulta sin imágenes");
        // Si no existen las columnas de imagen, usar consulta sin ellas
        $sql = "INSERT INTO viajes (
            email, 
            distance, 
            consumption, 
            fuelPrice, 
            totalCost, 
            litersPer100Km, 
            travelTime, 
            totalKm, 
            fecha
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())";        
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $input['email'],
            $input['distance'],
            $input['consumption'],
            $input['fuelPrice'],
            $input['totalCost'],
            $input['litersPer100Km'],
            $input['travelTime'] ?? null,
            $input['totalKm'] ?? null
        ]);
    } else {
        error_log("Columnas de imagen existen, usando consulta completa");
        // Si existen las columnas de imagen, usar consulta completa
        $sql = "INSERT INTO viajes (
            email, 
            distance, 
            consumption, 
            fuelPrice, 
            totalCost, 
            litersPer100Km, 
            travelTime, 
            totalKm, 
            fecha,
            image_url,
            image_filename
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?)";        
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $input['email'],
            $input['distance'],
            $input['consumption'],
            $input['fuelPrice'],
            $input['totalCost'],
            $input['litersPer100Km'],
            $input['travelTime'] ?? null,
            $input['totalKm'] ?? null,
            $input['imageUrl'] ?? null,      
            $input['imageFilename'] ?? null  
        ]);
    }
    
    $tripId = $pdo->lastInsertId();
    error_log("Viaje guardado con ID: $tripId");
    
    echo json_encode([
        'success' => true,
        'id' => $tripId,
        'message' => 'Viaje guardado correctamente'
    ]);
    
} catch (PDOException $e) {
    error_log("Error SQL: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Error al guardar: ' . $e->getMessage()]);
}
?>