class IncidentModel {
  final String id;
  final String category;
  final String? subcategory;
  final String description;
  final double? latitude;
  final double? longitude;
  final String occurredAt;
  final String reportedAt;
  final String severity; // LOW, MEDIUM, HIGH, CRITICAL, UNKNOWN
  final String verificationStatus; // OFFICIAL_SOURCE, VERIFIED, NEEDS_REVIEW, PENDING, REJECTED
  final String sourceType; // OFFICIAL_SOURCE, COMMUNITY_REPORT, SIMULATED
  final String sourceName;
  final String? sourceUrl;
  final String locationPrecision; // EXACT, APPROXIMATE, AREA_ONLY, UNKNOWN
  final bool isSimulated;
  final bool isAnonymous;
  final String? photoReference;
  final String? reviewNotes;

  IncidentModel({
    required this.id,
    required this.category,
    this.subcategory,
    required this.description,
    this.latitude,
    this.longitude,
    required this.occurredAt,
    required this.reportedAt,
    this.severity = 'UNKNOWN',
    required this.verificationStatus,
    required this.sourceType,
    this.sourceName = 'Official Record',
    this.sourceUrl,
    this.locationPrecision = 'EXACT',
    this.isSimulated = false,
    this.isAnonymous = false,
    this.photoReference,
    this.reviewNotes,
  });

  bool get isOfficialSource => verificationStatus == 'OFFICIAL_SOURCE';
  bool get isVerified => verificationStatus == 'VERIFIED' || isOfficialSource;
  bool get isPending => verificationStatus == 'PENDING';
  bool get isNeedsReview => verificationStatus == 'NEEDS_REVIEW';
  bool get isRejected => verificationStatus == 'REJECTED';
  bool get hasCoordinates => latitude != null && longitude != null;

  String get formattedCategory {
    return category.replaceAll('_', ' ');
  }

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['incident_id'] ?? json['id'] ?? '',
      category: json['category'] ?? 'OTHER_PUBLIC_SAFETY',
      subcategory: json['subcategory'],
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      occurredAt: json['incident_date'] ?? json['occurred_at'] ?? '',
      reportedAt: json['first_published_at'] ?? json['reported_at'] ?? '',
      severity: json['severity'] ?? 'UNKNOWN',
      verificationStatus: json['verification_status'] ?? 'PENDING',
      sourceType: json['source_type'] ?? 'COMMUNITY_REPORT',
      sourceName: json['source_name'] ?? 'Official Record',
      sourceUrl: json['source_url'],
      locationPrecision: json['location_precision'] ?? 'EXACT',
      isSimulated: json['is_simulated'] ?? false,
      isAnonymous: json['is_anonymous'] ?? false,
      photoReference: json['photo_reference'],
      reviewNotes: json['review_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incident_id': id,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'incident_date': occurredAt,
      'first_published_at': reportedAt,
      'severity': severity,
      'verification_status': verificationStatus,
      'source_type': sourceType,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'location_precision': locationPrecision,
      'is_simulated': isSimulated,
      'is_anonymous': isAnonymous,
      'photo_reference': photoReference,
      'review_notes': reviewNotes,
    };
  }
}
