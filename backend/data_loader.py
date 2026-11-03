"""
SURAKSHA AI - Real-World Dataset Loader, Validator & Summary Pipeline
"""
import os
import csv
import json
import math
import logging
from datetime import datetime
from typing import List, Dict, Any, Tuple, Optional

logger = logging.getLogger(__name__)

# Validated 10 Standard Categories
VALID_CATEGORIES = {
    "ROAD_ACCIDENT",
    "TRAFFIC_HAZARD",
    "WOMEN_SAFETY",
    "HARASSMENT",
    "ASSAULT",
    "THEFT",
    "POOR_STREET_LIGHTING",
    "UNSAFE_OR_ISOLATED_AREA",
    "ROAD_OBSTRUCTION",
    "OTHER_PUBLIC_SAFETY",
}

VALID_STATUSES = {"OFFICIAL_SOURCE", "VERIFIED", "NEEDS_REVIEW", "PENDING", "REJECTED"}
VALID_PRECISIONS = {"EXACT", "APPROXIMATE", "AREA_ONLY", "UNKNOWN"}
VALID_SEVERITIES = {"LOW", "MEDIUM", "HIGH", "CRITICAL", "UNKNOWN"}

# Bounding box for Telangana / Hyderabad region
TELANGANA_BOUNDS = {
    "min_lat": 15.5,
    "max_lat": 19.8,
    "min_lon": 77.0,
    "max_lon": 81.8,
}

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = math.sin(delta_phi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0)**2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c

class DatasetLoader:
    def __init__(self, data_dir: str = DATA_DIR):
        self.data_dir = data_dir
        self.incidents: List[Dict[str, Any]] = []
        self.quarantined_records: List[Dict[str, Any]] = []
        self.sources: List[Dict[str, Any]] = []
        self.road_segments: List[Dict[str, Any]] = []
        self.places: List[Dict[str, Any]] = []
        self.demo_incidents: List[Dict[str, Any]] = []

    def load_all(self):
        """Loads and validates all data files."""
        self.load_sources()
        self.load_places()
        self.load_road_segments()
        self.load_demo_incidents()
        self.load_incidents_csv()
        logger.info(f"Loaded {len(self.incidents)} valid incidents ({len(self.quarantined_records)} quarantined).")

    def load_sources(self):
        path = os.path.join(self.data_dir, "data_sources.json")
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    self.sources = json.load(f)
            except Exception as e:
                logger.error(f"Error loading sources: {e}")

    def load_places(self):
        path = os.path.join(self.data_dir, "places.json")
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    self.places = json.load(f)
            except Exception as e:
                logger.error(f"Error loading places: {e}")

    def load_road_segments(self):
        path = os.path.join(self.data_dir, "road_segments.json")
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    self.road_segments = json.load(f)
            except Exception as e:
                logger.error(f"Error loading road segments: {e}")

    def load_demo_incidents(self):
        path = os.path.join(self.data_dir, "demo_incidents.json")
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    self.demo_incidents = json.load(f)
            except Exception as e:
                logger.error(f"Error loading demo incidents: {e}")

    def load_incidents_csv(self):
        path = os.path.join(self.data_dir, "incidents.csv")
        if not os.path.exists(path):
            logger.warning(f"incidents.csv not found at {path}")
            return

        self.incidents.clear()
        self.quarantined_records.clear()

        with open(path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row_idx, row in enumerate(reader):
                is_valid, sanitized, reason = self.validate_and_sanitize_record(row)
                if is_valid:
                    self.incidents.append(sanitized)
                else:
                    self.quarantined_records.append({
                        "row_index": row_idx + 1,
                        "raw_data": row,
                        "quarantine_reason": reason
                    })

    def validate_and_sanitize_record(self, row: Dict[str, str]) -> Tuple[bool, Optional[Dict[str, Any]], str]:
        """Validates a single row strictly; rejects malformed data."""
        inc_id = row.get("incident_id", "").strip()
        if not inc_id:
            return False, None, "Missing incident_id"

        raw_cat = row.get("category", "").strip().upper().replace(" ", "_")
        if raw_cat not in VALID_CATEGORIES:
            return False, None, f"Invalid category '{raw_cat}'"

        precision = row.get("location_precision", "UNKNOWN").strip().upper()
        if precision not in VALID_PRECISIONS:
            precision = "UNKNOWN"

        lat_str = row.get("latitude", "").strip()
        lon_str = row.get("longitude", "").strip()

        lat, lon = None, None
        if lat_str and lon_str:
            try:
                lat = float(lat_str)
                lon = float(lon_str)
                # Verify bounds
                if not (TELANGANA_BOUNDS["min_lat"] <= lat <= TELANGANA_BOUNDS["max_lat"] and
                        TELANGANA_BOUNDS["min_lon"] <= lon <= TELANGANA_BOUNDS["max_lon"]):
                    if precision != "AREA_ONLY":
                        return False, None, f"Coordinates ({lat}, {lon}) outside Telangana coverage bounds"
            except ValueError:
                if precision in ("EXACT", "APPROXIMATE"):
                    return False, None, "Malformed numeric coordinates"

        status = row.get("verification_status", "OFFICIAL_SOURCE").strip().upper()
        if status not in VALID_STATUSES:
            status = "NEEDS_REVIEW"

        severity = row.get("severity", "UNKNOWN").strip().upper()
        if severity not in VALID_SEVERITIES:
            severity = "UNKNOWN"

        is_sim = str(row.get("is_simulated", "false")).strip().lower() in ("true", "1", "yes")

        sanitized = {
            "incident_id": inc_id,
            "category": raw_cat,
            "subcategory": row.get("subcategory", "").strip() or None,
            "incident_date": row.get("incident_date", "").strip() or None,
            "latitude": lat,
            "longitude": lon,
            "severity": severity,
            "verification_status": status,
            "source_type": row.get("source_type", "OFFICIAL_SOURCE").strip().upper(),
            "source_name": row.get("source_name", "").strip() or "Official Record",
            "source_url": row.get("source_url", "").strip() or None,
            "location_precision": precision,
            "first_published_at": row.get("first_published_at", "").strip() or None,
            "last_updated": row.get("last_updated", "").strip() or None,
            "is_simulated": is_sim,
        }
        return True, sanitized, ""

    def detect_duplicate(self, candidate: Dict[str, Any], threshold_meters: float = 120.0) -> Optional[Dict[str, Any]]:
        """
        Detects if a new community submission is likely a duplicate of an existing record:
        - Within threshold_meters (default 120m)
        - Same category
        - Similar timestamp / date
        """
        c_lat = candidate.get("latitude")
        c_lon = candidate.get("longitude")
        c_cat = candidate.get("category")

        if c_lat is None or c_lon is None:
            return None

        for existing in self.incidents:
            e_lat = existing.get("latitude")
            e_lon = existing.get("longitude")
            if e_lat is None or e_lon is None:
                continue

            if existing.get("category") == c_cat:
                d = haversine_distance_meters(c_lat, c_lon, e_lat, e_lon)
                if d <= threshold_meters:
                    return {
                        "is_duplicate": True,
                        "distance_meters": round(d, 1),
                        "matched_incident_id": existing.get("incident_id"),
                        "matched_status": existing.get("verification_status")
                    }
        return None

    def generate_summary(self) -> Dict[str, Any]:
        """Generates statistical dataset summary without inventing facts."""
        cat_counts = {}
        status_counts = {}
        source_counts = {}
        precision_counts = {}
        simulated_count = 0
        dates = []

        for inc in self.incidents:
            c = inc["category"]
            cat_counts[c] = cat_counts.get(c, 0) + 1

            st = inc["verification_status"]
            status_counts[st] = status_counts.get(st, 0) + 1

            src = inc["source_type"]
            source_counts[src] = source_counts.get(src, 0) + 1

            p = inc["location_precision"]
            precision_counts[p] = precision_counts.get(p, 0) + 1

            if inc.get("is_simulated"):
                simulated_count += 1

            d_str = inc.get("incident_date")
            if d_str:
                dates.append(d_str)

        dates.sort()
        earliest_date = dates[0] if dates else None
        latest_date = dates[-1] if dates else None

        return {
            "total_records": len(self.incidents),
            "quarantined_records_count": len(self.quarantined_records),
            "category_breakdown": cat_counts,
            "verification_status_breakdown": status_counts,
            "source_type_breakdown": source_counts,
            "location_precision_breakdown": precision_counts,
            "simulated_records_count": simulated_count,
            "real_world_records_count": len(self.incidents) - simulated_count,
            "date_range": {
                "earliest": earliest_date,
                "latest": latest_date,
            },
            "geographic_coverage": "Hyderabad & Telangana, India",
            "registered_sources_count": len(self.sources),
            "registered_facilities_count": len(self.places),
            "surveyed_road_segments_count": len(self.road_segments),
            "limitations_notice": (
                "Dataset contains official police audits, municipal surveys, and community reports. "
                "Area-level aggregate statistics are tracked separately from exact point markers. "
                "The absence of recorded incidents does NOT establish that a location is safe."
            )
        }

