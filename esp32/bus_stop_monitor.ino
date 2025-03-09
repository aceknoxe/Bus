#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "your_wifi_ssid";
const char* password = "your_wifi_password";

// Supabase configuration
const char* supabaseUrl = "https://naalvxbwxafxxazmpeja.supabase.co";
const char* supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hYWx2eGJ3eGFmeHhhem1wZWphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEwMTc4NDQsImV4cCI6MjA1NjU5Mzg0NH0.EnOibOlUeb6zX51lvyQS8dCXhkbvLed2D44vPQB4HR8";

// Test configuration
const char* testBusId = "dddddddd-dddd-dddd-dddd-dddddddddddd"; // Route 1 Bus

// Actual bus stop IDs from database
const char* testBusStopIds[] = {
  "11111111-1111-1111-1111-111111111111", // Central Station
  "22222222-2222-2222-2222-222222222222", // Market Square
  "33333333-3333-3333-3333-333333333333", // University
  "44444444-4444-4444-4444-444444444444", // Hospital
  "66666666-6666-6666-6666-666666666666", // Shopping Mall
  "77777777-7777-7777-7777-777777777777", // Airport Terminal
  "88888888-8888-8888-8888-888888888888", // Sports Complex
  "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1"  // Metro Station
};
const int numStops = sizeof(testBusStopIds) / sizeof(testBusStopIds[0]);
int currentStopIndex = 0;
unsigned long lastUpdateTime = 0;
const unsigned long UPDATE_INTERVAL = 20000; // 20 seconds

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");
  
  // Initialize timestamp
  lastUpdateTime = millis();
  Serial.println("Starting with bus stop: " + String(testBusStopIds[currentStopIndex]));
  
  // Initial LED feedback - 2 quick blinks for successful setup
  for (int i = 0; i < 2; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
    delay(200);
  }
}

void loop() {
  unsigned long currentTime = millis();
  
  // Check if it's time to update
  if (currentTime - lastUpdateTime >= UPDATE_INTERVAL) {
    // Update the current stop index
    currentStopIndex = (currentStopIndex + 1) % numStops;
    lastUpdateTime = currentTime;
    
    // Send update to Supabase
    sendBusUpdate(testBusId, testBusStopIds[currentStopIndex]);
    
    // Visual feedback - one long blink for stop change
    digitalWrite(LED_BUILTIN, HIGH);
    delay(500);
    digitalWrite(LED_BUILTIN, LOW);
  }
  
  delay(100); // Small delay between checks
}

void sendBusUpdate(const char* busId, const char* stopId) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    
    // Create JSON payload with correct column names
    StaticJsonDocument<200> doc;
    doc["current_stop_id"] = stopId;
    doc["last_update"] = "now()"; // Supabase SQL function for current timestamp
    doc["updated_at"] = "now()";
    
    String jsonString;
    serializeJson(doc, jsonString);
    
    // Log the update
    Serial.println("Sending update - Bus: " + String(busId) + " at Stop: " + String(stopId));
    
    // Configure HTTP request - using REST API to update buses table
    // Note: using 'id' instead of 'bus_id' as it's the primary key
    String url = String(supabaseUrl) + "/rest/v1/buses?id=eq." + String(busId);
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + String(supabaseKey));
    http.addHeader("Prefer", "return=minimal");
    
    // Send PATCH request to update bus location
    int httpCode = http.PATCH(jsonString);
    
    if (httpCode == 204) { // Successful PATCH returns 204 No Content
      Serial.println("Update successful");
      
      // Visual feedback - one quick blink for successful update
      digitalWrite(LED_BUILTIN, HIGH);
      delay(200);
      digitalWrite(LED_BUILTIN, LOW);
    } else {
      Serial.println("Error sending update, code: " + String(httpCode));
      if (httpCode > 0) {
        Serial.println("Response: " + http.getString());
      }
      
      // Error feedback - three quick blinks
      for (int i = 0; i < 3; i++) {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(100);
        digitalWrite(LED_BUILTIN, LOW);
        delay(100);
      }
    }
    
    http.end();
  }
}
