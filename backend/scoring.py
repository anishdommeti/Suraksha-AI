"""
SURAKSHA AI - Upgraded Precision-Aware Deterministic Heuristic Scoring Engine
"""
import math
from typing import List, Tuple, Dict, Any, Optional
from models import RouteScore, Incident
from data import get_all_incidents, CATEGORY_WEIGHTS

CORRIDOR_THRESHOLD_EXACT_METERS = 200.0
CORRIDOR_THRESHOLD_APPROX_METERS = 280.0

def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = math.sin(delta_phi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0)**2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c

def distance_point_to_segment_meters(p_lat: float, p_lon: float,
                                     s1_lat: float, s1_lon: float,
                                     s2_lat: float, s2_lon: float) -> float:
    d_s1 = haversine_distance_meters(p_lat, p_lon, s1_lat, s1_lon)
    d_s2 = haversine_distance_meters(p_lat, p_lon, s2_lat, s2_lon)
    d_seg = haversine_distance_meters(s1_lat, s1_lon, s2_lat, s2_lon)

    if d_seg == 0:
        return d_s1

    avg_lat = math.radians((s1_lat + s2_lat) / 2.0)
    kx = 111320.0 * math.cos(avg_lat)
    ky = 110540.0

    x = (p_lon - s1_lon) * kx
    y = (p_lat - s1_lat) * ky
    dx = (s2_lon - s1_lon) * kx
    dy = (s2_lat - s1_lat) * ky

    dot = x * dx + y * dy
    seg_len_sq = dx * dx + dy * dy

    t = max(0.0, min(1.0, dot / seg_len_sq))
    proj_x = t * dx
    proj_y = t * dy

    return math.sqrt((x - proj_x)**2 + (y - proj_y)**2)

def get_incidents_for_geometry(
    geometry: List[List[float]],
    category_filter: Optional[str] = None,
    time_window: Optional[str] = "last_90_days",
    include_simulated: bool = False
) -> Tuple[List[Incident], List[Incident], List[Incident]]:
    """
    Finds incidents within corridor of route geometry.
    Returns: (official_sources, verified_community, pending_community)
    Respects location precision:
    - AREA_ONLY records are excluded from point corridor matching to prevent false precision.
    - REJECTED reports are discarded.
    """
    all_incidents = get_all_incidents(
        category_filter=category_filter,
        time_window=time_window,
        include_simulated=include_simulated
    )

    official_matches = []
    verified_comm_matches = []
    pending_comm_matches = []

    if not geometry or len(geometry) < 2:
        return official_matches, verified_comm_matches, pending_comm_matches

    # Fast Bounding-Box Pre-filter to eliminate distant incidents efficiently
    min_lat = min(pt[0] for pt in geometry) - 0.0035
    max_lat = max(pt[0] for pt in geometry) + 0.0035
    min_lon = min(pt[1] for pt in geometry) - 0.0035
    max_lon = max(pt[1] for pt in geometry) + 0.0035

    for inc in all_incidents:
        if inc.verification_status == "REJECTED":
            continue

        # Area-only records do not have exact coordinates to match to individual streets
        if inc.location_precision == "AREA_ONLY" or inc.latitude is None or inc.longitude is None:
            continue

        # Check bounding box
        if not (min_lat <= inc.latitude <= max_lat and min_lon <= inc.longitude <= max_lon):
            continue

        threshold = (CORRIDOR_THRESHOLD_EXACT_METERS
                     if inc.location_precision == "EXACT"
                     else CORRIDOR_THRESHOLD_APPROX_METERS)

        min_dist = float("inf")
        for i in range(len(geometry) - 1):
            s1 = geometry[i]
            s2 = geometry[i + 1]
            d = distance_point_to_segment_meters(inc.latitude, inc.longitude, s1[0], s1[1], s2[0], s2[1])
            if d < min_dist:
                min_dist = d
            if min_dist <= threshold:
                break

        if min_dist <= threshold:
            if inc.verification_status == "OFFICIAL_SOURCE":
                official_matches.append(inc)
            elif inc.verification_status == "VERIFIED":
                verified_comm_matches.append(inc)
            elif inc.verification_status in ("PENDING", "NEEDS_REVIEW"):
                pending_comm_matches.append(inc)

    return official_matches, verified_comm_matches, pending_comm_matches

def calculate_route_score(
    route_id: str,
    geometry: List[List[float]],
    distance_km: float,
    duration_minutes: int,
    category_filter: Optional[str] = None,
    reporting_period: str = "last_90_days",
    include_simulated: bool = False
) -> RouteScore:
    """
    Precision-Aware Deterministic Heuristic Scoring:
    1. Corridor matching (200m exact / 280m approximate). Area-only records excluded from corridor match.
    2. Weights verified incidents by category. Approximate locations scaled by 0.85.
    3. Exposure normalization: Weighted Verified Incidents / Max(distance_km, 0.5 km).
    4. Pending community reports tracked separately without altering verified score.
    5. Rejected reports discarded.
    """
    if not geometry:
        return RouteScore(
            route_id=route_id,
            score=0.0,
            score_status="insufficient_data",
            formula_version="v2.0-precision-aware-heuristic",
            verified_incident_count=0,
            official_source_count=0,
            verified_community_count=0,
            pending_report_count=0,
            reporting_period=reporting_period,
            distance_km=distance_km,
            duration_minutes=duration_minutes,
            exposure_density=0.0,
            evidence_summary="Route geometry was not available to compute spatial corridor exposure.",
            limitations="Score could not be computed without spatial geometry.",
            data_mode="REAL_AND_OFFICIAL_DATA"
        )

    official, verified_comm, pending = get_incidents_for_geometry(
        geometry,
        category_filter=category_filter,
        time_window=reporting_period,
        include_simulated=include_simulated
    )

    # Compute weighted verified incidents
    weighted_sum = 0.0
    sources_consulted = set()

    for inc in official:
        weight = CATEGORY_WEIGHTS.get(inc.category, 1.0)
        precision_mult = 1.0 if inc.location_precision == "EXACT" else 0.85
        weighted_sum += (weight * precision_mult)
        sources_consulted.add(inc.source_name)

    for inc in verified_comm:
        weight = CATEGORY_WEIGHTS.get(inc.category, 1.0)
        precision_mult = 1.0 if inc.location_precision == "EXACT" else 0.85
        weighted_sum += (weight * precision_mult)
        sources_consulted.add(inc.source_name)

    for inc in pending:
        sources_consulted.add(inc.source_name)

    total_verified = len(official) + len(verified_comm)
    effective_dist = max(distance_km, 0.5)
    exposure_density = round(weighted_sum / effective_dist, 2)

    if total_verified == 0:
        score = 8.0  # Baseline low score
        evidence = f"0 verified incidents recorded along {distance_km:.1f} km corridor in {reporting_period}."
    else:
        score = min(100.0, round(10.0 + (exposure_density * 20.0), 1))
        evidence = (
            f"{total_verified} verified incidents ({len(official)} official sources, {len(verified_comm)} verified community) "
            f"along {distance_km:.1f} km corridor (weighted density: {exposure_density:.2f}/km)."
        )

    if len(pending) > 0:
        evidence += f" Note: {len(pending)} community report(s) are pending review and excluded from verified score."

    limitations = (
        "Calculated using spatial corridor matching (200m exact, 280m approximate). "
        "Area-level aggregate statistics are excluded from street-level corridor scores to prevent false precision. "
        "A lower score indicates fewer recorded incidents, NOT guaranteed safety."
    )

    return RouteScore(
        route_id=route_id,
        score=score,
        score_status="calculated",
        formula_version="v2.0-precision-aware-heuristic",
        verified_incident_count=total_verified,
        official_source_count=len(official),
        verified_community_count=len(verified_comm),
        pending_report_count=len(pending),
        reporting_period=reporting_period,
        distance_km=distance_km,
        duration_minutes=duration_minutes,
        exposure_density=exposure_density,
        evidence_summary=evidence,
        limitations=limitations,
        data_mode="REAL_AND_OFFICIAL_DATA" if not include_simulated else "SIMULATED_DEMO_DATA",
        sources_consulted=list(sources_consulted)
    )
