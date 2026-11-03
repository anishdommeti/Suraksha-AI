class ToolInvocationModel {
  final String toolName;
  final Map<String, dynamic> parameters;
  final dynamic result;

  ToolInvocationModel({
    required this.toolName,
    required this.parameters,
    required this.result,
  });

  factory ToolInvocationModel.fromJson(Map<String, dynamic> json) {
    return ToolInvocationModel(
      toolName: json['tool_name'] ?? '',
      parameters: json['parameters'] != null
          ? Map<String, dynamic>.from(json['parameters'])
          : {},
      result: json['result'],
    );
  }
}

class RouteComparisonCardData {
  final String routeId;
  final String name;
  final double distanceKm;
  final int durationMinutes;
  final double score;
  final String scoreCategory;
  final int verifiedCount;
  final int officialCount;
  final int pendingCount;
  final List<String> topHazards;
  final bool isRecommended;
  final String recommendationReason;

  const RouteComparisonCardData({
    required this.routeId,
    required this.name,
    required this.distanceKm,
    required this.durationMinutes,
    required this.score,
    required this.scoreCategory,
    this.verifiedCount = 0,
    this.officialCount = 0,
    this.pendingCount = 0,
    this.topHazards = const [],
    this.isRecommended = false,
    this.recommendationReason = '',
  });

  factory RouteComparisonCardData.fromJson(Map<String, dynamic> json) {
    return RouteComparisonCardData(
      routeId: json['route_id'] ?? '',
      name: json['name'] ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      scoreCategory: json['score_category'] ?? 'UNKNOWN',
      verifiedCount: (json['verified_count'] as num?)?.toInt() ?? 0,
      officialCount: (json['official_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      topHazards: List<String>.from(json['top_hazards'] ?? []),
      isRecommended: json['is_recommended'] ?? false,
      recommendationReason: json['recommendation_reason'] ?? '',
    );
  }
}

class ChatMessageModel {
  final String id;
  final String sender; // 'user' or 'suraksha'
  final String text;
  final String spokenText;
  final DateTime timestamp;
  final List<ToolInvocationModel> toolsCalled;
  final List<String> suggestedActions;
  final String? selectedRouteId;
  final bool isProcessing;
  final List<RouteComparisonCardData>? comparisonCards;
  final bool isConfirmationPrompt;
  final Map<String, dynamic>? pendingAction;

  ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    this.spokenText = '',
    required this.timestamp,
    this.toolsCalled = const [],
    this.suggestedActions = const [],
    this.selectedRouteId,
    this.isProcessing = false,
    this.comparisonCards,
    this.isConfirmationPrompt = false,
    this.pendingAction,
  });

  bool get isUser => sender == 'user';
  bool get isSuraksha => sender == 'suraksha';
}
