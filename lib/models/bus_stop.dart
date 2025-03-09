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
    final location = json['location'] as Map<String, dynamic>;
    final coordinates = location['coordinates'] as List<dynamic>;
    
    // Convert coordinates to double, handling both numeric and string inputs
    final longitude = coordinates[0] is num 
        ? (coordinates[0] as num).toDouble()
        : double.parse(coordinates[0].toString());
    final latitude = coordinates[1] is num 
        ? (coordinates[1] as num).toDouble()
        : double.parse(coordinates[1].toString());
    
    return BusStop(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: latitude,
      longitude: longitude,
      routeIds: (json['route_ids'] as List? ?? []).cast<String>(),
    );
  }
  factory BusStop.fromDatabaseJson(Map<String, dynamic> json) {
    // Extract coordinates from PostGIS POINT data
    final location = json['location'];
    double latitude = 0.0;
    double longitude = 0.0;

    if (location != null) {
      try {
        // Handle WKB (Well-Known Binary) format
        if (location is String && location.startsWith('0101')) {
          // Skip the first 4 bytes (SRID) and the next 1 byte (byteOrder)
          final coordBytes = location.substring(18);
          // PostGIS returns coordinates in the format: longitude,latitude
          final coordPairs = coordBytes.split('00000000000000');
          if (coordPairs.length >= 2) {
            longitude = double.parse(coordPairs[0]);
            latitude = double.parse(coordPairs[1]);
          }
        } else if (location is Map) {
          // Handle GeoJSON-like format
          final coordinates = location['coordinates'] as List;
          longitude = coordinates[0];
          latitude = coordinates[1];
        }
      } catch (e) {
        print('Error parsing location data: $e');
      }
    }

    return BusStop(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: latitude,
      longitude: longitude,
      routeIds: json['route_ids'] != null
          ? (json['route_ids'] as List<dynamic>).cast<String>()
          : [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusStop &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          listEquals(routeIds, other.routeIds);

 @override
  int get hashCode => Object.hash(id, name, latitude, longitude, routeIds);
}