<?php
/**
 * Staff Search Endpoint
 * Provides autocomplete data for staff search
 */

// Start output buffering to prevent header issues
ob_start();

require_once('Connections/coop.php');

// Get search term
$term = $_GET['term'] ?? '';

if (empty($term)) {
    header('Content-Type: application/json');
    echo json_encode([]);
    exit();
}

// Escape search term
$term = mysqli_real_escape_string($coop, $term);

// Query to get search suggestions
mysqli_select_db($coop, $database);
$query = "SELECT
    tblemployees.CoopID, 
    CONCAT(tblemployees.FirstName, ' ', tblemployees.MiddleName, ' ', tblemployees.LastName) AS FullName, 
    tblemployees.FirstName,
    tblemployees.MiddleName,
    tblemployees.LastName,
    IFNULL(tblaccountno.Bank,'') AS Bank, 
    IFNULL(tblaccountno.AccountNo,'') AS AccountNo, 
    IFNULL(tblbankcode.BankCode,'') AS BankCode
FROM
    tblemployees
    LEFT JOIN tblaccountno ON tblaccountno.COOPNO = tblemployees.CoopID
    LEFT JOIN tblbankcode ON tblaccountno.Bank = tblbankcode.bank
WHERE (tblemployees.CoopID LIKE '%$term%' 
    OR tblemployees.LastName LIKE '%$term%' 
    OR tblemployees.FirstName LIKE '%$term%' 
    OR tblemployees.MiddleName LIKE '%$term%')
    AND tblemployees.Status = 'Active'
LIMIT 10";

$result = mysqli_query($coop, $query);

$suggestions = [];
while ($row = mysqli_fetch_assoc($result)) {
    // Handle null values from CONCAT function
    $fullName = trim($row['FullName'] ?? '');
    $firstName = $row['FirstName'] ?? '';
    $middleName = $row['MiddleName'] ?? '';
    $lastName = $row['LastName'] ?? '';
    
    $suggestions[] = [
        'id' => $row['CoopID'],
        'coop_id' => $row['CoopID'],
        'full_name' => $fullName,
        'first_name' => $firstName,
        'middle_name' => $middleName,
        'last_name' => $lastName,
        'label' => $fullName . ' - ' . $row['CoopID'],
        'value' => $row['CoopID'],
        'bank' => $row['Bank'] ?? '',
        'account_no' => $row['AccountNo'] ?? '',
        'bank_code' => $row['BankCode'] ?? ''
    ];
}

// Return suggestions as JSON
header('Content-Type: application/json');
echo json_encode($suggestions);

// Clean output buffer
ob_end_flush();
?>