import 'package:flutter/foundation.dart';

@immutable
class BusStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> routeIds;

  const BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.routeIds,
  });

  BusStop copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    List<String>? routeIds,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      routeIds: routeIds ?? this.routeIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'route_ids': routeIds,
    };
  }

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      routeIds: (json['route_ids'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusStop &&
        other.id == id &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        listEquals(other.routeIds, routeIds);
  }

  @override
  int get hashCode {
    return Object.hash(id, name, latitude, longitude, Object.hashAll(routeIds));
  }
}