class PublicFacilityModel {
  final String facilityId;
  final String facilityType;
  final String name;
  final String jurisdiction;
  final double latitude;
  final double longitude;
  final String? contactPhone;
  final String sourceName;
  final String? address;
  final String? description;
  final String? emergencyNumber;
  final String? operationalCoverage;

  String get id => facilityId;
  String? get phoneNumber => contactPhone;

  PublicFacilityModel({
    String? id,
    String? facilityId,
    required this.facilityType,
    required this.name,
    String? jurisdiction,
    required this.latitude,
    required this.longitude,
    String? contactPhone,
    String? phoneNumber,
    String? sourceName,
    this.address,
    this.description,
    this.emergencyNumber,
    this.operationalCoverage,
  })  : facilityId = facilityId ?? id ?? '',
        jurisdiction = jurisdiction ?? address ?? 'Hyderabad',
        sourceName = sourceName ?? 'Official Directory',
        contactPhone = contactPhone ?? phoneNumber;

  factory PublicFacilityModel.fromJson(Map<String, dynamic> json) {
    return PublicFacilityModel(
      facilityId: json['facility_id'] ?? json['id'] ?? '',
      facilityType: json['facility_type'] ?? 'POLICE_STATION',
      name: json['name'] ?? '',
      jurisdiction: json['jurisdiction'] ?? json['address'] ?? 'Hyderabad',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      contactPhone: json['contact_phone'] ?? json['phone_number'],
      address: json['address'],
      description: json['description'],
      emergencyNumber: json['emergency_number'],
      operationalCoverage: json['operational_coverage'],
      sourceName: json['source_name'] ?? 'Official Directory',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facility_id': facilityId,
      'facility_type': facilityType,
      'name': name,
      'jurisdiction': jurisdiction,
      'latitude': latitude,
      'longitude': longitude,
      'contact_phone': contactPhone,
      'address': address,
      'description': description,
      'emergency_number': emergencyNumber,
      'operational_coverage': operationalCoverage,
      'source_name': sourceName,
    };
  }
}
