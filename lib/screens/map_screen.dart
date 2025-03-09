import 'package:flutter/material.dart';
import '../models/bus_stop.dart';
import 'bus_details_screen.dart';
import '../widgets/location_search_field.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _showResults = false;
  BusStop? _startLocation;
  BusStop? _endLocation;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _searchBuses() {
    if (_startLocation != null && _endLocation != null) {
      setState(() => _showResults = true);
    }
  }

  void _handleStartLocationSelected(BusStop stop) {
    setState(() {
      _startLocation = stop;
      _showResults = false;
    });
  }

  void _handleEndLocationSelected(BusStop stop) {
    setState(() {
      _endLocation = stop;
      _showResults = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Section
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LocationSearchField(
                  controller: _startController,
                  hintText: 'Enter starting point',
                  onLocationSelected: _handleStartLocationSelected,
                ),
                const SizedBox(height: 16),
                LocationSearchField(
                  controller: _endController,
                  hintText: 'Enter destination',
                  onLocationSelected: _handleEndLocationSelected,
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_startLocation != null && _endLocation != null) ? _searchBuses : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Search Buses',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Results Section
        if (_showResults)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3, // Sample data
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text('Route ${index + 1}'),
                    subtitle: const Text('Via: Stop A, Stop B, Stop C'),
                    trailing: const Text('30 mins'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusDetailsScreen(
                            busId: 'Bus${index + 1}',
                            routeName: 'Route ${index + 1}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}