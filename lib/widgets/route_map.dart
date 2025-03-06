import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';

class RouteMap extends StatefulWidget {
  final List<BusStop> stops;
  final List<BusRoute> routes;
  final List<Bus> buses;
  final VoidCallback? onMapReady;
  final Function(MapController)? onControllerReady;

  const RouteMap({
    super.key,
    required this.stops,
    required this.routes,
    required this.buses,
    this.onMapReady,
    this.onControllerReady,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    widget.onControllerReady?.call(_mapController);
  }

  @override
  Widget build(BuildContext context) {
    // Center map on first stop or default location
    final center = widget.stops.isNotEmpty
        ? LatLng(widget.stops.first.latitude, widget.stops.first.longitude)
        : const LatLng(12.9716, 77.5946); // Default: Bangalore

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: center,
        zoom: 13,
        onMapReady: widget.onMapReady,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bus',
        ),
        // Route lines
        PolylineLayer(
          polylines: widget.routes.map((route) {
            final routeStops = widget.stops
                .where((stop) => route.stopIds.contains(stop.id))
                .toList();
            return Polyline(
              points: routeStops
                  .map((stop) => LatLng(stop.latitude, stop.longitude))
                  .toList(),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              strokeWidth: 3.0,
            );
          }).toList(),
        ),
        // Bus stops
        MarkerLayer(
          markers: widget.stops.map((stop) {
            final point = LatLng(stop.latitude, stop.longitude);
            return Marker(
              point: point,
              child: Tooltip(
                message: stop.name,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Buses
        MarkerLayer(
          markers: widget.buses.map((bus) {
            final stop = widget.stops
                .firstWhere((stop) => stop.id == bus.currentStopId);
            final point = LatLng(stop.latitude, stop.longitude);
            return Marker(
              point: point,
              child: Tooltip(
                message: 'Bus at ${stop.name}',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}