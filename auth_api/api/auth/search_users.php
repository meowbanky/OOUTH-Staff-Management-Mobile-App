<?php
// Set CORS headers FIRST - before any output
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Max-Age: 1728000');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Set content type
header('Content-Type: application/json; charset=UTF-8');

// Error handling
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

try {
    $query = $_GET['query'] ?? '';
    
    if (empty($query)) {
        throw new Exception('Search query is required');
    }
    
    if (strlen($query) < 2) {
        throw new Exception('Search query must be at least 2 characters');
    }

    // Try to use Database class, fallback to direct connection
    $db = null;
    try {
        require_once __DIR__ . '/../../config/Database.php';
        $database = new Database();
        $db = $database->getConnection();
    } catch (Exception $dbError) {
        // Fallback to direct connection using existing coop connection
        require_once __DIR__ . '/../../../../Connections/coop.php';
        if (isset($coop)) {
            // Convert mysqli to PDO if needed, or use mysqli
            $db = $coop;
        } else {
            throw new Exception('Database connection failed');
        }
    }

    // Use PDO if available, otherwise use mysqli
    if ($db instanceof PDO) {
        $sql = "SELECT CoopID, FirstName, LastName, EmailAddress 
                FROM tblemployees 
                WHERE CONCAT(FirstName, ' ', LastName) LIKE :query AND Status = 'Active'
                LIMIT 10";

        $stmt = $db->prepare($sql);
        $searchQuery = "%$query%";
        $stmt->bindParam(':query', $searchQuery);
        $stmt->execute();
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } else {
        // Use mysqli
        $searchQuery = "%$query%";
        $sql = "SELECT CoopID, FirstName, LastName, EmailAddress 
                FROM tblemployees 
                WHERE CONCAT(FirstName, ' ', LastName) LIKE ? AND Status = 'Active'
                LIMIT 10";
        
        $stmt = mysqli_prepare($db, $sql);
        if (!$stmt) {
            throw new Exception('Database query preparation failed: ' . mysqli_error($db));
        }
        
        mysqli_stmt_bind_param($stmt, "s", $searchQuery);
        mysqli_stmt_execute($stmt);
        $result = mysqli_stmt_get_result($stmt);
        
        $results = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $results[] = $row;
        }
        mysqli_stmt_close($stmt);
    }

    echo json_encode([
        'success' => true,
        'data' => $results
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'error' => error_get_last()
    ], JSON_UNESCAPED_UNICODE);
}