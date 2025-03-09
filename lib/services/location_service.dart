import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus_stop.dart';

class LocationService {
  final SupabaseClient _supabase;

  LocationService(this._supabase);

  Future<List<BusStop>> searchLocations(String query) async {
    try {
      final response = await _supabase
          .from('bus_stops')
          .select()
          .ilike('name', '%$query%')
          .limit(query.isEmpty ? 10 : 5);

      return response.map((json) => BusStop.fromDatabaseJson(json)).toList();
    } catch (e) {
      print('Error searching locations: $e');
      return [];
    }
  }

  Future<List<BusStop>> getNearbyStops(double lat, double lng) async {
    try {
      // Using the nearby_stops database function
      final response = await _supabase.rpc(
        'nearby_stops',
        params: {
          'latitude': lat,
          'longitude': lng,
          'radius_meters': 1000.0, // 1km radius
        },
      );

      return response.map((json) => BusStop.fromDatabaseJson(json)).toList();
    } catch (e) {
      print('Error getting nearby stops: $e');
      return [];
    }
  }
}