# 🛡️ SURAKSHA AI

<div align="center">

> *"Your Safety. Your Route. Your Power."*  
> **"మీ భద్రత. మీ మార్గం. మీ శక్తి."**

[![Flutter](https://img.shields.io/badge/Flutter-3.13%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115%2B-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)](https://python.org)
[![OpenStreetMap](https://img.shields.io/badge/OpenStreetMap-Cartography-7EBC6F?logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)
[![OSRM](https://img.shields.io/badge/Routing-OSRM-blue)](https://project-osrm.org)
[![Photon](https://img.shields.io/badge/Geocoding-Photon%20Komoot-orange)](https://photon.komoot.io)
[![Cost](https://img.shields.io/badge/Cost-%240.00%20Zero%20Paid%20APIs-success)](https://github.com)
[![Backend Tests](https://img.shields.io/badge/Backend%20Tests-10%2F10%20Passed-brightgreen)](https://github.com)
[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-10%2F10%20Passed-brightgreen)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT%20%2F%20ODbL-lightgrey)](LICENSE)

**A 100% Free, Open-Source Geospatial Intelligence Platform & Mobile Application for Safe Commuter Navigation and Public Safety Transparency.**

[Features](#-core-features) • [Free FOSS Stack](#-zero-cost-geospatial-stack) • [System Architecture](#-system-architecture) • [Scoring Algorithm](#-mathematical-scoring-algorithm) • [Quick Start](#-installation--setup-guide) • [API Docs](#-api-specification) • [Demo Script](#-hackathon-live-demonstration-walkthrough)

</div>

---

## 📖 Table of Contents

- [1. Executive Summary & Vision](#-executive-summary--vision)
- [2. Zero-Cost Geospatial Stack](#-zero-cost-geospatial-stack)
- [3. Core Features](#-core-features)
- [4. System Architecture](#-system-architecture)
- [5. Complete Tech Stack](#-complete-tech-stack)
- [6. Directory Structure](#-directory-structure)
- [7. Mathematical Scoring Algorithm](#-mathematical-scoring-algorithm)
- [8. Real-World Datasets & Provenance](#-real-world-datasets--provenance)
- [9. Action-Capable AI Voice Assistant ("Suraksha")](#-action-capable-ai-voice-assistant-suraksha)
- [10. API Specification & Endpoints](#-api-specification)
- [11. Installation & Setup Guide](#-installation--setup-guide)
  - [Prerequisites](#prerequisites)
  - [Backend Setup (FastAPI)](#backend-setup-fastapi)
  - [Flutter Mobile App Setup](#flutter-mobile-app-setup)
  - [Connecting Mobile App to Backend](#connecting-mobile-app-to-backend-emulator-vs-physical-device)
- [12. Testing & Quality Assurance](#-testing--quality-assurance)
- [13. Hackathon Live Demonstration Walkthrough](#-hackathon-live-demonstration-walkthrough)
- [14. Emergency Protocol & Responsible AI Disclaimer](#-emergency-protocol--responsible-ai-disclaimer)
- [15. License & Attribution](#-license--attribution)

---

## 🌟 Executive Summary & Vision

Every day, millions of commuters—particularly women, late-night workers, students, and seniors—must travel through unfamiliar or dimly lit urban corridors. Existing commercial mapping applications optimize almost exclusively for **travel time** or **shortest distance**, often routing pedestrians and drivers through unlit back alleys, unmonitored bypasses, and hazardous collision zones.

Furthermore, building public safety applications typically incurs **prohibitive cloud API fees** (Google Maps Platform, Mapbox), locking out student developers, civic non-profits, and grassroots researchers.

**SURAKSHA AI** solves both challenges:
1. **100% Zero-Cost, Free & Open-Source Software (FOSS) Geospatial Stack:** Built on OpenStreetMap, Komoot Photon, and OSRM—demanding **no credit card, no cloud billing account, and zero paid API keys**.
2. **Deterministic, Precision-Aware Route Corridor Scoring:** Instead of opaque black-box "safety ratings", SURAKSHA AI computes mathematical corridor exposure density using verified police accident reports, municipal streetlight audits, and SHE Teams records.
3. **Data Integrity & Verification Isolation:** Community hazard reports remain quarantined as `PENDING` until validated, preventing malicious manipulation or false alarm contamination of official route scores.
4. **Action-Capable Indian English Voice Assistant:** "Suraksha" answers commuter questions, explains dataset provenance, checks report statuses, and accepts hands-free hazard submissions with spoken audio feedback.
5. **Offline-First Resilience:** Pre-loaded with 2,500+ real Hyderabad incident markers and public safety facilities, allowing the app to plan routes and evaluate hazards even without network connectivity.

---

## 💡 Zero-Cost Geospatial Stack

SURAKSHA AI operates without relying on proprietary, paid navigation platforms:

| Capability | Open-Source / Free Solution | Endpoint / Package | Licensing | Commercial Alternative Replaced |
|---|---|---|---|---|
| **Interactive Map UI** | **Flutter Map** (v8.3.2) | `flutter_map` + `latlong2` | BSD-3-Clause | Google Maps SDK ($7 / 1,000 loads) |
| **Map Cartography** | **OpenStreetMap** Raster Tiles | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | ODbL | Google Maps Dynamic Tiles |
| **Place Search & Geocoding** | **Photon by Komoot** (OSM-based) | `https://photon.komoot.io/api` | Apache-2.0 / ODbL | Google Places API ($17–$32 / 1,000 queries) |
| **Road Route Polyline** | **Project OSRM** Routing Engine | `https://router.project-osrm.org/route/v1/driving` | BSD-2-Clause | Google Directions API ($5–$10 / 1,000 requests) |
| **POI & Feature Extraction** | **Overpass API** (OSM Mirrors) | `https://overpass-api.de/api/interpreter` | ODbL | Google Places Details |
| **Voice Recognition & Speech** | **Native Android STT & TTS** | `speech_to_text` + `flutter_tts` | Hardware Native | Google Cloud Speech / ElevenLabs |
| **Corridor Analysis Engine** | **Deterministic Spatial Buffer Engine** | Python FastAPI / Dart Client Adapter | MIT | Proprietary Cloud Spatial DBs |

> [!TIP]
> **Total Monthly Operating Cost:** **$0.00**. Run on a free local workstation, university lab machine, or free cloud tier indefinitely.

---

## 🚀 Core Features

### 🗺️ 1. Map-First Interactive Navigation
- **Full-Screen OpenStreetMap:** Fluid, gesture-driven vector/raster map centered on Hyderabad (`17.3850, 78.4867`).
- **One-Tap Pin Drop:** Tap anywhere on the road network to immediately set route destinations.
- **Photon Geocoding Search:** Debounced, live autocomplete place search with offline cached Hyderabad landmarks (Charminar, HITEC City, Saidabad, Secunderabad).
- **Curated Multi-Route Alternatives:** View primary routes and alternative road options (Route A vs Route B) generated strictly along drivable/walkable streets via OSRM.

### 📊 2. Precision-Aware Heuristic Corridor Risk Scoring
- **Dynamic 200m/280m Buffer:** Projects route polyline segments into spatial corridors and calculates incident exposure.
- **Location Precision Isolation:** Discards station/district-wide aggregated (`AREA_ONLY`) statistics from street corridors to eliminate false precision.
- **Transparent Methodology:** Tap any route score badge to view the full breakdown—verified incident count, density per km, and data sources consulted.

### 🎙️ 3. Action-Capable AI Voice Assistant ("Suraksha")
- **True Backend Tool Execution:** Powered by an LLM agent with deterministic fallback that invokes structured tools:
  - `get_route_options`, `get_route_incidents`, `calculate_route_score`, `compare_routes`
  - `submit_incident_report`, `get_report_status`, `get_data_sources_info`
- **Voice In / Audio Out:** Native Speech-to-Text with animated audio visualizer and Indian English Text-to-Speech playback.
- **Prompt Audio Interruption:** One-tap stop-speaking control to halt TTS playback instantly.

### 🛡️ 4. Citizen Incident Reporting & Verification Lifecycle
- **Material 3 Reporting Workflow:** Submit reports across 10 categories (poor lighting, harassment, road accidents, isolation, road blockages).
- **Spatial Duplicate Detection:** Automatically flags matching community reports submitted within 120 meters.
- **Zero-Contamination Quarantine:** Newly reported hazards enter as `PENDING VERIFICATION` and **never** artificially inflate or distort verified safety scores until approved.
- **"My Reports" Dashboard:** Live tracking of citizen submissions with real-time status chips (`PENDING`, `VERIFIED`, `REJECTED`).

### 🌐 5. Bilingual & Accessibility First
- **English & Telugu (తెలుగు) Support:** Complete in-app internationalization switchable in real time.
- **Theme Modes:** Light Mode, Dark Mode, and System Default with high-contrast road styling.
- **Emergency Speed Dial:** Immediate confirmation dialers for **112** (National Emergency), **1091** (Women's Helpline), **108** (Ambulance), and Telangana SHE Teams WhatsApp.

### 🚗 6. Seamless Navigation Handoff
- Preview safe corridor options in SURAKSHA AI, then launch turn-by-turn navigation in **Google Maps** via native Android Intent with one tap.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      SURAKSHA AI Mobile Client (Flutter)                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                    Map-First User Interface                               │  │
│  │  • FlutterMap (OSM TileLayer)    • Floating Photon Search Bar (Autocomplete)│ │
│  │  • Interactive Map Tap Routing    • Route Alternative Bottom Sheet Cards    │ │
│  │  • Category & Status Filter Chips • Incident Marker Clusters & Tooltips   │  │
│  └─────────────────────────────────────┬─────────────────────────────────────┘  │
│                                        │                                        │
│  ┌─────────────────────────────────────▼─────────────────────────────────────┐  │
│  │                     State & Service Coordination Layer                    │  │
│  │  • IncidentService (Remote + 2,500+ Embedded Fallback Records)            │  │
│  │  • RoutingService (OSRM Driving Engine & Alternative Polyline Parser)      │  │
│  │  • PhotonService (Komoot Geocoding with Local Memory Cache)               │  │
│  │  • AssistantService (Voice Agent Orchestration & Tool Dispatch)           │  │
│  │  • SpeechService (Android SpeechToText & FlutterTTS en-IN)                │  │
│  │  • LocalizationService (EN / TE) & ThemeService (Light / Dark)            │  │
│  └─────────────────────────────────────┬─────────────────────────────────────┘  │
└────────────────────────────────────────┼────────────────────────────────────────┘
                                         │ HTTP REST (JSON)
┌────────────────────────────────────────▼────────────────────────────────────────┐
│                   SURAKSHA AI Intelligence Server (FastAPI)                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────┐  ┌───────────────────────┐  ┌───────────────────┐  │
│  │   Routing & Corridor    │  │   Heuristic Scoring   │  │   Action Agent    │  │
│  │      Engine (OSRM)      │  │  (Haversine / Buffers)│  │ (LLM Tool Calling)│  │
│  └────────────┬────────────┘  └───────────┬───────────┘  └─────────┬─────────┘  │
│               │                           │                        │            │
│  ┌────────────▼───────────────────────────▼────────────────────────▼─────────┐  │
│  │                   Dataset Loader & Verification Pipeline                  │  │
│  │  • 120m Spatial Duplicate Detector       • ODbL OpenStreetMap Importer    │  │
│  │  • Verification Lifecycle Isolator       • Road-Aligned Synthetic Gen     │  │
│  └────────────────────────────────────────┬──────────────────────────────────┘  │
│                                           │                                     │
│  ┌────────────────────────────────────────▼──────────────────────────────────┐  │
│  │       Data Store: incidents.csv | places.json | community_reports.json    │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 💻 Complete Tech Stack

### Mobile Application
- **Framework:** Flutter 3.13+ / Dart 3.0+
- **Architecture:** Provider Pattern (`ChangeNotifier`, `MultiProvider`)
- **Map & Cartography:** `flutter_map` (v8.3.2), `latlong2` (v0.10.1)
- **Voice Hardware APIs:** `speech_to_text` (v7.5.0), `flutter_tts` (v4.2.5)
- **Networking & Storage:** `http` (v1.6.0), `shared_preferences` (v2.5.6)
- **External Intention Handlers:** `url_launcher` (v6.3.3)
- **Target OS:** Android (minSdk: 23, compileSdk: 36, targetSdk: 34)

### Backend Intelligence Server
- **Server Framework:** FastAPI (v0.115.0+), Uvicorn (v0.30.0+)
- **Data Validation & Modeling:** Pydantic (v2.8.0+)
- **Asynchronous HTTP Client:** HTTPX (v0.27.0+)
- **Geometry & Spatial Analysis:** Python Standard `math` (Haversine & Point-to-Segment projections)
- **External Open Geospatial APIs:**
  - Komoot Photon API: `https://photon.komoot.io/api`
  - Project OSRM Routing: `https://router.project-osrm.org`
  - OpenStreetMap Overpass: `https://overpass-api.de/api/interpreter`

---

## 📁 Directory Structure

```
Suraksha/
├── android/                             # Android native configuration & manifests
│   ├── app/
│   │   ├── build.gradle.kts             # Gradle configuration (minSdk 23, compileSdk 36)
│   │   └── src/main/
│   │       └── AndroidManifest.xml      # Hardware permissions (INTERNET, RECORD_AUDIO, GPS)
│   └── gradle.properties                # JVM & compilation optimization flags
├── assets/                              # App visual assets & map styles
│   ├── images/
│   │   └── suraksha_splash.png          # App brand splash logo
│   └── map_styles/
│       └── dark_map_style.json          # Custom night-time road tile configuration
├── backend/                             # Python FastAPI Intelligence Backend
│   ├── agent.py                         # Action-capable tool-calling agent & prompts
│   ├── data.py                          # In-memory storage & community report management
│   ├── data_loader.py                   # CSV/JSON dataset validator, duplicate checker
│   ├── main.py                          # FastAPI REST endpoints & CORS definitions
│   ├── models.py                        # Pydantic schemas (Routes, Incidents, Scores)
│   ├── osm_importer.py                  # OpenStreetMap Overpass feature harvester (ODbL)
│   ├── routing.py                       # OSRM road route client & demo geometries
│   ├── scoring.py                       # Precision-aware deterministic corridor engine
│   ├── synthetic_generator.py           # Road-aligned synthetic scenario generator
│   ├── test_backend.py                  # 10-step automated backend test suite
│   ├── requirements.txt                 # Backend Python dependencies
│   └── .env.example                     # Environment configuration template
├── data/                                # Master Geospatial Datasets
│   ├── data_sources.json                # 6 registered official sources (Police, SHE Teams)
│   ├── incidents.csv                    # Real-world attributable incident catalog
│   ├── places.json                      # Public safety facilities (Police, Hospitals, SHE)
│   ├── road_segments.json               # Surveyed road corridors with illumination stats
│   ├── osm_features.json                # Imported OpenStreetMap POIs & street lights
│   ├── demo_incidents.json              # Synthetic test fixtures (is_simulated: true)
│   ├── community_reports.json           # User-submitted citizen hazard reports
│   └── README.md                        # Dataset documentation & provenance guidelines
├── lib/                                 # Flutter Dart Application
│   ├── main.dart                        # Entry point (initializes providers & run)
│   ├── app.dart                         # MultiProvider root & theme definition
│   ├── config/
│   │   └── app_config.dart              # Global endpoints (OSM, Photon, OSRM, Backend)
│   ├── data/
│   │   └── embedded_incidents_data.dart # 2,500+ embedded incidents for offline fallback
│   ├── models/                          # Strongly typed Dart data models
│   │   ├── chat_message_model.dart      # Chat messages & tool invocations
│   │   ├── facility_model.dart          # Police, hospital, and emergency facility model
│   │   ├── incident_model.dart          # Standard incident record with precision
│   │   ├── photon_feature.dart          # Photon geocoded search result
│   │   ├── route_model.dart             # Route polyline & distance metrics
│   │   ├── route_score_model.dart       # Heuristic risk score & evidence model
│   │   └── saved_location_model.dart    # User favorite places model
│   ├── screens/                         # Mobile Application Screens
│   │   ├── assistant_screen.dart        # Voice & chat assistant screen
│   │   ├── home_screen.dart             # Scaffold container with navigation drawer
│   │   ├── map_screen.dart              # Full-screen interactive OSM map with Photon
│   │   ├── my_reports_screen.dart       # Community submission tracking dashboard
│   │   ├── report_incident_screen.dart  # 10-category incident report submission form
│   │   ├── saved_locations_screen.dart  # Saved places manager
│   │   ├── score_explanation_screen.dart# Transparent safety formula explainer
│   │   ├── settings_screen.dart         # Telugu/English toggle & Dark/Light mode
│   │   └── splash_screen.dart           # Animated initial launch branding
│   ├── services/                        # Business Logic & Networking Services
│   │   ├── assistant_service.dart       # LLM chat orchestrator & offline tool executor
│   │   ├── emergency_service.dart       # Speed dial intent launcher (112, 1091, 108)
│   │   ├── incident_service.dart        # Incident fetcher with offline fallback
│   │   ├── localization_service.dart    # Bilingual English / Telugu dictionary
│   │   ├── location_service.dart        # Device GPS & destination coordination
│   │   ├── navigation_launcher_service.dart # Turn-by-turn Google Maps intent handoff
│   │   ├── photon_service.dart          # Photon place geocoding with local LRU cache
│   │   ├── risk_scoring_service.dart    # Local client-side heuristic scorer
│   │   ├── routing_service.dart         # Direct OSRM polyline fetcher & decoder
│   │   ├── saved_locations_service.dart # Local persistent storage for favorites
│   │   ├── speech_service.dart          # Android native STT & TTS manager
│   │   └── theme_service.dart           # App-wide light/dark theme switcher
│   └── widgets/                         # Reusable UI Components
│       ├── incident_marker.dart         # Color-coded map markers with category icons
│       ├── microphone_button.dart       # Animated pulsating mic with voice states
│       └── route_card.dart              # Route comparison card with score badge
├── test/                                # Flutter Unit & Widget Tests
│   ├── incident_reporting_test.dart     # Comprehensive models & service unit tests
│   └── widget_test.dart                 # Map-first smoke & widget render tests
└── pubspec.yaml                         # Flutter dependencies & asset declarations
```

---

## 🧮 Mathematical Scoring Algorithm

SURAKSHA AI rejects arbitrary or opaque "AI ratings". Instead, it applies a **deterministic, precision-aware spatial corridor algorithm**:

### 1. Spatial Corridor Projection
Given a route polyline $R$ composed of $n$ road vertices $[v_1, v_2, \dots, v_n]$:
- Each road segment $S_i = (v_i, v_{i+1})$ is evaluated.
- For every incident $I$ at coordinate $(lat_I, lon_I)$, the orthogonal distance $d(I, S_i)$ to segment $S_i$ is computed using the **Haversine formula** projected onto the planar tangent:

$$d(I, S_i) = \min_{t \in [0, 1]} \text{Haversine}\Big(I, v_i + t \cdot (v_{i+1} - v_i)\Big)$$

### 2. Precision-Aware Threshold Matching
- **`EXACT` Precision:** Matched if $d(I, S_i) \le 200 \text{ meters}$.
- **`APPROXIMATE` Precision:** Matched if $d(I, S_i) \le 280 \text{ meters}$ (weighted at $0.85\times$).
- **`AREA_ONLY` Precision:** **Filtered out** ($d = \infty$) to prevent falsely attributing city-wide or district statistics to specific streets.

### 3. Category Severity Weighting
Each verified incident is assigned a severity weight $W_c$ based on historical public safety severity:

| Category | Weight ($W_c$) | Rationale |
|---|---|---|
| `ASSAULT` / `HARASSMENT` | **1.8** | Direct personal threat to commuter |
| `WOMEN_SAFETY` | **1.7** | Targeted vulnerability |
| `ROAD_ACCIDENT` | **1.5** | High vehicular collision risk |
| `THEFT` | **1.2** | Property and transit risk |
| `POOR_STREET_LIGHTING` | **1.0** | Infrastructure deficiency |
| `UNSAFE_OR_ISOLATED_AREA` | **1.0** | Lack of natural surveillance |
| `TRAFFIC_HAZARD` / `OBSTRUCTION` | **0.8** | Flow impediment |

### 4. Normalized Exposure Density Formula
The cumulative exposure is normalized over the route length $D_{\text{km}}$:

$$\text{Exposure Density} = \frac{\sum_{k} \Big( W_{c_k} \times \text{PrecisionMultiplier}_k \Big)}{\max(D_{\text{km}}, 0.5)}$$

The final Corridor Risk Score ($S \in [0, 100]$) is:

$$S = \min\Big(100.0, \; 10.0 + (\text{Exposure Density} \times 20.0)\Big)$$

> [!NOTE]
> - **$S \le 25$:** Low Recorded Exposure (well-illuminated, high footfall, minimal recorded incidents).
> - **$25 < S \le 55$:** Moderate Recorded Exposure.
> - **$S > 55$:** Elevated Exposure (cluster of recorded accidents, poor lighting, or police blackspots).
> - **Zero Guarantee Disclaimer:** A low score reflects fewer *recorded* incidents in available datasets; it does not guarantee absolute safety.

---

## 🗃️ Real-World Datasets & Provenance

SURAKSHA AI aggregates and structures public safety records across Hyderabad & Telangana:

| Dataset | Provider / Source | Records | Coverage |
|---|---|---|---|
| **Traffic Accident Blackspots** | Hyderabad & Cyberabad Traffic Police | Official | Major junctions (LB Nagar, Charminar, PVNR) |
| **Women's Safety Incident Registry** | Telangana Police SHE Teams Annual Audits | Official | Transit hubs, college corridors, bus stands |
| **Streetlight & Illumination Surveys** | Greater Hyderabad Municipal Corporation (GHMC) | Official | Secondary arterial roads & dark corridors |
| **Road Safety Open Datasets** | OpenCity.in & Data.gov.in | Public Open Data | Historical accident archives |
| **Public Safety Facilities** | OpenStreetMap contributors & Govt. Directories | Verified | 24x7 Police Stations, SHE Centers, Hospitals |
| **Citizen Community Submissions** | SURAKSHA AI Mobile Community | User Generated | Quarantined under `PENDING` review |

---

## 🎙️ Action-Capable AI Voice Assistant ("Suraksha")

Unlike static chatbots, **Suraksha** can inspect app state and execute tools within the system:

```
Commuter: "Which route has fewer recorded accidents to the airport?"
  │
  ├──> Assistant parses intent and executes backend tools:
  │    1. tool_get_route_options(origin, destination)
  │    2. tool_get_route_incidents(route_id, category_filter="ROAD_ACCIDENT")
  │    3. tool_calculate_route_score(route_id)
  │
  ├──> Synthesizes evidence-based response:
  │    "Route A via the Main Arterial has 2 recorded minor accidents over 14 km
  │     (Score: 16.2), while Route B via the back-road has 5 incidents near an
  │     unlit intersection. I recommend Route A."
  │
  └──> Speaks response aloud via Android Text-to-Speech (en-IN).
```

### Voice Commands Supported:
- *"Take me to Charminar"* (searches via Photon and sets destination).
- *"Compare routes using recent accident history"* (triggers OSRM routing and corridor scoring).
- *"Report poor street lighting here"* (initiates hands-free incident submission).
- *"Where does this data come from?"* (details official sources: Hyderabad Police, GHMC, SHE Teams).
- *"Who can I call in an emergency?"* (displays 112, 1091, 108 speed dial buttons).

---

## 🔌 API Specification

The FastAPI intelligence backend exposes REST endpoints conforming to OpenAPI 3.0:

### 1. Route Comparison Endpoint
`POST /api/routes/compare`

**Request:**
```json
{
  "origin": "Matrusri Engineering College",
  "destination": "Saidabad Metro Station",
  "category_filter": "ALL",
  "time_window": "last_90_days"
}
```

**Response (200 OK):**
```json
{
  "origin": "Matrusri Engineering College",
  "destination": "Saidabad Metro Station",
  "routes": [
    {
      "route_id": "route_arterial_saidabad",
      "name": "Route A: Main Arterial via Saidabad Main Rd",
      "distance_km": 2.6,
      "duration_minutes": 9,
      "geometry": [[17.3596, 78.5085], [17.3753, 78.4908]]
    }
  ],
  "scores": {
    "route_arterial_saidabad": {
      "score": 18.4,
      "score_status": "calculated",
      "verified_incident_count": 1,
      "pending_report_count": 0,
      "exposure_density": 0.38,
      "evidence_summary": "1 verified incident along 2.6 km corridor."
    }
  },
  "recommended_route_id": "route_arterial_saidabad",
  "comparison_summary": "Route A is the best-supported route based on recorded incident exposure."
}
```

### 2. Citizen Incident Submission Endpoint
`POST /api/incidents`

**Request:**
```json
{
  "category": "POOR_STREET_LIGHTING",
  "description": "Non-functional street light cluster near colony entrance",
  "latitude": 17.3685,
  "longitude": 78.5075,
  "location_precision": "EXACT",
  "severity_reported": "MEDIUM",
  "is_anonymous": true
}
```

**Response (200 OK):**
```json
{
  "report_id": "COM-REP-2024-9182",
  "submission_status": "SUCCESS",
  "verification_status": "PENDING",
  "is_duplicate_warning": false,
  "message": "Incident submitted successfully and marked PENDING VERIFICATION. Awaiting review."
}
```

### 3. Action-Capable AI Agent Chat Endpoint
`POST /api/agent/chat`

**Request:**
```json
{
  "message": "Explain where this incident data came from.",
  "conversation_history": []
}
```

---

## 🛠️ Installation & Setup Guide

### Prerequisites
- **Flutter SDK:** Version `^3.13.0` ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Android SDK:** Compile SDK 36, Min SDK 23 ([Android Studio](https://developer.android.com/studio))
- **Python:** Version `3.10` or higher ([Download Python](https://www.python.org/downloads/))
- **Physical Android Phone or Android Emulator**

---

### Backend Setup (FastAPI)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/suraksha-ai.git
   cd suraksha-ai/backend
   ```

2. **Create and activate a Python virtual environment:**
   - **Windows:**
     ```powershell
     python -m venv venv
     .\venv\Scripts\activate
     ```
   - **macOS / Linux:**
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the 10-Step Automated Backend Test Suite:**
   ```bash
   python test_backend.py
   ```
   *(Verify that all 10 tests pass with zero errors).*

5. **Start the FastAPI Development Server:**
   ```bash
   python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```
   - Swagger Interactive Documentation: `http://localhost:8000/docs`
   - Health Check: `http://localhost:8000/health`

---

### Flutter Mobile App Setup

1. **Navigate to the project root:**
   ```bash
   cd ..
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run Flutter static analysis:**
   ```bash
   flutter analyze
   ```

4. **Run Flutter unit and widget tests:**
   ```bash
   flutter test
   ```

5. **Launch the application:**
   - On a connected Android device or emulator:
     ```bash
     flutter run
     ```

6. **Build Release / Debug APK:**
   ```bash
   flutter build apk --debug
   ```
   The generated APK will be at:
   ```
   build/app/outputs/flutter-apk/app-debug.apk
   ```

7. **Install onto connected device via ADB:**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

---

### Connecting Mobile App to Backend (Emulator vs Physical Device)

The mobile app's backend URL is configured in `lib/config/app_config.dart`:

```dart
// Default for Android Emulator loopback
static String backendBaseUrl = 'http://10.0.2.2:8000';
```

- **When testing on Android Emulator:** Use `http://10.0.2.2:8000` (Android's alias to host `localhost`).
- **When testing on a Physical Phone:**
  1. Find your computer's local Wi-Fi IP address (`ipconfig` on Windows or `ifconfig` on macOS/Linux, e.g., `192.168.1.45`).
  2. In `lib/config/app_config.dart`, set:
     ```dart
     static String backendBaseUrl = 'http://192.168.1.45:8000';
     ```
  3. Ensure both phone and PC are connected to the same Wi-Fi network.

> [!NOTE]
> **Complete Offline Mode:** If the backend server is not running, SURAKSHA AI automatically falls back to its embedded dataset of 2,500+ records and local client-side spatial algorithms.

---

## 🧪 Testing & Quality Assurance

SURAKSHA AI includes automated test suites covering both backend intelligence and client logic:

### 1. Backend Verification (`backend/test_backend.py`)
```bash
python backend/test_backend.py
```
- ✅ **Test 1:** Dataset schema validation (incidents, sources, road segments, facilities).
- ✅ **Test 2:** Location precision isolation (`AREA_ONLY` excluded from street corridors).
- ✅ **Test 3:** Scoring determinism (identical geometries generate identical scores).
- ✅ **Test 4:** 120m spatial duplicate detection on citizen hazard reports.
- ✅ **Test 5:** Verification isolation (`PENDING` submissions do not alter verified scores).
- ✅ **Test 6:** Community report lifecycle transitions (`PENDING` $\to$ `VERIFIED`).
- ✅ **Test 7:** Action-capable AI agent tool invocations & provenance explanations.
- ✅ **Test 8:** Voice-guided hands-free incident reporting.
- ✅ **Test 9:** OpenStreetMap Overpass feature importer and deduplicator.
- ✅ **Test 10:** Road-aligned synthetic scenario generator (`is_simulated: true`).

### 2. Flutter Unit & Widget Tests (`test/`)
```bash
flutter test
```
- ✅ `IncidentModel` parsing, serialization, and location precision handling.
- ✅ `IncidentModel` community pending report and lifecycle flags.
- ✅ `PublicFacilityModel` police, hospital, and emergency facility attributes.
- ✅ `RouteScoreModel` exposure density, sources consulted, and baseline metrics.
- ✅ `PhotonFeature` geocoding query parser and landmark fallback.
- ✅ `SavedLocationsService` favorites persistence and custom place creation.
- ✅ `ThemeService` Light, Dark, and System ThemeModes management.
- ✅ `LocationService` GPS initialization and mock fallback tracking.
- ✅ `RouteComparisonCardData` structured assistant response parsing.
- ✅ `WidgetSmokeTest` verifying full-screen interactive OSM map rendering.

---

## 🏆 Hackathon Live Demonstration Walkthrough

Follow this step-by-step walkthrough to present SURAKSHA AI to hackathon judges and evaluators:

| Step | Action | What to Point Out |
|---|---|---|
| **1. Zero-Cost Open Cartography** | Open the app. Observe the full-screen OpenStreetMap of Hyderabad. | Point to the bottom-right pill: `© OpenStreetMap contributors`. Emphasize **zero paid Google Maps SDKs or billing keys**. |
| **2. Live Photon Place Search** | Tap the top search bar, type `"Charminar"`, and tap the suggestion. | Highlight instant, debounced autocomplete via Komoot's open-source Photon API. The map smoothly animates to the destination. |
| **3. Interactive Map Tap** | Tap any intersection or road directly on the map. | Notice the coordinate snackbar with an instant **"Plan Road Route"** trigger. |
| **4. Road Routing via OSRM** | Tap **"Plan Road Route (OSRM)"**. | Observe that the polyline strictly follows actual drivable streets via Open Source Routing Machine (OSRM), not artificial straight lines. |
| **5. Corridor Score & Evidence** | Tap the route card badge (e.g. `Score: 18.4/100 · Low Recorded Exposure`). | Open the transparent methodology screen showing verified incident counts, weighted density per km, and the exact public sources consulted. |
| **6. Alternative Route Comparison** | Tap **"Route B: Interior Colony Shortcut"**. | Demonstrate route switching: the polyline updates, and the score reflects differing corridor hazards. |
| **7. Citizen Report & Score Isolation** | Tap **"Report Hazard"**, select `POOR_STREET_LIGHTING`, enter details, and submit. | Show that the report receives ID `COM-REP-...` with `PENDING` status. Return to the map: **prove that the verified score has not changed**, preventing false alarm manipulation. |
| **8. "My Reports" Dashboard** | Open the Navigation Drawer $\to$ **"My Reports"**. | View the citizen report timeline, showing the review lifecycle. |
| **9. Action Voice Assistant ("Suraksha")** | Tap the microphone. Ask: *"Compare these routes using recent accident records."* | Listen to Suraksha call backend tools and speak the evidence-based answer aloud in Indian English. |
| **10. Bilingual & Accessibility** | Open Drawer $\to$ **Settings**. Switch language to **తెలుగు (Telugu)** or toggle **Dark Mode**. | UI text instantly updates to Telugu with custom nighttime road contrast. |
| **11. Turn-by-Turn Handoff** | On the route card, tap **"Navigate in Google Maps"**. | Demonstrate seamless Android intent handoff opening Google Maps with prefilled coordinates. |

---

## 🚨 Emergency Protocol & Responsible AI Disclaimer

> [!CAUTION]
> **SURAKSHA AI is a route comparison and public safety research platform, NOT an emergency response or police dispatch service.**

- In any active, life-threatening emergency in India:
  - 🚨 **National Emergency / Police:** Dial **112**
  - 🛡️ **Women's Safety Wing (SHE Teams):** Dial **1091** or WhatsApp `+91 94416 69888`
  - 🚑 **Medical / Ambulance:** Dial **108**
  - 🚒 **Fire Emergency:** Dial **101**

### Responsible AI & Heuristic Limitations:
1. **Absence of Evidence is Not Evidence of Absence:** A corridor score of $10.0$ indicates zero *recorded* incidents in available police or municipal records—it is **never** a guarantee of safety.
2. **No Profiling:** Corridor scoring evaluates infrastructure (lighting audits, surveyed collision blackspots, transit proximity), never demographics or protected citizen characteristics.
3. **Data Privacy:** Community incident reporting supports full anonymity (`is_anonymous: true`) with zero device fingerprinting or background location tracking.

---

## 📄 License & Attribution

- **Source Code:** Released under the [MIT License](LICENSE).
- **Cartography & Geodata:** [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright), licensed under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
- **Geocoding:** Powered by [Photon by Komoot](https://photon.komoot.io) under the Apache 2.0 License.
- **Routing Engine:** Powered by [Project OSRM](https://project-osrm.org) under the BSD 2-Clause License.

---

<div align="center">
  <b>Built for Public Safety Innovation, Women's Transit Security, and Open-Source Geospatial Research.</b><br>
  <i>"Your Safety. Your Route. Your Power."</i>
</div>
