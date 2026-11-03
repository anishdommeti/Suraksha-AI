import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _prefKey = 'suraksha_language_code';

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;
  String get languageCode => _currentLocale.languageCode;
  bool get isTelugu => _currentLocale.languageCode == 'te';

  LocalizationService() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && (savedCode == 'en' || savedCode == 'te')) {
        _currentLocale = Locale(savedCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SURAKSHA AI] Error loading language preference: $e');
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'te') return;
    if (_currentLocale.languageCode == code) return;

    _currentLocale = Locale(code);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (e) {
      debugPrint('[SURAKSHA AI] Error saving language preference: $e');
    }
  }

  String t(String key) {
    final lang = _currentLocale.languageCode;
    final dict = _translations[lang] ?? _translations['en']!;
    return dict[key] ?? _translations['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // General & Brand
      'app_name': 'SURAKSHA AI',
      'tagline': 'Your Safety. Your Route. Your Power.',
      'assistant_name': 'Suraksha',
      'action_agent': 'Action-Capable Voice Agent',
      'demo_mode': 'DEMO MODE: Simulated Safety Data',
      'close': 'Close',
      'ok': 'OK',
      'cancel': 'Cancel',
      'done': 'Done',
      'confirm': 'Confirm',
      'error': 'Error',
      'loading': 'Loading...',
      'success': 'Success',

      // Navigation Drawer
      'menu_title': 'SURAKSHA AI',
      'menu_subtitle': 'AI Personal Safety & Smart Route',
      'nav_map': 'Interactive Safety Map',
      'nav_assistant': 'AI Voice Assistant',
      'nav_report': 'Report Hazard / Incident',
      'nav_my_reports': 'My Submitted Reports',
      'nav_saved_places': 'Saved Locations',
      'nav_methodology': 'Risk Scoring Methodology',
      'nav_settings': 'Settings & Preferences',
      'nav_emergency': 'Emergency Helplines (India)',
      'helpline_112': '112 (National Emergency)',
      'helpline_1091': '1091 (Women Safety Helpline)',

      // Settings Screen
      'settings_title': 'Settings & Preferences',
      'theme_title': 'App Appearance',
      'theme_subtitle': 'Choose between Light and Dark navy themes',
      'theme_system': 'System Default',
      'theme_light': 'Light Theme',
      'theme_dark': 'Dark Navy Theme',
      'lang_title': 'Application Language',
      'lang_subtitle': 'Select your preferred display language',
      'lang_en': 'English',
      'lang_te': 'తెలుగు (Telugu)',
      'about_title': 'About SURAKSHA AI',
      'about_version': 'Version 2.4.0 (Hackathon MVP)',
      'about_tech': 'Powered by Google Maps, OSRM & OpenStreetMap',

      // Map & Routing Screen
      'search_placeholder': 'Search places via Photon (Hyderabad)...',
      'search_origin_placeholder': 'Search starting point (origin)...',
      'search_dest_placeholder': 'Search destination...',
      'origin_label': 'Starting Point',
      'destination_label': 'Destination',
      'use_my_location': 'Use Current Location',
      'current_location_active': 'My Current Location',
      'swap_direction': 'Swap',
      'plan_route_btn': 'Plan Road Route (OSRM)',
      'navigate_gmaps': 'Navigate with Google Maps',
      'navigate_google_maps': 'Navigate with Google Maps',
      'nav_gmaps_subtitle': 'Opens turn-by-turn navigation in Google Maps. SURAKSHA AI preserves your analyzed OSRM route.',
      'clear_route': 'Clear Route',
      'recalculate_route': 'Recalculate Route',
      'select_destination_prompt': 'Select a destination to plan a safety-evaluated route',
      'all_incidents': 'All Incidents',
      'toggle_facilities': 'Toggle Facilities',
      'zoom_in': 'Zoom In',
      'zoom_out': 'Zoom Out',
      'my_location': 'My Location',
      'ask_suraksha': 'Ask Suraksha',
      'report_hazard': 'Report Hazard',
      'routing_in_progress': 'Routing via OSRM & Analyzing Safety...',
      'route_analyzed': 'Route Analyzed',
      'analysis_done': 'Safety Analysis Completed',
      'recommended': 'Recommended',
      'legend_title': 'Map Marker Legend',
      'legend_tap_to_filter': 'Tap any category to filter map pins',
      'legend_accident': 'Road Accident Blackspots',
      'legend_women': "Women's Safety Concerns",
      'legend_lighting': 'Poor Street Lighting',
      'legend_hazard': 'Traffic Hazards / Skids',
      'legend_pending': 'Community Reports (Pending)',
      'legend_obstruction': 'Road Obstructions',
      'legend_facilities': 'Police Stations & Hospitals',

      // Incident Categories
      'cat_all': 'All Categories',
      'cat_accident': 'Road Accident / Collision',
      'cat_traffic_hazard': 'Traffic Hazard / Blind Curve / Pothole',
      'cat_women_safety': "Women's Safety Concern",
      'cat_harassment': 'Harassment / Eve-Teasing / Stalking',
      'cat_assault': 'Assault / Physical Violence',
      'cat_theft': 'Theft / Snatching / Robbery',
      'cat_lighting': 'Poor Street Lighting / Dark Corridor',
      'cat_isolated_area': 'Unsafe / Deserted Area',
      'cat_obstruction': 'Road Obstruction / Open Excavation',
      'cat_other': 'Other Public Safety Concern',

      // Severity Levels
      'sev_low': 'Low (Minor nuisance or hazard)',
      'sev_medium': 'Medium (Moderate obstruction or concern)',
      'sev_high': 'High (Active safety threat or major defect)',
      'sev_critical': 'Critical (Severe accident or imminent danger)',

      // Report Incident Form
      'report_screen_title': 'Report Incident / Hazard',
      'report_emergency_warning': 'Emergency Warning (India)',
      'report_emergency_desc': 'For life-threatening emergencies, do NOT use this form. Call Police at 112 or SHE Teams at 100 / 1091 immediately.',
      'incident_category_label': 'Incident Category',
      'reported_severity_label': 'Reported Severity (Your Assessment)',
      'incident_date_label': 'Incident Date',
      'incident_time_label': 'Incident Time',
      'location_input_label': 'Location',
      'use_gps_action': 'Use Live GPS',
      'precision_label': 'Precision:',
      'precision_exact': 'Exact Point',
      'precision_approx': 'Approximate',
      'description_label': 'Description',
      'description_hint': 'Describe what happened or the hazard observed (e.g. broken streetlights, vehicle skid, eve-teasing)...',
      'attach_photo': 'Attach Photo Evidence',
      'photo_attached': 'Photo Attached',
      'anonymous_label': 'Anonymous Submission',
      'anonymous_subtitle': 'Your name and contact will not be linked to the public report.',
      'submit_report_btn': 'Submit Community Report',
      'submitting_report': 'Registering...',
      'report_registered': 'Report Registered',
      'status_pending': 'STATUS: PENDING VERIFICATION',
      'what_happens_next': 'What happens next?',
      'next_point_1': '• Your submission is visible to commuters with a blue [Pending] marker.',
      'next_point_2': '• It will NOT affect official route safety scores until verified.',
      'next_point_3': '• Track updates anytime in "My Reports".',
      'view_in_my_reports': 'View in My Reports',

      // AI Assistant Screen
      'assistant_greeting': "Hi, I'm Suraksha, your AI-powered personal safety and smart route assistant. Where would you like to travel?",
      'listening_banner': 'Listening... speak your request',
      'processing_tools': 'Suraksha is executing backend tools...',
      'ask_input_hint': 'Ask Suraksha or speak...',
      'view_on_map': 'View on Map',
      'on_map': 'On Map',
      'google_maps_btn': 'Google Maps',
      'suggested_q1': 'Which route has fewer recorded incidents?',
      'suggested_q2': 'Compare routes to metro station',
      'suggested_q3': 'Why are you recommending this route?',
      'suggested_q4': 'Take me to Rajiv Gandhi International Airport',
      'suggested_q5': 'Navigate to Uppal Stadium',
      'suggested_q6': 'Report a hazard',
      'verified_records': 'verified audit records',
      'safety_score_label': 'Safety Score',

      // Score Explanation & Methodology
      'score_screen_title': 'About Risk Scores & Methodology',
      'scoring_header_title': 'Transparent Heuristic Safety Scoring',
      'scoring_header_subtitle': 'SURAKSHA AI computes deterministic, evidence-backed scores based strictly on recorded incident data. The LLM does NOT invent or guess risk scores.',
      'sec_1_title': '1. What Does the Score Measure?',
      'sec_2_title': '2. The Mathematical Heuristic Formula',
      'sec_3_title': '3. Verification Lifecycle & Score Isolation',
      'sec_4_title': '4. Data Provenance & Precision Transparency',
      'sec_5_title': '5. Critical Safety Limitations & Emergency Protocol',

      // My Reports
      'my_reports_title': 'My Submitted Reports',
      'no_reports_yet': 'No community reports registered yet.',
      'no_reports_hint': 'When you submit hazard reports, they will be tracked here.',
    },

    'te': {
      // General & Brand
      'app_name': 'సురక్ష AI',
      'tagline': 'మీ భద్రత. మీ మార్గం. మీ శక్తి.',
      'assistant_name': 'సురక్ష',
      'action_agent': 'స్మార్ట్ వాయిస్ అసిస్టెంట్',
      'demo_mode': 'డెమో మోడ్: భద్రతా డేటా',
      'close': 'మూసివేయి',
      'ok': 'సరే',
      'cancel': 'రద్దు చేయి',
      'done': 'పూర్తయింది',
      'confirm': 'ధృవీకరించు',
      'error': 'లోపం',
      'loading': 'లోడ్ అవుతోంది...',
      'success': 'విజయవంతం',

      // Navigation Drawer
      'menu_title': 'సురక్ష AI',
      'menu_subtitle': 'AI వ్యక్తిగత భద్రత & స్మార్ట్ రూట్ అసిస్టెంట్',
      'nav_map': 'ఇంటరాక్టివ్ భద్రతా మ్యాప్',
      'nav_assistant': 'AI వాయిస్ అసిస్టెంట్',
      'nav_report': 'ప్రమాదం / సమస్యను నివేదించండి',
      'nav_my_reports': 'నా నివేదికలు',
      'nav_saved_places': 'సేవ్ చేసిన స్థలాలు',
      'nav_methodology': 'రిస్క్ స్కోరింగ్ విధానం',
      'nav_settings': 'సెట్టింగులు & ప్రాధాన్యతలు',
      'nav_emergency': 'అత్యవసర హెల్ప్‌లైన్లు (భారతదేశం)',
      'helpline_112': '112 (జాతీయ అత్యవసర విభాగం)',
      'helpline_1091': '1091 (మహిళా భద్రతా హెల్ప్‌లైన్)',

      // Settings Screen
      'settings_title': 'సెట్టింగులు & ప్రాధాన్యతలు',
      'theme_title': 'యాప్ రూపం (థీమ్)',
      'theme_subtitle': 'లైట్ మరియు డార్క్ నేవీ థీమ్‌ల మధ్య ఎంచుకోండి',
      'theme_system': 'సిస్టమ్ డిఫాల్ట్',
      'theme_light': 'లైట్ థీమ్',
      'theme_dark': 'డార్క్ నేవీ థీమ్',
      'lang_title': 'అప్లికేషన్ భాష',
      'lang_subtitle': 'మీకు నచ్చిన భాషను ఎంచుకోండి',
      'lang_en': 'English',
      'lang_te': 'తెలుగు (Telugu)',
      'about_title': 'సురక్ష AI గురించి',
      'about_version': 'వెర్షన్ 2.4.0 (హ్యాకథాన్ MVP)',
      'about_tech': 'గూగుల్ మ్యాప్స్, OSRM & ఓపెన్‌స్ట్రీట్‌మ్యాప్ సహకారంతో',

      // Map & Routing Screen
      'search_placeholder': 'హైదరాబాద్‌లో స్థలాలను వెతకండి...',
      'search_origin_placeholder': 'ప్రారంభ స్థలాన్ని వెతకండి (Origin)...',
      'search_dest_placeholder': 'గమ్యస్థానాన్ని వెతకండి (Destination)...',
      'origin_label': 'ప్రారంభ స్థానం',
      'destination_label': 'గమ్యస్థానం',
      'use_my_location': 'నా ప్రస్తుత స్థానాన్ని ఉపయోగించు',
      'current_location_active': 'నా ప్రస్తుత GPS స్థానం',
      'swap_direction': 'మార్చు',
      'plan_route_btn': 'రోడ్ రూట్ ప్లాన్ చేయండి (OSRM)',
      'navigate_gmaps': 'గూగుల్ మ్యాప్స్‌తో నావిగేట్ చేయండి',
      'navigate_google_maps': 'గూగుల్ మ్యాప్స్‌తో నావిగేట్ చేయండి',
      'nav_gmaps_subtitle': 'గూగుల్ మ్యాప్స్‌లో టర్న్-బై-టర్న్ నావిగేషన్‌ను ప్రారంభిస్తుంది.',
      'clear_route': 'రూట్‌ను క్లియర్ చేయి',
      'recalculate_route': 'తిరిగి లెక్కించు',
      'select_destination_prompt': 'సురక్షితమైన మార్గాన్ని ప్లాన్ చేయడానికి గమ్యస్థానాన్ని ఎంచుకోండి',
      'all_incidents': 'అన్ని సంఘటనలు',
      'toggle_facilities': 'కేంద్రాలను మార్చు',
      'zoom_in': 'జూమ్ ఇన్',
      'zoom_out': 'జూమ్ అవుట్',
      'my_location': 'నా స్థానం',
      'ask_suraksha': 'సురక్షను అడగండి',
      'report_hazard': 'సమస్యను నివేదించు',
      'routing_in_progress': 'OSRM ద్వారా మార్గం మరియు భద్రతా విశ్లేషణ జరుగుతోంది...',
      'route_analyzed': 'రూట్ విశ్లేషించబడింది',
      'analysis_done': 'భద్రతా విశ్లేషణ పూర్తయింది',
      'recommended': 'సిఫార్సు చేయబడింది',
      'legend_title': 'మ్యాప్ గుర్తుల సూచిక',
      'legend_tap_to_filter': 'ఫిల్టర్ చేయడానికి ఏదైనా కేటగిరీని నొక్కండి',
      'legend_accident': 'రోడ్డు ప్రమాద బ్లాక్‌స్పాట్‌లు',
      'legend_women': 'మహిళా భద్రతా హెచ్చరికలు',
      'legend_lighting': 'సరైన లైటింగ్ లేని ప్రాంతాలు',
      'legend_hazard': 'ట్రాఫిక్ ప్రమాదాలు / మలుపులు',
      'legend_pending': 'ప్రజా నివేదికలు (ధృవీకరణ పెండింగ్)',
      'legend_obstruction': 'రోడ్డు అడ్డంకులు / తవ్వకాలు',
      'legend_facilities': 'పోలీస్ స్టేషన్లు & ఆసుపత్రులు',

      // Incident Categories
      'cat_all': 'అన్ని కేటగిరీలు',
      'cat_accident': 'రోడ్డు ప్రమాదం / ఢీకొనడం',
      'cat_traffic_hazard': 'ట్రాఫిక్ ప్రమాదం / గుంతలు / మలుపు',
      'cat_women_safety': 'మహిళా భద్రతా ఆందోళన',
      'cat_harassment': 'వేధింపులు / ఈవ్-టీజింగ్ / వెంబడించడం',
      'cat_assault': 'దాడి / శారీరక దాడి',
      'cat_theft': 'దొంగతనం / స్నాచింగ్',
      'cat_lighting': 'వీధి దీపాలు లేకపోవడం / చీకటి దారి',
      'cat_isolated_area': 'నిర్జన / ప్రమాదకరమైన ప్రాంతం',
      'cat_obstruction': 'రోడ్డు అడ్డంకి / ఓపెన్ తవ్వకం',
      'cat_other': 'ఇతర ప్రజా భద్రతా ఆందోళన',

      // Severity Levels
      'sev_low': 'తక్కువ (చిన్న సమస్య లేదా ప్రమాదం)',
      'sev_medium': 'మధ్యస్థం (సాధారణ అడ్డంకి లేదా ఆందోళన)',
      'sev_high': 'అధికం (ప్రధాన భద్రతా ముప్పు)',
      'sev_critical': 'తీవ్రమైనది (తీవ్రమైన ప్రమాదం / అత్యవసరం)',

      // Report Incident Form
      'report_screen_title': 'సంఘటన / ప్రమాదాన్ని నివేదించండి',
      'report_emergency_warning': 'అత్యవసర హెచ్చరిక (భారతదేశం)',
      'report_emergency_desc': 'ప్రాణాపాయ అత్యవసర పరిస్థితుల్లో ఈ ఫారమ్‌ను ఉపయోగించవద్దు. వెంటనే పోలీస్ 112 లేదా షీ టీమ్స్ 100 / 1091 కి కాల్ చేయండి.',
      'incident_category_label': 'సంఘటన కేటగిరీ',
      'reported_severity_label': 'తీవ్రత స్థాయి (మీ అంచనా)',
      'incident_date_label': 'సంఘటన తేదీ',
      'incident_time_label': 'సంఘటన సమయం',
      'location_input_label': 'స్థానం',
      'use_gps_action': 'లైవ్ GPS ఉపయోగించు',
      'precision_label': 'ఖచ్చితత్వం:',
      'precision_exact': 'ఖచ్చితమైన పాయింట్',
      'precision_approx': 'సుమారుగా',
      'description_label': 'వివరణ',
      'description_hint': 'ఏమి జరిగిందో లేదా గమనించిన ప్రమాదాన్ని వివరించండి (ఉదా. వీధి దీపాలు వెలగకపోవడం, వాహనం జారడం)...',
      'attach_photo': 'ఫోటో సాక్ష్యాన్ని జతచేయి',
      'photo_attached': 'ఫోటో జతచేయబడింది',
      'anonymous_label': 'అజ్ఞాత నివేదిక',
      'anonymous_subtitle': 'మీ పేరు మరియు వివరాలు పబ్లిక్ నివేదికలో కనిపించవు.',
      'submit_report_btn': 'నివేదికను సమర్పించండి',
      'submitting_report': 'నమోదు అవుతోంది...',
      'report_registered': 'నివేదిక నమోదయింది',
      'status_pending': 'స్థితి: ధృవీకరణ పెండింగ్‌లో ఉంది',
      'what_happens_next': 'తరువాత ఏమి జరుగుతుంది?',
      'next_point_1': '• మీ నివేదిక నీలిరంగు [పెండింగ్] గుర్తుతో ప్రయాణికులకు కనిపిస్తుంది.',
      'next_point_2': '• ధృవీకరించబడే వరకు ఇది అధికారిక రూట్ భద్రతా స్కోర్‌లను మార్చదు.',
      'next_point_3': '• "నా నివేదికలు" లో ఎప్పుడైనా అప్‌డేట్‌లను చూడవచ్చు.',
      'view_in_my_reports': 'నా నివేదికలలో చూడండి',

      // AI Assistant Screen
      'assistant_greeting': 'నమస్కారం, నేను సురక్షను. మీ AI భద్రత మరియు స్మార్ట్ రూట్ అసిస్టెంట్‌ని. మీరు ఎక్కడికి ప్రయాణించాలనుకుంటున్నారు?',
      'listening_banner': 'వింటున్నాను... మీ అభ్యర్థనను చెప్పండి',
      'processing_tools': 'సురక్ష టూల్స్ ద్వారా వివరాలను సేకరిస్తోంది...',
      'ask_input_hint': 'సురక్షను అడగండి లేదా మాట్లాడండి...',
      'view_on_map': 'మ్యాప్‌లో చూడండి',
      'on_map': 'మ్యాప్‌లో ఉంది',
      'google_maps_btn': 'గూగుల్ మ్యాప్స్',
      'suggested_q1': 'తక్కువ ప్రమాదాలు నమోదైన మార్గం ఏది?',
      'suggested_q2': 'మెట్రో స్టేషన్‌కు మార్గాలను సరిపోల్చండి',
      'suggested_q3': 'ఈ మార్గాన్ని ఎందుకు సిఫార్సు చేస్తున్నారు?',
      'suggested_q4': 'రాజీవ్ గాంధీ అంతర్జాతీయ విమానాశ్రయానికి రూట్ చూపించు',
      'suggested_q5': 'ఉప్పల్ స్టేడియం వైపు రూట్ చూపించు',
      'suggested_q6': 'సమస్యను నివేదించు',
      'verified_records': 'ధృవీకరించబడిన ఆడిట్ రికార్డులు',
      'safety_score_label': 'భద్రతా స్కోరు',

      // Score Explanation & Methodology
      'score_screen_title': 'రిస్క్ స్కోరింగ్ విధానం',
      'scoring_header_title': 'పారదర్శక భద్రతా స్కోరింగ్ విధానం',
      'scoring_header_subtitle': 'సురక్ష AI రికార్డ్ చేయబడిన సంఘటనల ఆధారంగా ఖచ్చితమైన స్కోర్‌లను లెక్కిస్తుంది. AI ఊహించి స్కోర్‌లను చెప్పదు.',
      'sec_1_title': '1. స్కోర్ దేనిని కొలుస్తుంది?',
      'sec_2_title': '2. గణిత సూత్రం & పద్ధతి',
      'sec_3_title': '3. ధృవీకరణ విధానం & స్కోర్ రక్షణ',
      'sec_4_title': '4. అధికారిక డేటా మూలాలు',
      'sec_5_title': '5. ముఖ్యమైన భద్రతా పరిమితులు & అత్యవసర ప్రోటోకాల్',

      // My Reports
      'my_reports_title': 'నా సమర్పించిన నివేదికలు',
      'no_reports_yet': 'ఇంకా ఎటువంటి నివేదికలు సమర్పించలేదు.',
      'no_reports_hint': 'మీరు సమర్పించిన ప్రమాద నివేదికలు ఇక్కడ కనిపిస్తాయి.',
    },
  };
}

