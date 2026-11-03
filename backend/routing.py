"""
SURAKSHA AI - Routing Service with OSRM Client and Demonstration Fixtures
"""
import httpx
import logging
from typing import List, Dict, Optional, Tuple
from models import RouteOption

logger = logging.getLogger(__name__)

# Global cache of active routes so tools can fetch details by route_id
ACTIVE_ROUTES: Dict[str, RouteOption] = {}

# Demonstration Coordinates for Hyderabad demo:
# Matrusri Engineering College: 17.3596, 78.5085
# Saidabad / Malakpet Metro Station: 17.3753, 78.4908

DEMO_COORDINATES = {
    "matrusri": (17.3596, 78.5085),
    "college": (17.3596, 78.5085),
    "metro": (17.3753, 78.4908),
    "saidabad metro": (17.3753, 78.4908),
    "saidabad": (17.3680, 78.5050),
    "malakpet": (17.3760, 78.4900)
}

def generate_demo_routes(origin_name: str, dest_name: str) -> List[RouteOption]:
    """Generates deterministic, realistic candidate routes for demo."""
    # Route 1: Main Arterial (Recommended, Safer)
    r1_geom = [
        [17.3596, 78.5085], # Matrusri
        [17.3610, 78.5090],
        [17.3645, 78.5088], # Saidabad Main road
        [17.3685, 78.5075],
        [17.3712, 78.5028], # Near INC-005 (Road Obstruction)
        [17.3735, 78.4965],
        [17.3753, 78.4908], # Saidabad Metro
    ]
    r1 = RouteOption(
        route_id="route_arterial_saidabad",
        name="Route A: Main Arterial via Saidabad Main Rd",
        summary="Commercial corridor with active traffic and commercial frontage.",
        distance_km=2.6,
        duration_minutes=9,
        geometry=r1_geom,
        is_simulated=True,
        source="Demonstration Fixture"
    )

    # Route 2: Interior Colony Shortcut (Higher Incident Density)
    r2_geom = [
        [17.3596, 78.5085], # Matrusri
        [17.3615, 78.5060],
        [17.3642, 78.5041], # Near INC-001 (Poor Lighting)
        [17.3661, 78.5015], # Near INC-003 (Deserted Stretch)
        [17.3685, 78.4988], # Near INC-002 (Harassment)
        [17.3698, 78.4962], # Near INC-004 (Poor Lighting)
        [17.3753, 78.4908], # Saidabad Metro
    ]
    r2 = RouteOption(
        route_id="route_colony_bypass",
        name="Route B: Interior Colony Shortcut via Singareni",
        summary="Shorter distance but traverses isolated residential back-alleys.",
        distance_km=2.1,
        duration_minutes=7,
        geometry=r2_geom,
        is_simulated=True,
        source="Demonstration Fixture"
    )

    # Route 3: Transit Link via IS Sadan Jn
    r3_geom = [
        [17.3596, 78.5085], # Matrusri
        [17.3580, 78.5110],
        [17.3620, 78.5125], # IS Sadan Jn
        [17.3680, 78.5100],
        [17.3720, 78.5030],
        [17.3745, 78.4960],
        [17.3753, 78.4908], # Saidabad Metro
    ]
    r3 = RouteOption(
        route_id="route_transit_is_sadan",
        name="Route C: Link via IS Sadan Junction",
        summary="Longer route with divided carriageway and streetlights.",
        distance_km=3.1,
        duration_minutes=12,
        geometry=r3_geom,
        is_simulated=True,
        source="Demonstration Fixture"
    )

    routes = [r1, r2, r3]
    for r in routes:
        ACTIVE_ROUTES[r.route_id] = r
    return routes

async def geocode_place(query: str) -> Optional[Tuple[float, float]]:
    """Tries resolving place name via Nominatim with demo fallback."""
    q_lower = query.lower().strip()
    for key, coords in DEMO_COORDINATES.items():
        if key in q_lower:
            return coords

    try:
        url = "https://nominatim.openstreetmap.org/search"
        params = {"q": query, "format": "json", "limit": 1}
        headers = {"User-Agent": "SurakshaAI-HackathonDemo/1.0"}
        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.get(url, params=params, headers=headers)
            if resp.status_code == 200:
                data = resp.json()
                if data and len(data) > 0:
                    return (float(data[0]["lat"]), float(data[0]["lon"]))
    except Exception as e:
        logger.warning(f"Geocoding network error: {e}")

    # Fallback default coordinates
    return (17.3596, 78.5085)

async def fetch_candidate_routes(origin: str, destination: str) -> List[RouteOption]:
    """
    Fetches candidate routes.
    If origin/destination match demo or external OSRM fails, returns deterministic demonstration routes.
    """
    orig_lower = origin.lower()
    dest_lower = destination.lower()

    # If demo keywords or generic query, return robust demo routes
    if ("matrusri" in orig_lower or "college" in orig_lower or
        "metro" in dest_lower or "saidabad" in dest_lower):
        return generate_demo_routes(origin, destination)

    # Otherwise attempt live OSRM
    orig_coords = await geocode_place(origin)
    dest_coords = await geocode_place(destination)

    if not orig_coords or not dest_coords:
        return generate_demo_routes(origin, destination)

    try:
        # OSRM coordinate order is lng,lat
        osrm_url = (f"http://router.project-osrm.org/route/v1/driving/"
                    f"{orig_coords[1]},{orig_coords[0]};{dest_coords[1]},{dest_coords[0]}"
                    f"?overview=full&geometries=geojson&alternatives=true")

        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(osrm_url)
            if resp.status_code == 200:
                data = resp.json()
                osrm_routes = data.get("routes", [])
                if osrm_routes:
                    result = []
                    for idx, r in enumerate(osrm_routes):
                        dist_km = round(r["distance"] / 1000.0, 2)
                        dur_min = int(round(r["duration"] / 60.0))
                        # GeoJSON coordinates are [lng, lat], convert to [lat, lng]
                        coords = [[pt[1], pt[0]] for pt in r["geometry"]["coordinates"]]
                        route_id = f"live_route_{idx + 1}"
                        opt = RouteOption(
                            route_id=route_id,
                            name=f"Route {chr(65 + idx)}: Direct via Primary Road",
                            summary=f"OSRM live navigation route ({dist_km} km).",
                            distance_km=dist_km,
                            duration_minutes=dur_min,
                            geometry=coords,
                            is_simulated=False,
                            source="OSRM"
                        )
                        result.append(opt)
                        ACTIVE_ROUTES[route_id] = opt
                    return result
    except Exception as e:
        logger.warning(f"OSRM live routing error: {e}. Falling back to demo routes.")

    return generate_demo_routes(origin, destination)

def get_route_by_id(route_id: str) -> Optional[RouteOption]:
    if route_id in ACTIVE_ROUTES:
        return ACTIVE_ROUTES[route_id]
    # Check if demo route can be restored
    demo_routes = generate_demo_routes("Matrusri", "Metro")
    for r in demo_routes:
        if r.route_id == route_id:
            return r
    return None

