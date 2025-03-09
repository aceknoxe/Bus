import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bus_service.dart';
import 'search_service.dart';
import 'realtime_service.dart';
import 'location_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient _client;
  late final BusService busService;
  late final SearchService searchService;
  late final RealtimeService realtimeService;
  late final LocationService locationService;

  SupabaseService._();

  void _initializeServices() {
    _client = Supabase.instance.client;
    busService = BusService(_client);
    realtimeService = RealtimeService(_client);
    searchService = SearchService(_client);
    locationService = LocationService(_client);
  }

  static Future<SupabaseService> initialize() async {
    if (_instance != null) return _instance!;

    await dotenv.load();
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception('Missing Supabase configuration. Please check your .env file.');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _instance = SupabaseService._();
    _instance!._initializeServices();

    return _instance!;
  }

  static SupabaseService get instance {
    if (_instance == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  bool get isAuthenticated => _client.auth.currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}