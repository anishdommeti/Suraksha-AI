"""
SURAKSHA AI - Upgraded FastAPI Backend API Server
Supports real-world Hyderabad public safety datasets, dataset summaries,
community reporting with verification lifecycle, and action-capable AI agent.
"""
from typing import List, Dict, Optional, Any
from fastapi import FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from models import (
    RouteOption, RouteScore, RouteComparison, Incident,
    IncidentCreateRequest, IncidentCreateResponse, ReportReviewRequest,
    RouteRequest, RouteCompareRequest,
    AgentChatRequest, AgentChatResponse
)
import routing
import scoring
import data
import agent
from osm_importer import OsmImporter
import synthetic_generator

osm_service = OsmImporter()

app = FastAPI(
    title="SURAKSHA AI API",
    description="Real-world Public Safety Dataset & Intelligent Route Comparison API for Hyderabad & Telangana",
    version="2.0.0"
)

# Enable CORS for Flutter Web, Android Emulator (10.0.2.2), and LAN devices
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", tags=["System"])
async def health_check():
    """Health check endpoint to verify backend operational readiness."""
    return {
        "status": "healthy",
        "service": "SURAKSHA AI Backend",
        "version": "2.0.0",
        "branding": "SURAKSHA AI",
        "tagline": "Your Safety. Your Route. Your Power.",
        "geographic_scope": "Hyderabad & Telangana, India"
    }

# ==================== DATASET REGISTRY ENDPOINTS ====================

@app.get("/api/dataset/summary", tags=["Dataset"])
async def get_dataset_summary():
    """Returns dataset metrics, category breakdowns, source provenance, and limitations."""
    return data.get_data_summary()

@app.get("/api/dataset/sources", tags=["Dataset"])
async def get_data_sources():
    """Lists registered public safety data sources and publishers."""
    return data.get_data_sources()

@app.get("/api/dataset/facilities", tags=["Dataset"])
async def get_public_facilities():
    """Retrieves verified public facilities: Police stations, SHE Teams centres, and hospitals."""
    return data.get_facilities()

@app.get("/api/dataset/road-segments", tags=["Dataset"])
async def get_road_segments():
    """Retrieves surveyed road corridors and blackspot assessments."""
    return data.get_road_segments()

# ==================== INCIDENT & REPORTING ENDPOINTS ====================

@app.get("/api/incidents", response_model=List[Incident], tags=["Incidents"])
async def get_incidents(
    category: Optional[str] = Query(None, description="Filter by category (e.g. ROAD_ACCIDENT, WOMEN_SAFETY)"),
    status: Optional[str] = Query(None, description="Filter by verification status (OFFICIAL_SOURCE, VERIFIED, PENDING)"),
    time_window: Optional[str] = Query("all_time", description="Filter by time window: 7_days, 30_days, 90_days, all_time"),
    include_simulated: bool = Query(False, description="Whether to include isolated synthetic demo records")
):
    """Retrieve incidents with category, status, and date filtering."""
    return data.get_all_incidents(
        category_filter=category,
        verification_filter=status,
        time_window=time_window,
        include_simulated=include_simulated
    )

@app.get("/api/incidents/{incident_id}", response_model=Incident, tags=["Incidents"])
async def get_incident_by_id(incident_id: str):
    """Retrieve details of a specific incident."""
    inc = data.get_incident_by_id(incident_id)
    if not inc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Incident '{incident_id}' not found."
        )
    return inc

@app.post("/api/incidents", response_model=IncidentCreateResponse, tags=["Incidents"])
async def create_incident_report(req: IncidentCreateRequest):
    """
    Submit a citizen community report.
    - Status is strictly saved as PENDING VERIFICATION.
    - Runs duplicate check against existing incidents within 120m.
    - Never automatically modifies verified safety scores.
    """
    if not req.category.strip() or not req.description.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category and description are required."
        )

    incident, is_duplicate, duplicate_info = data.add_community_report(req)

    return IncidentCreateResponse(
        report_id=incident.id,
        submission_status="DUPLICATE_FLAGGED" if is_duplicate else "SUCCESS",
        verification_status="PENDING",
        message=(
            "Incident submitted successfully and marked PENDING VERIFICATION. "
            "Awaiting review by community moderators before contributing to official scores."
        ),
        is_duplicate_warning=is_duplicate,
        duplicate_info=duplicate_info,
        incident=incident
    )

@app.get("/api/reports/my-reports", response_model=List[Incident], tags=["Incidents"])
async def get_my_reports():
    """Retrieve community-submitted reports."""
    return data.get_community_reports()

@app.post("/api/reports/{report_id}/review", response_model=Incident, tags=["Incidents"])
async def review_report(report_id: str, req: ReportReviewRequest):
    """
    Authorized review action to transition report status:
    PENDING -> NEEDS_REVIEW -> VERIFIED or REJECTED.
    """
    updated = data.review_community_report(report_id, req.verification_status, req.review_notes)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report '{report_id}' not found."
        )
    return updated

# ==================== ROUTE PLANNING & SCORING ENDPOINTS ====================

@app.post("/api/routes", response_model=List[RouteOption], tags=["Routes"])
async def get_routes(req: RouteRequest):
    """Retrieve candidate routes between origin and destination."""
    if not req.origin.strip() or not req.destination.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Origin and destination are required."
        )
    routes = await routing.fetch_candidate_routes(req.origin, req.destination)
    return routes

@app.post("/api/routes/compare", response_model=RouteComparison, tags=["Routes"])
async def compare_routes(req: RouteCompareRequest):
    """Compare candidate routes with precision-aware deterministic heuristic risk scoring and evidence."""
    routes: List[RouteOption] = []
    if req.route_ids:
        for rid in req.route_ids:
            r = routing.get_route_by_id(rid)
            if r:
                routes.append(r)
    elif req.origin and req.destination:
        routes = await routing.fetch_candidate_routes(req.origin, req.destination)

    if not routes:
        routes = await routing.fetch_candidate_routes("Matrusri Engineering College", "Saidabad Metro")

    scores: Dict[str, RouteScore] = {}
    for r in routes:
        s = scoring.calculate_route_score(
            r.route_id, r.geometry, r.distance_km, r.duration_minutes,
            category_filter=req.category_filter,
            reporting_period=req.time_window or "last_90_days"
        )
        scores[r.route_id] = s

    best_route = min(routes, key=lambda x: scores[x.route_id].score)

    summary = (
        f"Compared {len(routes)} candidate routes. "
        f"{best_route.name} is the best-supported route based on recorded incident exposure "
        f"({scores[best_route.route_id].score}/100) with "
        f"{scores[best_route.route_id].verified_incident_count} verified record(s)."
    )

    return RouteComparison(
        origin=req.origin or "Matrusri Engineering College",
        destination=req.destination or "Saidabad Metro",
        routes=routes,
        scores=scores,
        recommended_route_id=best_route.route_id,
        comparison_summary=summary,
        limitations="Heuristic score based on recorded incidents. Low score does not guarantee safety.",
        data_mode="REAL_AND_OFFICIAL_DATA"
    )

@app.get("/api/routes/{route_id}/incidents", tags=["Routes"])
async def get_route_incidents(
    route_id: str,
    reporting_period: str = Query("last_90_days"),
    category_filter: Optional[str] = Query(None)
):
    """Retrieve verified and pending incidents along a route corridor."""
    return await agent.tool_get_route_incidents(route_id, reporting_period, category_filter)

@app.get("/api/routes/{route_id}/score", response_model=RouteScore, tags=["Routes"])
async def get_route_score(
    route_id: str,
    reporting_period: str = Query("last_90_days"),
    category_filter: Optional[str] = Query(None)
):
    """Calculate deterministic heuristic risk score for a route."""
    r = routing.get_route_by_id(route_id)
    if not r:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Route '{route_id}' not found."
        )
    return scoring.calculate_route_score(
        route_id=r.route_id,
        geometry=r.geometry,
        distance_km=r.distance_km,
        duration_minutes=r.duration_minutes,
        category_filter=category_filter,
        reporting_period=reporting_period
    )

# ==================== ACTION-CAPABLE AI AGENT ENDPOINT ====================

@app.post("/api/agent/chat", response_model=AgentChatResponse, tags=["AI Agent"])
async def agent_chat(req: AgentChatRequest):
    """
    Action-Capable AI Agent Endpoint.
    Executes backend tools, returns structured evidence, and produces spoken answers.
    """
    if not req.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message is required."
        )
    return await agent.handle_chat(req)

# ==================== OPENSTREETMAP DATA IMPORT ENDPOINTS ====================

@app.post("/api/osm/import", tags=["OpenStreetMap"])
async def import_osm_data(
    min_lat: Optional[float] = Query(None),
    min_lon: Optional[float] = Query(None),
    max_lat: Optional[float] = Query(None),
    max_lon: Optional[float] = Query(None),
    use_live_overpass: bool = Query(False, description="Query Overpass API live if enabled")
):
    """Imports OpenStreetMap features (police, hospitals, street lamps, roads) for Hyderabad."""
    bbox = None
    if min_lat is not None and min_lon is not None and max_lat is not None and max_lon is not None:
        bbox = {"min_lat": min_lat, "min_lon": min_lon, "max_lat": max_lat, "max_lon": max_lon}
    return await osm_service.import_features(bbox=bbox, use_live_overpass=use_live_overpass)

@app.get("/api/osm/summary", tags=["OpenStreetMap"])
async def get_osm_summary():
    """Returns total count and breakdown of imported OpenStreetMap features."""
    return osm_service.get_summary()

@app.get("/api/osm/features", tags=["OpenStreetMap"])
async def get_osm_features():
    """Retrieves all imported OpenStreetMap geographic features."""
    return osm_service.get_all_features()

# ==================== SYNTHETIC DEMO DATA ENDPOINTS ====================

class SyntheticGenRequest(BaseModel):
    count: int = 25
    seed: int = 42

@app.post("/api/dataset/generate-synthetic", tags=["Synthetic Data"])
async def generate_synthetic_incidents(req: SyntheticGenRequest):
    """Generates road-aligned synthetic incidents clearly flagged is_simulated=true."""
    return synthetic_generator.generate_synthetic_dataset(count=req.count, seed=req.seed)

@app.post("/api/dataset/reset-synthetic", tags=["Synthetic Data"])
async def reset_synthetic_incidents():
    """Resets synthetic incidents back to standard demo baseline."""
    return synthetic_generator.reset_synthetic_dataset()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
