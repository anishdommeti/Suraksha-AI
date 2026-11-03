"""
SURAKSHA AI - Synthetic Demo Data Generator
Generates reproducible, road-aligned demonstration incidents for hackathon scenarios.
Strictly isolated from genuine community reports and official verified police records.
Always flagged: is_simulated = True.
"""

import json
import logging
import os
import random
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Any

logger = logging.getLogger(__name__)

DEMO_INCIDENTS_PATH = "data/demo_incidents.json"

CATEGORIES = [
    "POOR_STREET_LIGHTING",
    "ROAD_ACCIDENT",
    "WOMEN_SAFETY",
    "HARASSMENT",
    "TRAFFIC_HAZARD",
    "UNSAFE_OR_ISOLATED_AREA",
    "ROAD_OBSTRUCTION",
    "THEFT",
    "ASSAULT",
    "OTHER_PUBLIC_SAFETY",
]

SEVERITIES = ["LOW", "MEDIUM", "HIGH", "CRITICAL"]

# Key corridor anchor points distributed across Greater Hyderabad
ROAD_ANCHORS = [
    # Saidabad & Malakpet (Core Demo Corridor)
    (17.3596, 78.5085, "Near Matrusri College Gate, Saidabad"),
    (17.3610, 78.5090, "Saidabad Road Junction"),
    (17.3642, 78.5041, "Singareni Colony Park Road"),
    (17.3661, 78.5015, "Singareni Residential Bend"),
    (17.3685, 78.4988, "Underpass Approach Road, Saidabad"),
    (17.3698, 78.4962, "Colony Commercial Border"),
    (17.3620, 78.5125, "IS Sadan Transit Corridor"),
    (17.3680, 78.5100, "IS Sadan Flyover Base"),
    (17.3712, 78.5028, "Saidabad Main Commercial Strip"),
    (17.3753, 78.4908, "Saidabad Metro Hub Pedestrian Way"),
    (17.3762, 78.4912, "Malakpet Road Extension"),

    # Hitec City & Madhapur
    (17.4504, 78.3808, "Cyber Towers Junction, Hitec City"),
    (17.4435, 78.3772, "Mindspace IT Park Entrance, Hitec City"),
    (17.4330, 78.3865, "Inorbit Mall Access Road, Madhapur"),
    (17.4485, 78.3912, "Hitec City Metro Station Footpath"),

    # Gachibowli & Financial District
    (17.4401, 78.3489, "Gachibowli Stadium ORR Junction"),
    (17.4265, 78.3680, "Biodiversity Park Flyover Ramp, Gachibowli"),
    (17.4475, 78.3562, "DLF Cybercity Road, Gachibowli"),

    # Banjara Hills & Jubilee Hills
    (17.4215, 78.4482, "Road No. 1, Banjara Hills"),
    (17.4120, 78.4350, "Road No. 12, Care Hospital Corridor, Banjara Hills"),
    (17.4248, 78.4285, "KBR Park Perimeter Walkway, Banjara Hills"),
    (17.4300, 78.4110, "Jubilee Hills Check Post"),
    (17.4345, 78.4012, "Road No. 45 Flyover Junction, Jubilee Hills"),
    (17.4312, 78.3934, "Durgam Cheruvu Cable Bridge Approach"),

    # Begumpet & Secunderabad
    (17.4442, 78.4682, "Begumpet Airport Flyover Road"),
    (17.4468, 78.4615, "Prakash Nagar Metro Footbridge, Begumpet"),
    (17.4344, 78.5015, "Secunderabad Railway Station Approach"),
    (17.4398, 78.4982, "Clock Tower Junction, Secunderabad"),
    (17.4415, 78.4875, "Paradise Circle, Secunderabad"),

    # Uppal & Ramanthapur
    (17.4065, 78.5591, "Rajiv Gandhi International Cricket Stadium, Uppal"),
    (17.4018, 78.5602, "Uppal Ring Road & Metro Interchange"),
    (17.3945, 78.5420, "Ramanthapur Main Road"),

    # Charminar & Old City
    (17.3616, 78.4747, "Charminar Heritage Pedestrian Zone"),
    (17.3695, 78.4735, "Madina Building & Nayapul Bridge"),
    (17.3785, 78.4760, "Moazzam Jahi Market Junction"),

    # Kukatpally & KPHB
    (17.4932, 78.3995, "KPHB Colony Metro Station, Kukatpally"),
    (17.4985, 78.3908, "JNTU University Junction, Kukatpally"),

    # Mehdipatnam
    (17.3920, 78.4398, "Mehdipatnam Bus Depot & Rythu Bazar"),
    (17.3875, 78.4440, "PVNR Expressway Ramp, Mehdipatnam"),

    # Dilsukhnagar
    (17.3688, 78.5248, "Dilsukhnagar Bus Stand & Metro"),
    (17.3645, 78.5372, "Chaitanyapuri Metro Junction, Dilsukhnagar"),
]

DESCRIPTIONS = {
    "POOR_STREET_LIGHTING": [
        "Sodium vapor lamps flickering and non-operational for 120m stretch.",
        "Dark alley between boundary wall and storm drain.",
        "Broken overhead street light causing poor night visibility.",
    ],
    "ROAD_ACCIDENT": [
        "Minor two-wheeler skid on loose gravel curve.",
        "Auto-rickshaw collision at unsignalized crossover.",
        "Near-miss pedestrian collision at crossing.",
    ],
    "WOMEN_SAFETY": [
        "Isolated bus shelter without lighting or crowd presence after 9 PM.",
        "Poorly lit passage frequently reported by evening commuters.",
    ],
    "HARASSMENT": [
        "Eve-teasing and catcalling reported near deserted tea stall.",
        "Group loitering and intimidating commuters on foot.",
    ],
    "TRAFFIC_HAZARD": [
        "Unmarked speed bump causing emergency braking.",
        "Damaged concrete median with protruding rebar.",
    ],
    "UNSAFE_OR_ISOLATED_AREA": [
        "Deserted stretch with heavy vegetation and zero commercial activity.",
        "Vacant plot perimeter with zero night-time pedestrian traffic.",
    ],
    "ROAD_OBSTRUCTION": [
        "Civic pipeline excavation barrier encroaching half carriageway.",
        "Uncollected municipal tree debris blocking pedestrian walkway.",
    ],
    "THEFT": [
        "Mobile phone snatching incident from slow-moving two-wheeler.",
        "Bicycle theft from outside convenience store.",
    ],
    "ASSAULT": [
        "Late-night altercation between intoxicated individuals.",
        "Attempted purse snatching with physical shoving.",
    ],
    "OTHER_PUBLIC_SAFETY": [
        "Open utility trench without safety tape.",
        "Stray dog aggression reported during early morning walk.",
    ],
}

def generate_synthetic_dataset(
    count: int = 25,
    seed: int = 42,
    output_path: str = DEMO_INCIDENTS_PATH
) -> Dict[str, Any]:
    """
    Generates deterministic, road-anchored synthetic incidents.
    Enforces strict is_simulated=True and SIMULATED_DEMO_DATA source type.
    """
    random.seed(seed)
    now = datetime.now(timezone.utc)
    generated: List[Dict[str, Any]] = []

    for i in range(count):
        inc_id = f"SYNTH-DEMO-2024-{i + 1:03d}"
        cat = random.choice(CATEGORIES)
        sev = random.choices(SEVERITIES, weights=[0.25, 0.45, 0.20, 0.10])[0]

        # Anchor to a realistic road corridor point with slight jitter (<40m)
        anchor_lat, anchor_lon, location_desc = random.choice(ROAD_ANCHORS)
        jitter_lat = (random.random() - 0.5) * 0.0006
        jitter_lon = (random.random() - 0.5) * 0.0006
        lat = round(anchor_lat + jitter_lat, 6)
        lon = round(anchor_lon + jitter_lon, 6)

        # Distribute timestamps across last 45 days
        days_ago = random.randint(1, 45)
        hours_ago = random.randint(0, 23)
        occurred_time = now - timedelta(days=days_ago, hours=hours_ago)
        reported_time = occurred_time + timedelta(minutes=random.randint(15, 120))

        desc_template = random.choice(DESCRIPTIONS[cat])
        full_desc = f"{desc_template} ({location_desc})"

        record = {
            "incident_id": inc_id,
            "category": cat,
            "severity": sev,
            "latitude": lat,
            "longitude": lon,
            "occurred_at": occurred_time.isoformat(),
            "reported_at": reported_time.isoformat(),
            "description": full_desc,
            "source_type": "SIMULATED_DEMO_DATA",
            "source_name": "SURAKSHA Synthetic Generator (Demo)",
            "source_url": "https://suraksha.ai/demo",
            "verification_status": "OFFICIAL_SOURCE" if sev in ["HIGH", "CRITICAL"] else "VERIFIED",
            "is_simulated": True,
            "location_precision": "EXACT",
            "confidence_score": 0.85,
            "is_anonymous": False,
            "created_at": now.isoformat(),
            "ui_label": "SIMULATED DEMO DATA — NOT VERIFIED REAL-WORLD INCIDENTS"
        }
        generated.append(record)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(generated, f, indent=2)

    cat_counts: Dict[str, int] = {}
    for r in generated:
        c = r["category"]
        cat_counts[c] = cat_counts.get(c, 0) + 1

    return {
        "status": "success",
        "generated_count": len(generated),
        "seed": seed,
        "by_category": cat_counts,
        "file": output_path,
        "disclaimer": "SIMULATED DEMO DATA — NOT VERIFIED REAL-WORLD INCIDENTS",
    }

def reset_synthetic_dataset(output_path: str = DEMO_INCIDENTS_PATH) -> Dict[str, Any]:
    """Resets synthetic incidents back to standard 10 baseline demo fixtures."""
    return generate_synthetic_dataset(count=10, seed=42, output_path=output_path)

