<?php
/**
 * Test API Signature Generation
 * Verifies that signature is generated correctly according to OOUTH API spec
 */

require_once('config/api_config.php');

echo "=================================================\n";
echo "🔐 OOUTH API Signature Generation Test\n";
echo "=================================================\n\n";

// Configuration
$apiKey = OOUTH_API_KEY;
$apiSecret = OOUTH_API_SECRET;

echo "📋 Configuration:\n";
echo "   API Key: " . $apiKey . "\n";
echo "   Secret Length: " . strlen($apiSecret) . " characters\n";
echo "   Secret (first 8 chars): " . substr($apiSecret, 0, 8) . "...\n\n";

// Step 1: Get current timestamp
$timestamp = time();
echo "⏰ Step 1: Get Timestamp\n";
echo "   Timestamp: " . $timestamp . "\n";
echo "   Human Date: " . date('Y-m-d H:i:s', $timestamp) . " UTC\n\n";

// Step 2: Build signature string
$signatureString = $apiKey . $timestamp;
echo "🔨 Step 2: Build Signature String\n";
echo "   Formula: API_KEY + TIMESTAMP (no spaces)\n";
echo "   Result: " . $signatureString . "\n";
echo "   Length: " . strlen($signatureString) . " characters\n\n";

// Step 3: Calculate HMAC-SHA256
$signature = hash_hmac('sha256', $signatureString, $apiSecret);
echo "🔐 Step 3: Calculate HMAC-SHA256\n";
echo "   Algorithm: HMAC-SHA256\n";
echo "   Key: API Secret (64 chars)\n";
echo "   Message: " . $signatureString . "\n";
echo "   Signature: " . $signature . "\n";
echo "   Signature Length: " . strlen($signature) . " characters\n\n";

// Verify signature format
echo "✅ Step 4: Verify Signature Format\n";
$isValidFormat = preg_match('/^[a-f0-9]{64}$/', $signature);
if ($isValidFormat) {
    echo "   ✓ Signature format is valid (64 hex characters)\n";
} else {
    echo "   ✗ ERROR: Invalid signature format!\n";
}
echo "\n";

// Headers that will be sent
echo "📤 Step 5: Request Headers\n";
echo "   X-API-Key: " . $apiKey . "\n";
echo "   X-Timestamp: " . $timestamp . "\n";
echo "   X-Signature: " . $signature . "\n\n";

// Test with actual API
echo "=================================================\n";
echo "🌐 Testing with Real API...\n";
echo "=================================================\n\n";

require_once('classes/OOUTHSalaryAPIClient.php');

$client = new OOUTHSalaryAPIClient();

echo "Attempting authentication...\n\n";

if ($client->authenticate()) {
    echo "✅ SUCCESS! Authentication worked!\n";
    echo "   The signature generation is correct.\n";
} else {
    echo "❌ FAILED! Authentication failed.\n";
    echo "   Check the error log for details.\n";
    echo "\n";
    echo "💡 Troubleshooting Tips:\n";
    echo "   1. Verify API secret is exactly 64 characters\n";
    echo "   2. Check system clock (must be within ±5 minutes of server)\n";
    echo "   3. Verify API key format: oouth_XXX_XXXXX_XX_XXXX\n";
    echo "   4. Check error_log for detailed debugging info\n";
}

echo "\n";
echo "=================================================\n";
echo "🔍 Check your error_log file for detailed logs\n";
echo "=================================================\n";
?>

