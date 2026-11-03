"""
SURAKSHA AI - Live Incident Store & Community Report Repository
Integrates real-world Hyderabad incident datasets with persistent community reports.
"""
import os
import uuid
import json
import logging
from datetime import datetime, timezone, timedelta
from typing import List, Dict, Optional, Any, Tuple

from models import Incident, IncidentCreateRequest
from data_loader import DatasetLoader, DATA_DIR

logger = logging.getLogger(__name__)

# Category weights for deterministic heuristic scoring
CATEGORY_WEIGHTS: Dict[str, float] = {
    "ASSAULT": 3.5,
    "HARASSMENT": 3.0,
    "WOMEN_SAFETY": 3.0,
    "ROAD_ACCIDENT": 2.5,
    "UNSAFE_OR_ISOLATED_AREA": 2.0,
    "POOR_STREET_LIGHTING": 1.5,
    "THEFT": 1.5,
    "TRAFFIC_HAZARD": 1.5,
    "ROAD_OBSTRUCTION": 1.0,
    "OTHER_PUBLIC_SAFETY": 1.0,
}

COMMUNITY_REPORTS_FILE = os.path.join(DATA_DIR, "community_reports.json")

loader = DatasetLoader()
loader.load_all()

# Load community reports from persistent store
COMMUNITY_REPORTS: List[Dict[str, Any]] = []

def _load_persisted_community_reports():
    global COMMUNITY_REPORTS
    if os.path.exists(COMMUNITY_REPORTS_FILE):
        try:
            with open(COMMUNITY_REPORTS_FILE, "r", encoding="utf-8") as f:
                COMMUNITY_REPORTS = json.load(f)
                logger.info(f"Loaded {len(COMMUNITY_REPORTS)} community reports from disk.")
        except Exception as e:
            logger.error(f"Error loading community reports file: {e}")
            COMMUNITY_REPORTS = []
    else:
        COMMUNITY_REPORTS = []

def _save_persisted_community_reports():
    try:
        with open(COMMUNITY_REPORTS_FILE, "w", encoding="utf-8") as f:
            json.dump(COMMUNITY_REPORTS, f, indent=2)
    except Exception as e:
        logger.error(f"Error saving community reports to disk: {e}")

_load_persisted_community_reports()

def get_all_incidents(
    category_filter: Optional[str] = None,
    verification_filter: Optional[str] = None,
    time_window: Optional[str] = None,  # "7_days", "30_days", "90_days", "all_time"
    include_simulated: bool = False
) -> List[Incident]:
    """Retrieves all combined incidents matching filters."""
    combined_raw = list(loader.incidents) + list(COMMUNITY_REPORTS)
    if include_simulated:
        combined_raw.extend(loader.demo_incidents)

    results: List[Incident] = []
    now = datetime.now(timezone.utc)

    for item in combined_raw:
        # Category filter
        if category_filter and category_filter != "ALL":
            cat_norm = category_filter.strip().upper().replace(" ", "_")
            if item.get("category") != cat_norm:
                continue

        # Verification filter
        status = item.get("verification_status", "OFFICIAL_SOURCE")
        if verification_filter and verification_filter != "ALL":
            if status != verification_filter:
                continue

        # Time window filter
        if time_window and time_window != "all_time":
            d_str = item.get("incident_date") or item.get("first_published_at")
            if d_str:
                try:
                    d_obj = datetime.fromisoformat(d_str.replace("Z", "+00:00"))
                    diff = (now - d_obj).days
                    if time_window == "7_days" and diff > 7:
                        continue
                    elif time_window == "30_days" and diff > 30:
                        continue
                    elif time_window == "90_days" and diff > 90:
                        continue
                except Exception:
                    pass

        try:
            results.append(Incident(**item))
        except Exception as e:
            logger.warning(f"Error parsing incident: {e}")

    return results

def get_incident_by_id(incident_id: str) -> Optional[Incident]:
    target = incident_id.strip().lower()
    for item in loader.incidents + COMMUNITY_REPORTS + loader.demo_incidents:
        if item.get("incident_id", "").lower() == target:
            return Incident(**item)
    return None

def add_community_report(req: IncidentCreateRequest) -> Tuple[Incident, bool, Optional[Dict[str, Any]]]:
    """
    Submits a community incident report.
    - Status is STRICTLY PENDING.
    - Runs duplicate check against existing incidents.
    - Saves to disk.
    """
    rep_id = f"COM-REP-{uuid.uuid4().hex[:6].upper()}"
    now_iso = datetime.now(timezone.utc).isoformat()
    norm_cat = req.category.strip().upper().replace(" ", "_")
    if norm_cat not in CATEGORY_WEIGHTS:
        norm_cat = "OTHER_PUBLIC_SAFETY"

    candidate = {
        "incident_id": rep_id,
        "category": norm_cat,
        "subcategory": "Community User Submission",
        "description": req.description,
        "incident_date": req.incident_datetime or now_iso[:10],
        "latitude": req.latitude,
        "longitude": req.longitude,
        "severity": req.severity_reported.upper(),
        "verification_status": "PENDING",  # Strictly PENDING VERIFICATION!
        "source_type": "COMMUNITY_REPORT",
        "source_name": "SURAKSHA AI Citizen Commuter Report",
        "source_url": "https://suraksha.ai/community",
        "location_precision": req.location_precision.upper(),
        "first_published_at": now_iso,
        "last_updated": now_iso,
        "is_simulated": False,
        "is_anonymous": req.is_anonymous,
        "photo_reference": req.photo_reference,
        "review_notes": "Awaiting initial review by community safety moderator."
    }

    # Duplicate check
    duplicate_info = loader.detect_duplicate(candidate)
    is_duplicate = duplicate_info is not None

    COMMUNITY_REPORTS.append(candidate)
    _save_persisted_community_reports()

    return Incident(**candidate), is_duplicate, duplicate_info

def review_community_report(report_id: str, new_status: str, review_notes: str) -> Optional[Incident]:
    """Updates verification status of a community report (VERIFIED, REJECTED, NEEDS_REVIEW)."""
    target = report_id.strip().lower()
    for item in COMMUNITY_REPORTS:
        if item.get("incident_id", "").lower() == target:
            item["verification_status"] = new_status.upper()
            item["review_notes"] = review_notes
            item["last_updated"] = datetime.now(timezone.utc).isoformat()
            _save_persisted_community_reports()
            return Incident(**item)
    return None

def get_community_reports() -> List[Incident]:
    return [Incident(**c) for c in COMMUNITY_REPORTS]

def get_data_summary() -> Dict[str, Any]:
    return loader.generate_summary()

def get_facilities() -> List[Dict[str, Any]]:
    return loader.places

def get_road_segments() -> List[Dict[str, Any]]:
    return loader.road_segments

def get_data_sources() -> List[Dict[str, Any]]:
    return loader.sources
