import 'package:flutter/foundation.dart';

@immutable
class BusRoute {
  final String id;
  final String name;
  final List<String> stopIds;
  final String description;
  final String scheduleType; // 'weekday', 'weekend', 'holiday'
  final Map<String, List<String>> schedule; // stopId -> list of scheduled times

  const BusRoute({
    required this.id,
    required this.name,
    required this.stopIds,
    required this.description,
    required this.scheduleType,
    required this.schedule,
  });

  BusRoute copyWith({
    String? id,
    String? name,
    List<String>? stopIds,
    String? description,
    String? scheduleType,
    Map<String, List<String>>? schedule,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      stopIds: stopIds ?? this.stopIds,
      description: description ?? this.description,
      scheduleType: scheduleType ?? this.scheduleType,
      schedule: schedule ?? this.schedule,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stop_ids': stopIds,
      'description': description,
      'schedule_type': scheduleType,
      'schedule': schedule,
    };
  }

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      stopIds: (json['stop_ids'] as List<dynamic>).cast<String>(),
      description: json['description'] as String,
      scheduleType: json['schedule_type'] as String,
      schedule: (json['schedule'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusRoute &&
        other.id == id &&
        other.name == name &&
        listEquals(other.stopIds, stopIds) &&
        other.description == description &&
        other.scheduleType == scheduleType &&
        mapEquals(other.schedule, schedule);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      Object.hashAll(stopIds),
      description,
      scheduleType,
      Object.hashAll(schedule.entries),
    );
  }
}