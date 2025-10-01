<?php
// Script para verificar la estructura de la base de datos
header('Content-Type: text/html; charset=utf-8');

echo "<h2>Verificación de Base de Datos - ReaderKM</h2>";

// IMPORTANTE: Cambia estos datos por los de TU base de datos
$servername = "db5018344716.hosting-data.io";           // O tu servidor de BD
$username = "dbu932428";        // Reemplaza con tu usuario real
$password = "1973Rosowo_1";       // Reemplaza con tu password real  
$dbname = "dbs14526327";         // Reemplaza con tu base de datos real    

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<p style='color: green;'>✅ Conexión a base de datos exitosa</p>";
    
    // Verificar estructura de la tabla viajes
    echo "<h3>Estructura de la tabla 'viajes':</h3>";
    $stmt = $pdo->query("DESCRIBE viajes");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table border='1' style='border-collapse: collapse;'>";
    echo "<tr><th>Campo</th><th>Tipo</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    
    $hasImageUrl = false;
    $hasImageFilename = false;
    
    foreach ($columns as $column) {
        echo "<tr>";
        echo "<td>" . $column['Field'] . "</td>";
        echo "<td>" . $column['Type'] . "</td>";
        echo "<td>" . $column['Null'] . "</td>";
        echo "<td>" . $column['Key'] . "</td>";
        echo "<td>" . $column['Default'] . "</td>";
        echo "<td>" . $column['Extra'] . "</td>";
        echo "</tr>";
        
        if ($column['Field'] === 'image_url') $hasImageUrl = true;
        if ($column['Field'] === 'image_filename') $hasImageFilename = true;
    }
    echo "</table>";
    
    echo "<h3>Estado de columnas de imagen:</h3>";
    if ($hasImageUrl) {
        echo "<p style='color: green;'>✅ Columna 'image_url' existe</p>";
    } else {
        echo "<p style='color: red;'>❌ Columna 'image_url' NO existe</p>";
        echo "<p><strong>SQL para crear:</strong> <code>ALTER TABLE viajes ADD COLUMN image_url VARCHAR(500) DEFAULT NULL;</code></p>";
    }
    
    if ($hasImageFilename) {
        echo "<p style='color: green;'>✅ Columna 'image_filename' existe</p>";
    } else {
        echo "<p style='color: red;'>❌ Columna 'image_filename' NO existe</p>";
        echo "<p><strong>SQL para crear:</strong> <code>ALTER TABLE viajes ADD COLUMN image_filename VARCHAR(255) DEFAULT NULL;</code></p>";
    }
    
    // Contar registros
    $count = $pdo->query("SELECT COUNT(*) FROM viajes")->fetchColumn();
    echo "<h3>Total de viajes en la base de datos: $count</h3>";
    
    // Mostrar últimos 5 registros
    if ($count > 0) {
        echo "<h3>Últimos 5 viajes:</h3>";
        $stmt = $pdo->query("SELECT * FROM viajes ORDER BY fecha DESC LIMIT 5");
        $lastTrips = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "<table border='1' style='border-collapse: collapse;'>";
        if (!empty($lastTrips)) {
            // Headers
            echo "<tr>";
            foreach (array_keys($lastTrips[0]) as $key) {
                echo "<th>$key</th>";
            }
            echo "</tr>";
            
            // Data
            foreach ($lastTrips as $trip) {
                echo "<tr>";
                foreach ($trip as $value) {
                    echo "<td>" . htmlspecialchars($value) . "</td>";
                }
                echo "</tr>";
            }
        }
        echo "</table>";
    }
    
} catch (PDOException $e) {
    echo "<p style='color: red;'>❌ Error de conexión: " . $e->getMessage() . "</p>";
}
?>