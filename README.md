# Bus Tracking System

A real-time bus tracking system using Flutter, Supabase, and ESP32.

## Features
- Real-time bus location tracking
- Interactive map with routes and stops
- Live search for stops and routes
- Beautiful animated splash screen with Lottie
- Dark/light theme support

## Setup Instructions

### 1. Project Setup
```bash
# Make script executable
chmod +x init_project.sh

# Run initialization script
./init_project.sh
```

### 2. Supabase Setup
```bash
# Install Supabase CLI
npm install -g supabase
# or
brew install supabase/tap/supabase

# Link project
supabase login
supabase link --project-ref your-project-ref

# Apply database migrations
supabase db push
```

### 3. Flutter App Setup
Create `.env` file in project root:
```env
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

Install dependencies and run:
```bash
flutter pub get
flutter run
```

### 4. ESP32 Setup
1. Open `esp32/bus_stop_monitor.ino` in Arduino IDE
2. Install required libraries:
   - WiFi
   - HTTPClient
   - ArduinoJson
3. Update configuration:
   ```cpp
   const char* ssid = "your_wifi_ssid";
   const char* password = "your_wifi_password";
   const char* supabaseUrl = "your_supabase_url";
   const char* supabaseKey = "your_supabase_anon_key";
   const char* busStopId = "your_bus_stop_id"; // from sample data
   ```
4. Flash to ESP32

## Splash Screen

The app features a beautiful animated splash screen using Lottie animations:

- Location: `assets/animations/bus_tracking.json`
- Features:
  * Smooth bus movement animation
  * Fade-in text transitions
  * Material 3 design elements
  * Version display
  * Auto-transition to main screen

To customize the splash screen:
1. Edit the animation in `assets/animations/bus_tracking.json`
2. Adjust timings in `lib/screens/splash_screen.dart`
3. Update text and colors as needed

## Sample Data

The seed data includes:

Bus IDs:
- dddddddd-dddd-dddd-dddd-dddddddddddd (Route 1)
- eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee (Route 2)
- ffffffff-ffff-ffff-ffff-ffffffffffff (Express)

Stop IDs:
- 11111111-1111-1111-1111-111111111111 (Central Station)
- 22222222-2222-2222-2222-222222222222 (Tech Park)
- 33333333-3333-3333-3333-333333333333 (Market Square)
- 44444444-4444-4444-4444-444444444444 (University Campus)
- 55555555-5555-5555-5555-555555555555 (Hospital)

Route IDs:
- aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa (Route 1)
- bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb (Route 2)
- cccccccc-cccc-cccc-cccc-cccccccccccc (Express 1)
