# SURAKSHA AI — Public Safety Dataset Documentation

## 1. Overview & Provenance

SURAKSHA AI maintains structured, traceable datasets of road accidents, women's safety incidents, and municipal infrastructure reports for **Hyderabad and Telangana, India**.

The system strictly enforces the separation of:
1. **Official Sources (`OFFICIAL_SOURCE`):** Published police statistics, municipal lighting audits, and OpenCity road accident studies.
2. **Community Reports (`COMMUNITY_REPORT`):** Citizen-submitted reports that begin in a `PENDING` state and require verification.
3. **Simulated Demonstrations (`SIMULATED`):** Explicitly flagged synthetic records (`is_simulated: true`) used for offline testing.

---

## 2. Dataset Files

| File | Purpose | Primary Sources |
|---|---|---|
| `data/incidents.csv` | Master catalog of verified & official incident records | Hyderabad Traffic Police, Telangana SHE Teams, GHMC, OpenCity |
| `data/data_sources.json` | Registry of all imported datasets with licensing and coverage | Telangana Police, GHMC, OpenCity, NCRB |
| `data/road_segments.json` | Corridors with known illumination and accident risk levels | Hyderabad Traffic Police, GHMC Darkness Surveys |
| `data/places.json` | Public safety facilities (Police stations, SHE Teams, hospitals) | Telangana Police Directory, DHS Telangana |
| `data/demo_incidents.json` | Isolated fixtures for hackathon scenario testing | Internal mock fixtures |
| `data/community_reports.json` | Persistent local store for user-submitted community reports | Mobile user submissions |

---

## 3. Incident Schema & Location Precision

Each record conforms to the standardized schema:

```json
{
  "incident_id": "OFF-HYD-ACC-2024-001",
  "category": "ROAD_ACCIDENT",
  "subcategory": "Pedestrian Collision",
  "incident_date": "2024-02-18",
  "latitude": 17.3712,
  "longitude": 78.5028,
  "severity": "HIGH",
  "verification_status": "OFFICIAL_SOURCE",
  "source_type": "OFFICIAL_SOURCE",
  "source_name": "Hyderabad Traffic Police Annual Audit",
  "source_url": "https://htp.telangana.gov.in",
  "location_precision": "EXACT",
  "first_published_at": "2024-03-01",
  "last_updated": "2024-12-31",
  "is_simulated": false
}
```

### Supported Location Precisions:
- `EXACT`: GPS-confirmed survey or municipal maintenance pole coordinates.
- `APPROXIMATE`: Junction, landmark, or corridor mid-point estimation.
- `AREA_ONLY`: Station-level or ward-level aggregate data (not plotted as false exact points on the map).
- `UNKNOWN`: Insufficient spatial evidence.

---

## 4. Community Reporting & Verification Lifecycle

```
[User Submits Report] ──> Status: PENDING (Default)
                               │
                               ├──> Evaluated by Review Workflow ──> Status: NEEDS_REVIEW
                               │                                           │
                               ├──> Verified by Municipal Audit   ──> Status: VERIFIED (Scores updated)
                               │
                               └──> Found Duplicate / Invalid     ──> Status: REJECTED (Excluded from scores)
```

**Critical Integrity Rules:**
- New submissions **NEVER** automatically contribute to verified risk scores.
- Unverified submissions are labelled with a blue `[Pending Verification]` badge.
- Rejected reports are strictly discarded.

---

## 5. Emergency Protocol

SURAKSHA AI is **not** an emergency dispatch service. For life-threatening emergencies in India:
- **Police Emergency:** Dial **112**
- **Women Safety Wing (SHE Teams):** Dial **100** / **112** or WhatsApp: `+91 94416 69888`
- **Medical Emergency / Ambulance:** Dial **108**

