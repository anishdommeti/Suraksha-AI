import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/incident_service.dart';
import '../services/location_service.dart';
import 'my_reports_screen.dart';
import '../services/localization_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const ReportIncidentScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'ROAD_ACCIDENT';
  String _selectedSeverity = 'MEDIUM';
  String _locationPrecision = 'EXACT';
  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();
  bool _isAnonymous = true;
  String? _attachedPhotoName;

  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  double _latitude = 17.3670;
  double _longitude = 78.5050;
  bool _isSubmitting = false;

  final Map<String, String> _categoriesMap = {
    'ROAD_ACCIDENT': 'Road Accident / Collision',
    'TRAFFIC_HAZARD': 'Traffic Hazard / Pothole / Blind Curve',
    'WOMEN_SAFETY': "Women's Safety Concern",
    'HARASSMENT': 'Harassment / Eve-Teasing / Stalking',
    'ASSAULT': 'Assault / Physical Violence',
    'THEFT': 'Theft / Snatching / Robbery',
    'POOR_STREET_LIGHTING': 'Poor Street Lighting / Dark Corridor',
    'UNSAFE_OR_ISOLATED_AREA': 'Unsafe / Deserted Area',
    'ROAD_OBSTRUCTION': 'Road Obstruction / Open Excavation',
    'OTHER_PUBLIC_SAFETY': 'Other Public Safety Concern',
  };

  @override
  void initState() {
    super.initState();
    final loc = Provider.of<LocationService>(context, listen: false);
    _latitude = widget.initialLat ?? loc.originCoords.latitude;
    _longitude = widget.initialLng ?? loc.originCoords.longitude;
    _locController.text =
        '${loc.origin} (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})';
  }

  @override
  void dispose() {
    _descController.dispose();
    _locController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime,
    );
    if (picked != null) {
      setState(() => _incidentTime = picked);
    }
  }

  Future<void> _useGpsLocation() async {
    final loc = Provider.of<LocationService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Requesting device GPS coordinates...'),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await loc.requestCurrentLocation(updateOrigin: false);
    if (!mounted) return;

    if (success && loc.currentGpsCoords != null) {
      setState(() {
        _latitude = loc.currentGpsCoords!.latitude;
        _longitude = loc.currentGpsCoords!.longitude;
        _locationPrecision = 'EXACT';
        final acc = loc.accuracyMeters != null
            ? ' (±${loc.accuracyMeters!.toStringAsFixed(0)}m)'
            : '';
        _locController.text =
            'Live GPS: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}$acc';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Acquired live GPS location: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.statusMessage),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  void _simulateAttachPhoto() {
    setState(() {
      _attachedPhotoName =
          'photo_evidence_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attached evidence photo: $_attachedPhotoName (Checked: < 5MB).',
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final fullDatetime = DateTime(
      _incidentDate.year,
      _incidentDate.month,
      _incidentDate.day,
      _incidentTime.hour,
      _incidentTime.minute,
    ).toUtc().toIso8601String();

    final incidentService = Provider.of<IncidentService>(
      context,
      listen: false,
    );

    try {
      final result = await incidentService.submitCommunityReport(
        category: _selectedCategory,
        description: _descController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        locationPrecision: _locationPrecision,
        severityReported: _selectedSeverity,
        isAnonymous: _isAnonymous,
        photoReference: _attachedPhotoName,
        incidentDatetime: fullDatetime,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _showSubmissionConfirmation(result);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
    }
  }

  void _showSubmissionConfirmation(SubmissionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                result.isDuplicateWarning
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle,
                color: result.isDuplicateWarning
                    ? Colors.orange
                    : const Color(0xFF00796B),
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                result.isDuplicateWarning
                    ? 'Report Submitted (Duplicate Alert)'
                    : 'Report Registered',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report ID: ${result.incident.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB3E5FC)),
                  ),
                  child: const Text(
                    'STATUS: PENDING VERIFICATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0288D1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF455A64),
                    height: 1.35,
                  ),
                ),
                if (result.isDuplicateWarning) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Notice: A similar report exists within 120m. Both records will be reviewed together.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const Text(
                  'What happens next?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Your submission is visible to commuters with a blue [Pending] marker.\n'
                  '• It will NOT affect official route safety scores until verified.\n'
                  '• Track updates anytime in "My Reports".',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF546E7A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyReportsScreen(),
                  ),
                );
              },
              child: const Text('View in My Reports'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // return home
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locService = Provider.of<LocalizationService>(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1326)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          locService.t('report_screen_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Critical Emergency Notice Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C0B0E)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFFFCDD2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.emergency,
                      color: Color(0xFFEF5350),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locService.t('report_emergency_warning'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFF8A80)
                                  : const Color(0xFFB71C1C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locService.t('report_emergency_desc'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFFFCDD2)
                                  : const Color(0xFFC62828),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Category dropdown
              Text(
                locService.t('incident_category_label'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                items: _categoriesMap.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reported Severity (Reporter Assessment)
              Text(
                locService.t('reported_severity_label'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSeverity,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'LOW',
                    child: Text('Low (Minor nuisance or hazard)'),
                  ),
                  DropdownMenuItem(
                    value: 'MEDIUM',
                    child: Text('Medium (Moderate obstruction or concern)'),
                  ),
                  DropdownMenuItem(
                    value: 'HIGH',
                    child: Text('High (Active safety threat or major defect)'),
                  ),
                  DropdownMenuItem(
                    value: 'CRITICAL',
                    child: Text(
                      'Critical (Severe accident or imminent danger)',
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSeverity = val);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Pickers
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locService.t('incident_date_label'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(_incidentDate),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locService.t('incident_time_label'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time, size: 14),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _incidentTime.format(context),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location Input & GPS Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(locService.t('location_input_label'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: TextButton.icon(
                      onPressed: _useGpsLocation,
                      icon: const Icon(
                        Icons.my_location,
                        size: 14,
                        color: Color(0xFF00796B),
                      ),
                      label: Text(locService.t('use_gps_action'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00796B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _locController,
                decoration: InputDecoration(
                  hintText: 'e.g. Near Singareni Colony Park or Saidabad Jn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a location'
                    : null,
              ),
              const SizedBox(height: 8),

              // Location Precision Chips (Wrapped to prevent RenderFlex overflow)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${locService.t('precision_label')} ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  ChoiceChip(
                    label: Text(
                      locService.t('precision_exact'),
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: _locationPrecision == 'EXACT',
                    selectedColor: const Color(0xFFB2DFDB),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _locationPrecision = 'EXACT');
                      }
                    },
                  ),
                  ChoiceChip(
                    label: Text(
                      locService.t('precision_approx'),
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: _locationPrecision == 'APPROXIMATE',
                    selectedColor: const Color(0xFFB2DFDB),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _locationPrecision = 'APPROXIMATE');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                locService.t('description_label'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe what happened or the hazard observed (e.g. broken streetlights, vehicle skid, eve-teasing)...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (val) => val == null || val.trim().length < 5
                    ? 'Please enter at least 5 characters'
                    : null,
              ),
              const SizedBox(height: 14),

              // Photo Evidence Attachment
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _simulateAttachPhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: Text(
                      _attachedPhotoName == null
                          ? 'Attach Photo Evidence'
                          : 'Photo Attached',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00796B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (_attachedPhotoName != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Anonymous Reporting Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  locService.t('anonymous_label'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  locService.t('anonymous_subtitle'),
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                value: _isAnonymous,
                activeThumbColor: const Color(0xFF00796B),
                onChanged: (val) => setState(() => _isAnonymous = val),
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? locService.t('submitting_report') : locService.t('submit_report_btn'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
