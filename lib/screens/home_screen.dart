import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/bus_route.dart';
import 'route_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../services/supabase_service.dart';

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

  final _searchController2 = TextEditingController();
  String _searchQuery2 = '';
  List<BusRoute> _searchResults2 = [];
  bool _isSearching2 = false;
  BusStop? _selectedStop;
  BusRoute? _selectedRoute;
  List<Bus> _foundBuses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Subscribe to real-time updates
    SupabaseService.instance.realtimeService.busUpdates.listen((bus) {
      _updateBusList(bus);
    });
  }

  // Method to update the bus list
  void _updateBusList(Bus updatedBus) {
  setState(() {
    // Find the index of the updated bus
    int index = _buses.indexWhere((bus) => bus.id == updatedBus.id);

    if (index != -1) {
      // Update the existing bus
      _buses[index] = updatedBus;
    } else {
      // Add the new bus (shouldn't normally happen with our ESP32 setup, but good to handle)
      _buses.add(updatedBus);
    }
    _buses.sort((a, b) => a.id.compareTo(b.id)); // optional sorting
  });
}

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Available Stops',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final stop = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(
                        stop.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Connected to ${stop.routeIds.length} routes'),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.location_on, color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedStop = stop;
                          _searchController.text = stop.name;
                          _searchResults = [];
                        });
                      },
                    ),
                  );
                },
              ),
            ],
            if (_searchResults2.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Available Routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults2.length,
                itemBuilder: (context, index) {
                  final route = _searchResults2[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(
                        'Route ${route.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${route.stopIds.length} stops'),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.directions_bus, color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedRoute = route;
                          _searchController2.text = route.name;
                          _searchResults2 = [];
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesList() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(
                'Route ${route.name}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('${route.stopIds.length} stops'),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.directions_bus, color: Colors.white),
              ),
              onTap: () {
                setState(() {
                  _selectedRoute = route;
                  _searchController2.text = route.name;
                });
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchController2.dispose();
    super.dispose();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data. Please check your connection.';
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = [];
        _isSearching = false;
      } else {
        _isSearching = true;
        _searchResults = _stops
            .where((stop) =>
                stop.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onSearchRoutes(String query) {
    setState(() {
      _searchQuery2 = query;
      if (query.isEmpty) {
        _searchResults2 = [];
        _isSearching2 = false;
      } else {
        _isSearching2 = true;
        _searchResults2 = _routes
            .where((route) =>
                route.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Where would you like to go?',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _searchController,
                                    onChanged: _onSearch,
                                    decoration: InputDecoration(
                                      hintText: 'Enter stop name...',
                                      prefixIcon: const Icon(Icons.location_on),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _searchController2,
                                    onChanged: _onSearchRoutes,
                                    decoration: InputDecoration(
                                      hintText: 'Enter route number...',
                                      prefixIcon: const Icon(Icons.directions_bus),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_selectedStop != null && _selectedRoute != null) {
                                          final service = SupabaseService.instance;
                                          final buses = await service.busService.getBusesByRoute(_selectedRoute!.id);
                                          setState(() {
                                            _foundBuses = buses;
                                          });

                                          if (mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RouteDetailScreen(
                                                  route: _selectedRoute!,
                                                  buses: _foundBuses,
                                                  stops: _stops,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        "Find Buses",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isSearching || _isSearching2
                          ? _buildSearchResults()
                          :
                          // Display the list of buses and their current stops
                          ListView.builder(
                            itemCount: _buses.length,
                            itemBuilder: (context, index) {
                              final bus = _buses[index];
                              // Find the corresponding stop name
                              final stopName = _stops.firstWhere(
                                (stop) => stop.id == bus.currentStopId,
                                orElse: () => const BusStop(id: '', name: 'Unknown Stop', latitude: 0, longitude: 0, routeIds: []),
                              ).name;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  title: Text('Bus ${bus.id}'),
                                  subtitle: Text('Current Stop: $stopName'),
                                  leading: const Icon(Icons.directions_bus),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
    );
  }
}