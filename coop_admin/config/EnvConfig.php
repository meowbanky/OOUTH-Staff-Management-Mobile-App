<?php

class EnvConfig {
    private static $config = null;
    
    /**
     * Load configuration from config.env file
     */
    public static function load() {
        if (self::$config === null) {
            self::$config = [];
            
            $envFile = __DIR__ . '/../config.env';
            
            if (file_exists($envFile)) {
                $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
                
                foreach ($lines as $line) {
                    // Skip comments
                    if (strpos(trim($line), '#') === 0) {
                        continue;
                    }
                    
                    // Parse key=value pairs
                    if (strpos($line, '=') !== false) {
                        list($key, $value) = explode('=', $line, 2);
                        $key = trim($key);
                        $value = trim($value);
                        
                        // Remove quotes if present
                        if ((substr($value, 0, 1) === '"' && substr($value, -1) === '"') ||
                            (substr($value, 0, 1) === "'" && substr($value, -1) === "'")) {
                            $value = substr($value, 1, -1);
                        }
                        
                        self::$config[$key] = $value;
                    }
                }
            }
        }
        
        return self::$config;
    }
    
    /**
     * Get a configuration value
     */
    public static function get($key, $default = null) {
        $config = self::load();
        return isset($config[$key]) ? $config[$key] : $default;
    }
    
    /**
     * Get OpenAI API key
     */
    public static function getOpenAIKey() {
        return self::get('OPENAI_API_KEY');
    }
    
    /**
     * Check if OpenAI key is configured
     */
    public static function hasOpenAIKey() {
        $key = self::getOpenAIKey();
        return !empty($key) && $key !== 'your_openai_api_key_here';
    }
    
    /**
     * Get database configuration from .env file
     * Throws exception if required values are missing
     */
    public static function getDatabaseConfig() {
        $host = self::get('DB_HOST');
        $name = self::get('DB_NAME');
        $user = self::get('DB_USER');
        $password = self::get('DB_PASSWORD');
        
        // Validate required database configuration values
        if (empty($host)) {
            throw new \Exception('DB_HOST is not configured in config.env file');
        }
        if (empty($name)) {
            throw new \Exception('DB_NAME is not configured in config.env file');
        }
        if (empty($user)) {
            throw new \Exception('DB_USER is not configured in config.env file');
        }
        if ($password === null) {
            throw new \Exception('DB_PASSWORD is not configured in config.env file');
        }
        
        return [
            'host' => $host,
            'name' => $name,
            'user' => $user,
            'password' => $password
        ];
    }
    
    /**
     * Get file upload configuration
     */
    public static function getUploadConfig() {
        return [
            'max_size' => self::get('MAX_FILE_SIZE', '10MB'),
            'allowed_types' => explode(',', self::get('ALLOWED_FILE_TYPES', 'pdf,xlsx,xls,jpg,jpeg,png'))
        ];
    }
    
    /**
     * Get Google Maps API key
     */
    public static function getGoogleMapsApiKey() {
        return self::get('GOOGLE_MAPS_API_KEY', '');
    }
    
    /**
     * Get API Secret for authentication
     */
    public static function getAPISecret() {
        return self::get('API_SECRET', '');
    }
} 