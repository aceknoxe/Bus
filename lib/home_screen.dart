import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'models/bus.dart';
import 'models/bus_stop.dart';
import 'models/bus_route.dart';
import 'widgets/route_map.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Bus> _buses = [];
  List<BusStop> _stops = [];
  List<BusRoute> _routes = [];
  bool _isLoading = true;
  String? _error;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<BusStop> _searchResults = [];
  bool _isSearching = false;
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController = null;
    super.dispose();
  }

  void _moveToStop(BusStop stop) {
    if (_mapController != null) {
      _mapController!.move(
        LatLng(stop.latitude, stop.longitude),
        15.0, // Higher zoom level for stop detail
      );
    }
  }

  void _showRoute(BusRoute route) {
    if (_mapController != null) {
      final routeStops = _stops.where((stop) => route.stopIds.contains(stop.id)).toList();
      if (routeStops.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(
          routeStops.map((stop) => LatLng(stop.latitude, stop.longitude)).toList(),
        );
        _mapController!.fitBounds(
          bounds,
          options: const FitBoundsOptions(
            padding: EdgeInsets.all(30.0),
          ),
        );
      }
    }
  }

  void _fitAllStops() {
    if (_mapController != null && _stops.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(
        _stops.map((stop) => LatLng(stop.latitude, stop.longitude)).toList(),
      );
      _mapController!.fitBounds(
        bounds,
        options: const FitBoundsOptions(
          padding: EdgeInsets.all(50.0),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final service = SupabaseService.instance;
      final stops = await service.busService.getAllStops();
      final routes = await service.busService.getAllRoutes();
      final buses = await service.busService.getAllBuses();

      if (!mounted) return;

      setState(() {
        _stops = stops;
        _routes = routes;
        _buses = buses;
        _isLoading = false;
      });

      // Wait for the map to be ready before fitting bounds
      Future.delayed(const Duration(milliseconds: 100), _fitAllStops);

      service.realtimeService.busUpdates.listen((bus) {
        if (mounted) {
          setState(() {
            _buses = _buses.map((b) => b.id == bus.id ? bus : b).toList();
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data. Please check your connection.';
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final stops = await SupabaseService.instance.searchService.searchStops(query);
      if (mounted) {
        setState(() {
          _searchResults = stops;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading bus data...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onChanged: _searchLocations,
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                cursorColor: Theme.of(context).colorScheme.onPrimary,
              )
            : const Text('Live Bus Tracker'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchResults.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RouteMap(
            stops: _stops,
            routes: _routes,
            buses: _buses,
            onControllerReady: (controller) {
              _mapController = controller;
            },
          ),
          if (_isSearching && _searchResults.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 136,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final stop = _searchResults[index];
                    return ListTile(
                      title: Text(stop.name),
                      subtitle: Text('${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}'),
                      leading: const Icon(Icons.location_on_outlined),
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchResults.clear();
                          _isSearching = false;
                        });
                        _moveToStop(stop);
                      },
                    );
                  },
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'Active Routes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          final route = _routes[index];
                          final busesOnRoute = _buses
                              .where((bus) => bus.routeId == route.id)
                              .toList();

                          return InkWell(
                            onTap: () => _showRoute(route),
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).colorScheme.surfaceVariant,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${busesOnRoute.length} buses active',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    route.description,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}