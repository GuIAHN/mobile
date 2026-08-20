import 'package:equatable/equatable.dart';

class DashboardResponse extends Equatable {
  final String scope;
  final String computedAt;
  final List<DashboardGroup> groups;

  const DashboardResponse({
    required this.scope,
    required this.computedAt,
    required this.groups,
  });

  @override
  List<Object?> get props => [scope, computedAt, groups];

  MetricResult? metricById(String id) {
    for (final group in groups) {
      for (final panel in group.panels) {
        if (panel.id == id && panel.metric != null) return panel.metric;
      }
    }
    return null;
  }

  DashboardResponse replaceMetric(MetricResult replacement) {
    var replaced = false;
    final updatedGroups = groups.map((group) {
      final updatedPanels = group.panels.map((panel) {
        if (panel.id != replacement.id) return panel;
        replaced = true;
        return DashboardPanel(
          id: panel.id,
          span: panel.span,
          metric: replacement,
        );
      }).toList();

      return DashboardGroup(title: group.title, panels: updatedPanels);
    }).toList();

    return replaced
        ? DashboardResponse(
            scope: scope,
            computedAt: computedAt,
            groups: updatedGroups,
          )
        : this;
  }

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      scope: json['scope'] as String? ?? '',
      computedAt: json['computedAt'] as String? ?? '',
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => DashboardGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DashboardGroup extends Equatable {
  final String title;
  final List<DashboardPanel> panels;

  const DashboardGroup({
    required this.title,
    required this.panels,
  });

  @override
  List<Object?> get props => [title, panels];

  factory DashboardGroup.fromJson(Map<String, dynamic> json) {
    return DashboardGroup(
      title: json['title'] as String? ?? '',
      panels: (json['panels'] as List<dynamic>?)
              ?.map((e) => DashboardPanel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DashboardPanel extends Equatable {
  final String id;
  final int span;
  final MetricResult? metric;

  const DashboardPanel({
    required this.id,
    required this.span,
    this.metric,
  });

  @override
  List<Object?> get props => [id, span, metric];

  factory DashboardPanel.fromJson(Map<String, dynamic> json) {
    return DashboardPanel(
      id: json['id'] as String? ?? '',
      span: json['span'] as int? ?? 12,
      metric: json['metric'] != null
          ? MetricResult.fromJson(json['metric'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MetricResult extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final String unit;
  final String availability;
  final Map<String, dynamic> payload;

  const MetricResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.unit,
    required this.availability,
    required this.payload,
  });

  @override
  List<Object?> get props => [id, title, subtitle, unit, availability, payload];

  factory MetricResult.fromJson(Map<String, dynamic> json) {
    return MetricResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      unit: json['unit'] as String? ?? '',
      availability: json['availability'] as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }
}
