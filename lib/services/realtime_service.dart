import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus.dart';

class RealtimeService {
  final SupabaseClient _supabase;
  final _busUpdateController = StreamController<Bus>.broadcast();

  Stream<Bus> get busUpdates => _busUpdateController.stream;

  RealtimeService(this._supabase) {
    _initializeRealtimeSubscription();
  }

  void _initializeRealtimeSubscription() {
    _supabase
        .from('bus_updates')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> updates) async {
      for (final update in updates) {
        try {
          // Fetch updated bus data
          final busResponse = await _supabase
              .from('buses')
              .select()
              .eq('id', update['bus_id'])
              .single();

          if (busResponse != null) {
            final bus = Bus.fromJson(busResponse);
            _busUpdateController.add(bus);
          }
        } catch (e) {
          print('Error processing bus update: $e');
        }
      }
    });
  }

  Future<void> dispose() async {
    await _busUpdateController.close();
  }
}