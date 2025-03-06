import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';

class SearchService {
  final SupabaseClient _supabase;

  SearchService(this._supabase);

  Future<Map<String, dynamic>> search(String query) async {
    if (query.isEmpty) {
      return {
        'routes': <BusRoute>[],
        'stops': <BusStop>[],
      };
    }

    final routes = await searchRoutes(query);
    final stops = await searchStops(query);

    return {
      'routes': routes,
      'stops': stops,
    };
  }

  Future<List<BusStop>> searchStops(String query) async {
    final response = await _supabase.from('bus_stops').select('''
      *,
      route_stops!inner (
        route_id
      )
    ''').ilike('name', '%$query%');

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

  Future<List<BusRoute>> searchRoutes(String query) async {
    final response = await _supabase.from('bus_routes').select('''
      *,
      route_stops!inner (
        stop_id,
        stop_order
      ),
      route_schedules (
        stop_id,
        arrival_time,
        schedule_type
      )
    ''')
    .or('name.ilike.%${query}%,description.ilike.%${query}%')
    .order('name');

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
}