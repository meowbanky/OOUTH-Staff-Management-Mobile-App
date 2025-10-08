<?php
/**
 * OOUTH Salary API Client
 * Handles authentication and data fetching from OOUTH Salary API
 */

require_once(__DIR__ . '/../config/api_config.php');

class OOUTHSalaryAPIClient {
    
    private $baseUrl;
    private $apiKey;
    private $apiSecret;
    private $jwtToken = null;
    private $tokenExpiry = null;
    private $timeout;
    private $debug;
    
    /**
     * Constructor
     */
    public function __construct() {
        $this->baseUrl = OOUTH_API_BASE_URL;
        $this->apiKey = OOUTH_API_KEY;
        $this->apiSecret = OOUTH_API_SECRET;
        $this->timeout = OOUTH_API_TIMEOUT;
        $this->debug = OOUTH_API_DEBUG;
    }
    
    /**
     * Authenticate and get JWT token
     * @return bool Success status
     */
    public function authenticate() {
        try {
            $timestamp = time();
            $signatureString = $this->apiKey . $timestamp;
            $signature = hash_hmac('sha256', $signatureString, $this->apiSecret);
            
            $response = $this->request('POST', '/auth/token', [
                'api_key' => $this->apiKey,
                'timestamp' => $timestamp,
                'signature' => $signature
            ], [
                'X-Timestamp' => $timestamp,
                'X-Signature' => $signature
            ]);
            
            if ($response && isset($response['success']) && $response['success']) {
                $this->jwtToken = $response['data']['access_token'];
                $this->tokenExpiry = time() + $response['data']['expires_in'];
                
                if ($this->debug) {
                    error_log("OOUTH API: Authentication successful");
                }
                
                return true;
            }
            
            if ($this->debug) {
                error_log("OOUTH API: Authentication failed - " . json_encode($response));
            }
            
            return false;
            
        } catch (Exception $e) {
            if ($this->debug) {
                error_log("OOUTH API: Authentication error - " . $e->getMessage());
            }
            return false;
        }
    }
    
    /**
     * Check if token is valid and refresh if needed
     * @return bool
     */
    private function ensureAuthenticated() {
        // Check if token exists and is not expired (with 1 minute buffer)
        if ($this->jwtToken && $this->tokenExpiry && time() < ($this->tokenExpiry - 60)) {
            return true;
        }
        
        // Token expired or doesn't exist, re-authenticate
        return $this->authenticate();
    }
    
    /**
     * Get all payroll periods
     * @param int $page Page number
     * @param int $limit Records per page
     * @return array|null
     */
    public function getPeriods($page = 1, $limit = 100) {
        if (!$this->ensureAuthenticated()) {
            return null;
        }
        
        return $this->request('GET', "/payroll/periods?page={$page}&limit={$limit}");
    }
    
    /**
     * Get active payroll period
     * @return array|null
     */
    public function getActivePeriod() {
        if (!$this->ensureAuthenticated()) {
            return null;
        }
        
        return $this->request('GET', '/payroll/periods/active');
    }
    
    /**
     * Get specific period by ID
     * @param int $periodId
     * @return array|null
     */
    public function getPeriod($periodId) {
        if (!$this->ensureAuthenticated()) {
            return null;
        }
        
        return $this->request('GET', "/payroll/periods/{$periodId}");
    }
    
    /**
     * Get deduction data
     * @param int $deductionId
     * @param int|null $periodId
     * @return array|null
     */
    public function getDeductions($deductionId, $periodId = null) {
        if (!$this->ensureAuthenticated()) {
            return null;
        }
        
        $url = "/payroll/deductions/{$deductionId}";
        if ($periodId !== null) {
            $url .= "?period={$periodId}";
        }
        
        return $this->request('GET', $url);
    }
    
    /**
     * Get allowance data
     * @param int $allowanceId
     * @param int|null $periodId
     * @return array|null
     */
    public function getAllowances($allowanceId, $periodId = null) {
        if (!$this->ensureAuthenticated()) {
            return null;
        }
        
        $url = "/payroll/allowances/{$allowanceId}";
        if ($periodId !== null) {
            $url .= "?period={$periodId}";
        }
        
        return $this->request('GET', $url);
    }
    
    /**
     * Make HTTP request to API
     * @param string $method HTTP method
     * @param string $endpoint API endpoint
     * @param array|null $body Request body
     * @param array $extraHeaders Extra headers
     * @return array|null
     */
    private function request($method, $endpoint, $body = null, $extraHeaders = []) {
        $url = $this->baseUrl . $endpoint;
        
        $headers = [
            'Content-Type: application/json',
            'Accept: application/json',
            'X-API-Key: ' . $this->apiKey
        ];
        
        if ($this->jwtToken) {
            $headers[] = 'Authorization: Bearer ' . $this->jwtToken;
        }
        
        // Add extra headers
        foreach ($extraHeaders as $key => $value) {
            $headers[] = "{$key}: {$value}";
        }
        
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_TIMEOUT, $this->timeout);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        
        if ($body) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
        }
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        
        if ($error) {
            if ($this->debug) {
                error_log("OOUTH API: cURL error - {$error}");
            }
            return null;
        }
        
        if ($this->debug) {
            error_log("OOUTH API: {$method} {$endpoint} - HTTP {$httpCode}");
        }
        
        $data = json_decode($response, true);
        
        if ($httpCode >= 400) {
            if ($this->debug) {
                error_log("OOUTH API: Error response - " . json_encode($data));
            }
        }
        
        return $data;
    }
    
    /**
     * Get resource data based on configured resource type
     * @param int|null $periodId
     * @return array|null
     */
    public function getResourceData($periodId = null) {
        $resourceType = OOUTH_RESOURCE_TYPE;
        $resourceId = OOUTH_RESOURCE_ID;
        
        if ($resourceType === 'deduction') {
            return $this->getDeductions($resourceId, $periodId);
        } elseif ($resourceType === 'allowance') {
            return $this->getAllowances($resourceId, $periodId);
        }
        
        return null;
    }
    
    /**
     * Get last error message
     * @return string|null
     */
    public function getLastError() {
        // You can implement error tracking here
        return null;
    }
}