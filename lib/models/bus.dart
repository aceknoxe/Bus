import 'package:flutter/foundation.dart';

@immutable
class Bus {
  final String id;
  final String routeId;
  final String currentStopId;
  final DateTime lastUpdate;

  const Bus({
    required this.id,
    required this.routeId,
    required this.currentStopId,
    required this.lastUpdate,
  });

  Bus copyWith({
    String? id,
    String? routeId,
    String? currentStopId,
    DateTime? lastUpdate,
  }) {
    return Bus(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      currentStopId: currentStopId ?? this.currentStopId,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'current_stop_id': currentStopId,
      'last_update': lastUpdate.toIso8601String(),
    };
  }

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      currentStopId: json['current_stop_id'] as String,
      lastUpdate: DateTime.parse(json['last_update'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bus &&
        other.id == id &&
        other.routeId == routeId &&
        other.currentStopId == currentStopId &&
        other.lastUpdate == lastUpdate;
  }

  @override
  int get hashCode {
    return Object.hash(id, routeId, currentStopId, lastUpdate);
  }
}