<?php
/**
 * Upload JSON Data Endpoint
 * Processes and uploads data from OOUTH Salary API to database
 */

// Start output buffering
ob_start();

// Start session if not already started
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!isset($_SESSION['SESS_MEMBER_ID']) || (trim($_SESSION['SESS_MEMBER_ID']) == '')) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

// Set headers
header('Content-Type: application/json');

// Database connection
require_once(__DIR__ . '/../Connections/coop.php');

try {
    // Get JSON input
    $input = file_get_contents('php://input');
    $request = json_decode($input, true);
    
    if (!$request) {
        throw new Exception('Invalid JSON data');
    }
    
    // Validate required fields
    if (!isset($request['period']) || !isset($request['data']) || !is_array($request['data'])) {
        throw new Exception('Missing required fields: period and data');
    }
    
    $periodId = $request['period'];
    $periodInfo = $request['period_info'] ?? null;
    $resourceType = $request['resource_type'] ?? 'deduction';
    $resourceId = $request['resource_id'] ?? null;
    $resourceName = $request['resource_name'] ?? 'Unknown';
    $data = $request['data'];
    
    if (empty($data)) {
        throw new Exception('No data to upload');
    }
    
    // Select database
    mysqli_select_db($coop, $database);
    
    // Start transaction
    mysqli_begin_transaction($coop);
    
    $successCount = 0;
    $errorCount = 0;
    $errors = [];
    
    // Determine which table to update based on resource type
    // This is a simplified example - adjust based on your actual database schema
    $tableName = ($resourceType === 'allowance') ? 'tblallowances' : 'tbldeductions';
    $fieldName = ($resourceType === 'allowance') ? 'AllowanceAmount' : 'DeductionAmount';
    
    // Process each record
    foreach ($data as $record) {
        $staffId = mysqli_real_escape_string($coop, $record['staff_id']);
        $name = mysqli_real_escape_string($coop, $record['name']);
        $amount = floatval($record['amount']);
        
        // Check if record exists for this staff and period
        $checkQuery = "SELECT * FROM {$tableName} 
                      WHERE CoopID = '{$staffId}' 
                      AND Period = {$periodId} 
                      AND " . ($resourceType === 'allowance' ? "AllowanceID" : "DeductionID") . " = '{$resourceId}'";
        
        $checkResult = mysqli_query($coop, $checkQuery);
        
        if ($checkResult && mysqli_num_rows($checkResult) > 0) {
            // Update existing record
            $updateQuery = "UPDATE {$tableName} 
                           SET {$fieldName} = {$amount},
                               UpdatedAt = NOW(),
                               UpdatedBy = '{$_SESSION['SESS_MEMBER_ID']}',
                               Source = 'API'
                           WHERE CoopID = '{$staffId}' 
                           AND Period = {$periodId}
                           AND " . ($resourceType === 'allowance' ? "AllowanceID" : "DeductionID") . " = '{$resourceId}'";
            
            if (mysqli_query($coop, $updateQuery)) {
                $successCount++;
            } else {
                $errorCount++;
                $errors[] = "Failed to update {$staffId}: " . mysqli_error($coop);
            }
        } else {
            // Insert new record
            $insertQuery = "INSERT INTO {$tableName} 
                           (CoopID, 
                            Period, 
                            " . ($resourceType === 'allowance' ? "AllowanceID" : "DeductionID") . ",
                            {$fieldName},
                            CreatedAt,
                            CreatedBy,
                            Source)
                           VALUES 
                           ('{$staffId}',
                            {$periodId},
                            '{$resourceId}',
                            {$amount},
                            NOW(),
                            '{$_SESSION['SESS_MEMBER_ID']}',
                            'API')";
            
            if (mysqli_query($coop, $insertQuery)) {
                $successCount++;
            } else {
                $errorCount++;
                $errors[] = "Failed to insert {$staffId}: " . mysqli_error($coop);
            }
        }
    }
    
    // Commit transaction if most records were successful
    if ($successCount > 0 && $errorCount < ($successCount / 2)) {
        mysqli_commit($coop);
        
        // Log the upload activity
        $logQuery = "INSERT INTO tblapi_upload_log 
                    (Period, ResourceType, ResourceID, ResourceName, 
                     RecordsProcessed, RecordsSuccess, RecordsError, 
                     UploadedBy, UploadedAt, Source)
                    VALUES 
                    ({$periodId}, '{$resourceType}', '{$resourceId}', '{$resourceName}',
                     " . count($data) . ", {$successCount}, {$errorCount},
                     '{$_SESSION['SESS_MEMBER_ID']}', NOW(), 'API')";
        mysqli_query($coop, $logQuery); // Non-critical, ignore if fails
        
        echo json_encode([
            'success' => true,
            'message' => "Upload completed: {$successCount} records processed successfully",
            'details' => "{$successCount} succeeded, {$errorCount} failed",
            'data' => [
                'total' => count($data),
                'success' => $successCount,
                'errors' => $errorCount,
                'error_messages' => $errors
            ]
        ]);
    } else {
        // Rollback if too many errors
        mysqli_rollback($coop);
        throw new Exception("Upload failed: Too many errors ({$errorCount} errors out of " . count($data) . " records). Transaction rolled back.");
    }
    
} catch (Exception $e) {
    // Rollback transaction on error
    if (isset($coop)) {
        mysqli_rollback($coop);
    }
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'error' => $e->getMessage()
    ]);
}

// Close database connection
if (isset($coop)) {
    mysqli_close($coop);
}

ob_end_flush();

