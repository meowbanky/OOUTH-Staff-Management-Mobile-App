<?php
header('Content-Type: application/json');

// Load environment configuration
require_once __DIR__ . '/../config/EnvConfig.php';

// ==========================================
// 1. CONFIGURATION
// ==========================================

// Get API Secret from environment configuration
$API_SECRET = EnvConfig::getAPISecret();

// Validate API secret is configured
if (empty($API_SECRET)) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "API_SECRET not configured in config.env"]);
    exit;
}

// DATABASE CREDENTIALS from environment configuration
$dbConfig = EnvConfig::getDatabaseConfig();
$host = $dbConfig['host'];
$db   = $dbConfig['name'];
$user = $dbConfig['user'];
$pass = $dbConfig['password'];
$charset = 'utf8mb4';

// ==========================================
// 2. AUTHENTICATION & CONNECTION
// ==========================================

// Check for API Key
$headers = getallheaders();
$authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : '';

// Allow passing key via GET parameter for easy testing (optional)
if(!$authHeader && isset($_GET['apikey'])) {
    $authHeader = "Bearer " . $_GET['apikey'];
}

if (strpos($authHeader, $API_SECRET) === false) {
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Unauthorized"]);
    exit;
}

// Connect to Database
$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database Connection Failed"]);
    exit;
}

// ==========================================
// 3. ROUTING LOGIC
// ==========================================

$action = $_GET['action'] ?? '';

switch ($action) {
    case 'check_user':
        checkUser($pdo);
        break;

    case 'get_balances':
        getBalances($pdo);
        break;

    default:
        echo json_encode(["status" => "error", "message" => "Invalid action"]);
        break;
}

// ==========================================
// 4. FUNCTIONS
// ==========================================

function checkUser($pdo) {
    // Input: Phone number
    $phone = $_GET['phone'] ?? '';
    
    // Basic sanitization
    $phone = preg_replace('/[^0-9]/', '', $phone); 

    // We check specifically for the phone number
    // Note: n8n usually sends WhatsApp numbers with country code (e.g. 23480...)
    // You might need to adjust the LIKE query if your DB stores '080...'
    
    // Trying exact match first, then checking if DB stores it without country code
    $stmt = $pdo->prepare("SELECT memberid, Fname, Lname, MobilePhone FROM tbl_personalinfo WHERE MobilePhone LIKE ? LIMIT 1");
    
    // We try to match the last 10 digits to be safe (handles 080 vs 23480 issues)
    $searchPhone = "%" . substr($phone, -10); 
    
    $stmt->execute([$searchPhone]);
    $user = $stmt->fetch();

    if ($user) {
        echo json_encode([
            "status" => "success",
            "member_id" => $user['memberid'],
            "name" => $user['Fname'] . " " . $user['Lname'],
            "phone_matched" => $user['MobilePhone']
        ]);
    } else {
        echo json_encode([
            "status" => "error", 
            "message" => "Member not found"
        ]);
    }
}

function getBalances($pdo) {
    $memberId = $_GET['member_id'] ?? 0;

    if (!$memberId) {
        echo json_encode(["status" => "error", "message" => "Member ID required"]);
        return;
    }

    // Updated SQL to include interest columns
    $sql = "SELECT 
                SUM(savings) as total_savings_in,
                SUM(withdrawal_savings) as total_savings_out,
                SUM(shares) as total_shares_in,
                SUM(withdrawal_shares) as total_shares_out,
                SUM(loanAmount) as total_loan_taken,
                SUM(loanRepayment) as total_loan_repaid,
                SUM(interest) as total_interest_charged,
                SUM(interestPaid) as total_interest_paid
            FROM tlb_mastertransaction 
            WHERE memberid = ?";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$memberId]);
    $result = $stmt->fetch();

    // Calculations
    $savings_bal  = ($result['total_savings_in'] ?? 0) - ($result['total_savings_out'] ?? 0);
    $shares_bal   = ($result['total_shares_in'] ?? 0) - ($result['total_shares_out'] ?? 0);
    
    // Loan Principal Balance
    $loan_bal     = ($result['total_loan_taken'] ?? 0) - ($result['total_loan_repaid'] ?? 0);
    
    // Outstanding Interest Balance
    $interest_bal = ($result['total_interest_charged'] ?? 0) - ($result['total_interest_paid'] ?? 0);

    // Safety checks (optional: keeps balances from looking weird if data is inconsistent)
    if($loan_bal < 0) $loan_bal = 0;
    if($interest_bal < 0) $interest_bal = 0;

    echo json_encode([
        "status" => "success",
        "data" => [
            "savings_balance" => number_format($savings_bal, 2),
            "shares_balance" => number_format($shares_bal, 2),
            "loan_balance" => number_format($loan_bal, 2),
            "interest_balance" => number_format($interest_bal, 2),
            "currency" => "NGN"
        ]
    ]);
}
?>