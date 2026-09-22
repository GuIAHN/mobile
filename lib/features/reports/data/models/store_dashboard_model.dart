import '../../domain/entities/store_dashboard.dart';

class DashboardResponseModel extends DashboardResponse {
  const DashboardResponseModel({
    required super.scope,
    required super.computedAt,
    required super.groups,
  });

  factory DashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return DashboardResponseModel(
      scope: json['scope'] as String? ?? '',
      computedAt: json['computedAt'] as String? ?? '',
      groups: (json['groups'] as List<dynamic>?)
              ?.map((item) => DashboardGroupModel.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList() ??
          const [],
    );
  }
}

class DashboardGroupModel extends DashboardGroup {
  const DashboardGroupModel({required super.title, required super.panels});

  factory DashboardGroupModel.fromJson(Map<String, dynamic> json) {
    return DashboardGroupModel(
      title: json['title'] as String? ?? '',
      panels: (json['panels'] as List<dynamic>?)
              ?.map((item) => DashboardPanelModel.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList() ??
          const [],
    );
  }
}

class DashboardPanelModel extends DashboardPanel {
  const DashboardPanelModel({
    required super.id,
    required super.span,
    super.metric,
  });

  factory DashboardPanelModel.fromJson(Map<String, dynamic> json) {
    final rawMetric = json['metric'];
    return DashboardPanelModel(
      id: json['id'] as String? ?? '',
      span: json['span'] as int? ?? 12,
      metric: rawMetric is Map<String, dynamic>
          ? MetricResultModel.fromJson(rawMetric)
          : null,
    );
  }
}

class MetricResultModel extends MetricResult {
  const MetricResultModel({
    required super.id,
    required super.title,
    super.subtitle,
    required super.unit,
    required super.availability,
    required super.payload,
    super.computedAt,
  });

  factory MetricResultModel.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return MetricResultModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      unit: json['unit'] as String? ?? '',
      availability: json['availability'] as String? ?? '',
      payload:
          rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : const {},
      computedAt: json['computedAt'] as String?,
    );
  }
}

class StoreResponseStatusModel extends StoreResponseStatus {
  const StoreResponseStatusModel({
    required super.blocked,
    super.sampleSize,
    super.medianMinutes,
    super.thresholdMinutes,
    super.minSample,
    super.windowDays,
  });

  factory StoreResponseStatusModel.fromJson(Map<String, dynamic> json) {
    return StoreResponseStatusModel(
      blocked: json['blocked'] as bool? ?? true,
      sampleSize: json['sampleSize'] as num?,
      medianMinutes: json['medianMinutes'] as num?,
      thresholdMinutes: json['thresholdMinutes'] as num?,
      minSample: json['minSample'] as num?,
      windowDays: json['windowDays'] as num?,
    );
  }
}
