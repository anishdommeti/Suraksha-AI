"""
SURAKSHA AI - Upgraded Pydantic Models
Supports real-world datasets, location precision, community reporting lifecycle,
and transparent heuristic scoring.
"""
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class Incident(BaseModel):
    id: str = Field(alias="incident_id")
    category: str
    subcategory: Optional[str] = None
    description: Optional[str] = None
    incident_date: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    severity: str = "UNKNOWN"  # LOW, MEDIUM, HIGH, CRITICAL, UNKNOWN
    verification_status: str = "OFFICIAL_SOURCE"  # OFFICIAL_SOURCE, VERIFIED, NEEDS_REVIEW, PENDING, REJECTED
    source_type: str = "OFFICIAL_SOURCE"  # OFFICIAL_SOURCE, COMMUNITY_REPORT, SIMULATED
    source_name: str = "Official Record"
    source_url: Optional[str] = None
    location_precision: str = "UNKNOWN"  # EXACT, APPROXIMATE, AREA_ONLY, UNKNOWN
    first_published_at: Optional[str] = None
    last_updated: Optional[str] = None
    is_simulated: bool = False
    is_anonymous: bool = False
    photo_reference: Optional[str] = None
    review_notes: Optional[str] = None

    class Config:
        populate_by_name = True

class RouteSegment(BaseModel):
    segment_id: str
    name: str
    road_type: str
    geometry: List[List[float]] = Field(default_factory=list)
    lighting_status: str
    access_status: str
    accident_risk_level: str = "MODERATE"
    blackspot_identified: bool = False
    source_name: str
    source_url: Optional[str] = None
    last_updated: Optional[str] = None

class PublicFacility(BaseModel):
    facility_id: str
    facility_type: str  # POLICE_STATION, WOMEN_SAFETY_HUB, HOSPITAL_EMERGENCY, METRO_TRANSIT_STATION
    name: str
    jurisdiction: str
    latitude: float
    longitude: float
    contact_phone: Optional[str] = None
    source_name: str
    source_url: Optional[str] = None
    last_updated: Optional[str] = None

class RouteOption(BaseModel):
    route_id: str
    name: str
    summary: str
    distance_km: float
    duration_minutes: int
    geometry: List[List[float]] = Field(default_factory=list)
    is_simulated: bool = False
    source: str = "OSRM"

class RouteScore(BaseModel):
    route_id: str
    score: float  # Heuristic risk score 0 - 100
    score_status: str  # "calculated", "insufficient_data"
    formula_version: str = "v2.0-precision-aware-heuristic"
    verified_incident_count: int
    official_source_count: int = 0
    verified_community_count: int = 0
    pending_report_count: int
    reporting_period: str = "last_90_days"
    distance_km: float
    duration_minutes: int
    exposure_density: float
    evidence_summary: str
    limitations: str
    data_mode: str  # "REAL_AND_OFFICIAL_DATA" or "SIMULATED_DEMO_DATA"
    sources_consulted: List[str] = Field(default_factory=list)

class RouteComparison(BaseModel):
    origin: str
    destination: str
    routes: List[RouteOption]
    scores: Dict[str, RouteScore]
    recommended_route_id: Optional[str] = None
    comparison_summary: str
    limitations: str
    data_mode: str

class RouteRequest(BaseModel):
    origin: str
    destination: str

class RouteCompareRequest(BaseModel):
    origin: Optional[str] = None
    destination: Optional[str] = None
    route_ids: Optional[List[str]] = None
    category_filter: Optional[str] = None
    time_window: Optional[str] = "last_90_days"

class IncidentCreateRequest(BaseModel):
    category: str
    description: str
    latitude: float
    longitude: float
    location_precision: str = "EXACT"  # EXACT, APPROXIMATE, AREA_ONLY
    incident_datetime: Optional[str] = None
    severity_reported: str = "MEDIUM"  # LOW, MEDIUM, HIGH, CRITICAL
    is_anonymous: bool = True
    photo_reference: Optional[str] = None

class IncidentCreateResponse(BaseModel):
    report_id: str
    submission_status: str  # "SUCCESS", "DUPLICATE_FLAGGED"
    verification_status: str = "PENDING"  # strictly PENDING
    message: str
    is_duplicate_warning: bool = False
    duplicate_info: Optional[Dict[str, Any]] = None
    incident: Incident

class ReportReviewRequest(BaseModel):
    verification_status: str  # "VERIFIED", "REJECTED", "NEEDS_REVIEW"
    review_notes: str

class ToolInvocation(BaseModel):
    tool_name: str
    parameters: Dict[str, Any]
    result: Any

class AgentChatRequest(BaseModel):
    message: str
    conversation_history: Optional[List[Dict[str, str]]] = Field(default_factory=list)
    current_route_id: Optional[str] = None
    origin: Optional[str] = None
    destination: Optional[str] = None
    category_filter: Optional[str] = None

class AgentChatResponse(BaseModel):
    reply_text: str
    spoken_text: str
    tools_called: List[ToolInvocation] = Field(default_factory=list)
    suggested_actions: List[str] = Field(default_factory=list)
    routes: Optional[List[RouteOption]] = None
    scores: Optional[Dict[str, RouteScore]] = None
    selected_route_id: Optional[str] = None
    comparison_cards: Optional[List[Dict[str, Any]]] = None
    is_confirmation_prompt: bool = False
    pending_action: Optional[Dict[str, Any]] = None
    data_mode: str = "REAL_AND_OFFICIAL_DATA"
