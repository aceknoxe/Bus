import 'package:flutter/material.dart';
import '../models/bus_stop.dart';
import '../services/supabase_service.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(BusStop) onLocationSelected;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onLocationSelected,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  List<BusStop> _suggestions = [];
  bool _isLoading = false;
  final _locationService = SupabaseService.instance.locationService;

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      // Show all locations when the field is clicked or empty
      try {
        final results = await _locationService.searchLocations('');
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isLoading = false;
          });
        }
        print('Error getting all locations: $e');
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _locationService.searchLocations(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
      print('Error getting suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _getSuggestions,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final stop = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(stop.name),
                  onTap: () {
                    widget.controller.text = stop.name;
                    widget.onLocationSelected(stop);
                    setState(() => _suggestions = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}