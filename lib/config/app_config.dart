class AppConfig {
  static const String appName = 'SURAKSHA AI';
  static const String tagline = 'Your Safety. Your Route. Your Power.';
  static const String assistantName = 'Suraksha';
  static const String greeting =
      "Hi, I'm Suraksha, your AI-powered route and safety assistant. Where would you like to go?";

  // Default backend base URL for Android emulator is 10.0.2.2:8000, for web/desktop is localhost:8000
  static String backendBaseUrl = 'http://10.0.2.2:8000';

  // Toggle for demo mode indicator
  static const String demoModeLabel = 'DEMO MODE: Simulated Safety Data';
  static const String reportingPeriod = 'Last 90 Days';

  // Default demonstration coordinates (Hyderabad Center)
  static const double defaultLat = 17.3850;
  static const double defaultLng = 78.4867;

  // Open-Source Geospatial Services Endpoints (Configurable)
  static String photonBaseUrl = 'https://photon.komoot.io/api';
  static String osrmBaseUrl = 'https://router.project-osrm.org';
  static String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'com.suraksha.ai/1.0';
  static const String osmAttribution = '© OpenStreetMap contributors';
}
