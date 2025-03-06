import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';

class BusService {
  final SupabaseClient _supabase;

  BusService(this._supabase);

  // Bus Methods
  Future<List<Bus>> getAllBuses() async {
    final response = await _supabase
        .from('buses')
        .select()
        .order('last_update', ascending: false);
    return response.map((json) => Bus.fromJson(json)).toList();
  }

  Future<Bus?> getBusById(String id) async {
    final response = await _supabase
        .from('buses')
        .select()
        .eq('id', id)
        .single();
    return response == null ? null : Bus.fromJson(response);
  }

  Future<List<Bus>> getBusesByRoute(String routeId) async {
    final response = await _supabase
        .from('buses')
        .select()
        .eq('route_id', routeId)
        .order('last_update', ascending: false);
    return response.map((json) => Bus.fromJson(json)).toList();
  }

  // Bus Stop Methods
  Future<List<BusStop>> getAllStops() async {
    final response = await _supabase.from('bus_stops').select('''
      *,
      route_stops (
        route_id
      )
    ''').not('route_stops', 'is', 'null');

    return response.map((json) {
      final routeIds = (json['route_stops'] as List)
          .map((stop) => stop['route_id'] as String)
          .toList();

      return BusStop(
        id: json['id'],
        name: json['name'],
        latitude: (json['location']['coordinates'][1] as num).toDouble(),
        longitude: (json['location']['coordinates'][0] as num).toDouble(),
        routeIds: routeIds,
      );
    }).toList();
  }

  Future<BusStop?> getStopById(String id) async {
    final response = await _supabase.from('bus_stops').select('''
      *,
      route_stops (
        route_id
      )
    ''').eq('id', id).not('route_stops', 'is', 'null').single();

    if (response == null) return null;

    final routeIds = (response['route_stops'] as List)
        .map((stop) => stop['route_id'] as String)
        .toList();

    return BusStop(
      id: response['id'],
      name: response['name'],
      latitude: (response['location']['coordinates'][1] as num).toDouble(),
      longitude: (response['location']['coordinates'][0] as num).toDouble(),
      routeIds: routeIds,
    );
  }

  // Bus Route Methods
  Future<List<BusRoute>> getAllRoutes() async {
    final response = await _supabase.from('bus_routes').select('''
      *,
      route_stops (
        stop_id,
        stop_order
      ),
      route_schedules (
        stop_id,
        arrival_time,
        schedule_type
      )
    ''').not('route_stops', 'is', 'null').order('name');

    return response.map((json) {
      final stopIds = (json['route_stops'] as List)
          .map((stop) => stop['stop_id'] as String)
          .toList();

      final schedule = <String, List<String>>{};
      for (final scheduleItem in json['route_schedules'] as List) {
        final stopId = scheduleItem['stop_id'] as String;
        final time = scheduleItem['arrival_time'] as String;
        schedule.putIfAbsent(stopId, () => []).add(time);
      }

      return BusRoute(
        id: json['id'],
        name: json['name'],
        stopIds: stopIds,
        description: json['description'] ?? '',
        scheduleType: json['schedule_type'],
        schedule: schedule,
      );
    }).toList();
  }

  Future<BusRoute?> getRouteById(String id) async {
    final response = await _supabase.from('bus_routes').select('''
      *,
      route_stops (
        stop_id,
        stop_order
      ),
      route_schedules (
        stop_id,
        arrival_time,
        schedule_type
      )
    ''').eq('id', id).not('route_stops', 'is', 'null').single();

    if (response == null) return null;

    final stopIds = (response['route_stops'] as List)
        .map((stop) => stop['stop_id'] as String)
        .toList();

    final schedule = <String, List<String>>{};
    for (final scheduleItem in response['route_schedules'] as List) {
      final stopId = scheduleItem['stop_id'] as String;
      final time = scheduleItem['arrival_time'] as String;
      schedule.putIfAbsent(stopId, () => []).add(time);
    }

    return BusRoute(
      id: response['id'],
      name: response['name'],
      stopIds: stopIds,
      description: response['description'] ?? '',
      scheduleType: response['schedule_type'],
      schedule: schedule,
    );
  }

  // Update Bus Location
  Future<void> updateBusLocation(String busId, String stopId) async {
    await _supabase.from('buses').update({
      'current_stop_id': stopId,
      'last_update': DateTime.now().toIso8601String(),
    }).eq('id', busId);
  }

  // Nearby Stops
  Future<List<BusStop>> getNearbyStops(double lat, double lng, double radiusInMeters) async {
    final response = await _supabase.rpc(
      'nearby_stops',
      params: {
        'latitude': lat,
        'longitude': lng,
        'radius_meters': radiusInMeters,
      },
    );

    return response.map((json) {
      return BusStop(
        id: json['id'],
        name: json['name'],
        latitude: (json['location']['coordinates'][1] as num).toDouble(),
        longitude: (json['location']['coordinates'][0] as num).toDouble(),
        routeIds: (json['route_ids'] as List).cast<String>(),
      );
    }).toList();
  }
}