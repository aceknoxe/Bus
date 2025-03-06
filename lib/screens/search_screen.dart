import 'package:flutter/material.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../services/supabase_service.dart';
import 'route_detail_screen.dart';
import 'stop_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<BusRoute> _routes = [];
  List<BusStop> _stops = [];

  @override
  void initState() {
    super.initState();
    // Focus the search field automatically when screen opens
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final results = await SupabaseService.instance.searchService.search(query);
      if (mounted) {
        setState(() {
          _routes = results['routes'] as List<BusRoute>;
          _stops = results['stops'] as List<BusStop>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          onChanged: (value) => _performSearch(value),
          decoration: InputDecoration(
            hintText: 'Search routes and stops...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          cursorColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: _searchQuery.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for bus routes and stops',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (_routes.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Routes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ..._routes.map(
                        (route) => ListTile(
                          title: Text(route.name),
                          subtitle: Text(route.description),
                          leading: const Icon(Icons.directions_bus_outlined),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final stops = await SupabaseService
                                .instance.busService
                                .getAllStops();
                            final buses = await SupabaseService
                                .instance.busService
                                .getBusesByRoute(route.id);
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RouteDetailScreen(
                                    route: route,
                                    stops: stops,
                                    buses: buses,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                    if (_stops.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Stops',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ..._stops.map(
                        (stop) => ListTile(
                          title: Text(stop.name),
                          leading: const Icon(Icons.location_on_outlined),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final routes = await SupabaseService
                                .instance.busService
                                .getAllRoutes();
                            final buses = await SupabaseService
                                .instance.busService
                                .getAllBuses();
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StopDetailScreen(
                                    stop: stop,
                                    routes: routes,
                                    buses: buses,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                    if (_routes.isEmpty && _stops.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No results found',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}