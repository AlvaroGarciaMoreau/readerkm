<?php
// Archivo para agregar la columna consumptionUnit a la base de datos

$servername = "db5018344716.hosting-data.io";
$username = "dbu932428";
$password = "1973Rosowo_1";
$dbname = "dbs14526327";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Agregar columna consumptionUnit si no existe
    $sql = "ALTER TABLE viajes ADD COLUMN consumptionUnit VARCHAR(20) DEFAULT 'L/100km'";
    $pdo->exec($sql);
    
    echo "Columna consumptionUnit agregada exitosamente";
    
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column') !== false) {
        echo "La columna consumptionUnit ya existe";
    } else {
        echo "Error: " . $e->getMessage();
    }
}
?>