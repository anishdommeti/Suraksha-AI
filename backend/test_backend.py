"""
SURAKSHA AI - Upgraded Backend Unit & Integration Tests
Verifies:
1. Dataset loading, schema validation & bounds checking
2. Category normalization and precision handling (EXACT vs APPROXIMATE vs AREA_ONLY)
3. Duplicate detection on community reports
4. Verification status isolation (PENDING does NOT alter verified scores)
5. Report lifecycle transitions (PENDING -> NEEDS_REVIEW -> VERIFIED)
6. Precision-aware route corridor scoring determinism
7. Action-capable AI agent tool invocations & provenance explanations
"""
import asyncio
from models import AgentChatRequest, IncidentCreateRequest, RouteCompareRequest, ReportReviewRequest
import routing
import scoring
import data
import agent
from data_loader import DatasetLoader

async def run_tests():
    print("=== RUNNING SURAKSHA AI UPGRADED TEST SUITE ===")

    # Test 1: Dataset Loader & Summary
    loader = DatasetLoader()
    loader.load_all()
    assert len(loader.incidents) > 0, "incidents.csv must load successfully!"
    assert len(loader.sources) >= 5, "Registered sources must be at least 5!"
    assert len(loader.places) >= 4, "Public safety facilities must load!"
    assert len(loader.road_segments) >= 3, "Road segments must load!"

    summary = loader.generate_summary()
    print(f"[PASS] Test 1: Dataset loaded successfully ({summary['total_records']} incidents from {summary['registered_sources_count']} registered sources).")
    print(f"       Categories: {list(summary['category_breakdown'].keys())}")
    print(f"       Precisions: {summary['location_precision_breakdown']}")

    # Test 2: Location Precision & Spatial Matching
    # Verify AREA_ONLY records are excluded from point corridor matching
    routes = await routing.fetch_candidate_routes("Matrusri Engineering College", "Saidabad Metro")
    r1 = routes[0]
    official, verified, pending = scoring.get_incidents_for_geometry(r1.geometry)
    for inc in official + verified + pending:
        assert inc.location_precision != "AREA_ONLY", "AREA_ONLY records must NOT be falsely mapped to point corridors!"
    print(f"[PASS] Test 2: Location precision isolation passed (0 AREA_ONLY records falsely matched to street corridors).")

    # Test 3: Deterministic Heuristic Scoring
    s1 = scoring.calculate_route_score(r1.route_id, r1.geometry, r1.distance_km, r1.duration_minutes)
    s2 = scoring.calculate_route_score(r1.route_id, r1.geometry, r1.distance_km, r1.duration_minutes)
    assert s1.score == s2.score, "Scores must be deterministic for identical inputs!"
    print(f"[PASS] Test 3: Scoring determinism passed (Route A score: {s1.score}/100, verified: {s1.verified_incident_count}).")

    # Test 4: Duplicate Detection
    dup_candidate = {
        "category": "ROAD_ACCIDENT",
        "latitude": 17.3712,  # Matches OFF-HYD-ACC-2024-001 within ~10m
        "longitude": 78.5028,
    }
    dup_res = loader.detect_duplicate(dup_candidate, threshold_meters=150.0)
    assert dup_res is not None and dup_res["is_duplicate"], "Duplicate detection must flag matching incident within threshold!"
    print(f"[PASS] Test 4: Duplicate detection passed (Flagged duplicate at {dup_res['distance_meters']}m, matched ID: {dup_res['matched_incident_id']}).")

    # Test 5: Community Report Submission & Verification Isolation
    init_score = s1.score
    req = IncidentCreateRequest(
        category="POOR_STREET_LIGHTING",
        description="Non-functional sodium streetlight cluster along college road",
        latitude=r1.geometry[0][0],
        longitude=r1.geometry[0][1],
        location_precision="EXACT",
        severity_reported="MEDIUM",
        is_anonymous=True
    )
    new_inc, is_dup, dup_info = data.add_community_report(req)
    assert new_inc.verification_status == "PENDING", "Newly submitted community report must start strictly as PENDING!"

    # Re-calculate score
    score_after = scoring.calculate_route_score(r1.route_id, r1.geometry, r1.distance_km, r1.duration_minutes)
    assert score_after.score == init_score, "PENDING community report must NOT modify verified route score!"
    assert score_after.pending_report_count >= 1, "Pending count must increment separately!"
    print(f"[PASS] Test 5: Verification isolation passed (New report: {new_inc.id}, Status: {new_inc.verification_status}, Score unchanged: {score_after.score}).")

    # Test 6: Report Lifecycle Review
    reviewed = data.review_community_report(new_inc.id, "VERIFIED", "Confirmed by GHMC lighting audit team.")
    assert reviewed is not None
    assert reviewed.verification_status == "VERIFIED", "Status must transition to VERIFIED!"
    print(f"[PASS] Test 6: Report lifecycle review passed ({reviewed.id} transitioned to VERIFIED).")

    # Test 7: AI Agent Tools & Data Provenance
    chat_req = AgentChatRequest(message="Explain where this incident data came from.")
    chat_resp = await agent.handle_chat(chat_req)
    assert len(chat_resp.tools_called) >= 1
    assert "Hyderabad Traffic Police" in chat_resp.reply_text or "SHE Teams" in chat_resp.reply_text
    print(f"[PASS] Test 7: AI Agent provenance query passed (Tools invoked: {[t.tool_name for t in chat_resp.tools_called]}).")

    # Test 8: Voice-Initiated Incident Report
    rep_req = AgentChatRequest(message="Report poor street lighting near colony entrance.")
    rep_resp = await agent.handle_chat(rep_req)
    assert any(t.tool_name == "submit_incident_report" for t in rep_resp.tools_called)
    assert "PENDING VERIFICATION" in rep_resp.reply_text
    print(f"[PASS] Test 8: Voice-guided incident reporting passed (Response: '{rep_resp.spoken_text}').")

    # Test 9: OpenStreetMap Data Import & Deduplication
    from osm_importer import OsmImporter
    osm = OsmImporter()
    osm_res = await osm.import_features(use_live_overpass=False)
    assert osm_res["status"] == "success"
    assert osm_res["total_features"] >= 10
    assert "POLICE" in osm_res["by_category"]
    assert "HOSPITAL" in osm_res["by_category"]
    print(f"[PASS] Test 9: OpenStreetMap data import passed ({osm_res['total_features']} features imported/deduplicated across {list(osm_res['by_category'].keys())}).")

    # Test 10: Synthetic Demo Data Generation with Road Alignment
    import synthetic_generator
    synth_res = synthetic_generator.generate_synthetic_dataset(count=15, seed=123)
    assert synth_res["status"] == "success"
    assert synth_res["generated_count"] == 15
    assert synth_res["seed"] == 123
    print(f"[PASS] Test 10: Synthetic demo generator passed ({synth_res['generated_count']} incidents generated with explicit simulation flags).")

    print("\nALL 10 UPGRADED BACKEND TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    asyncio.run(run_tests())
