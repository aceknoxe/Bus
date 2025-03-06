#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "your_wifi_ssid";
const char* password = "your_wifi_password";

// Supabase configuration
const char* supabaseUrl = "your_supabase_url";
const char* supabaseKey = "your_supabase_anon_key";
const char* functionPath = "/functions/v1/bus-update";

// Bus stop configuration
const char* busStopId = "your_bus_stop_id"; // UUID from your database
const long updateInterval = 10000; // Update every 10 seconds

// RFID settings
#define RFID_SS_PIN 10
#define RFID_RST_PIN 9

void setup() {
  Serial.begin(115200);
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");
  
  // Initialize RFID reader
  SPI.begin();
  rfid.PCD_Init();
}

void loop() {
  // Check if new card is present
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    String busId = getBusIdFromCard();
    if (busId.length() > 0) {
      sendBusUpdate(busId);
    }
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
  }
  
  delay(100); // Small delay between readings
}

String getBusIdFromCard() {
  // Read RFID card data
  String content = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    content.concat(String(rfid.uid.uidByte[i] < 0x10 ? "0" : ""));
    content.concat(String(rfid.uid.uidByte[i], HEX));
  }
  content.toUpperCase();
  
  // Map RFID to bus ID (you would maintain this mapping in your system)
  if (content == "CARD_ID_1") return "bus_uuid_1";
  if (content == "CARD_ID_2") return "bus_uuid_2";
  return "";
}

void sendBusUpdate(String busId) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    
    // Create JSON payload
    StaticJsonDocument<200> doc;
    doc["bus_id"] = busId;
    doc["stop_id"] = busStopId;
    
    String jsonString;
    serializeJson(doc, jsonString);
    
    // Configure HTTP request
    String url = String(supabaseUrl) + functionPath;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + String(supabaseKey));
    
    // Send POST request
    int httpCode = http.POST(jsonString);
    
    if (httpCode > 0) {
      String response = http.getString();
      Serial.println("HTTP Response code: " + String(httpCode));
      Serial.println("Response: " + response);
      
      // Visual feedback
      digitalWrite(LED_BUILTIN, HIGH);
      delay(500);
      digitalWrite(LED_BUILTIN, LOW);
    } else {
      Serial.println("Error sending update");
      // Error feedback
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