import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../services/supabase_service.dart';
import '../models/bus_stop.dart';

class RealTimeBusUpdate extends StatefulWidget {
  final String? routeId;
  final String? stopId;

  const RealTimeBusUpdate({
    super.key,
    this.routeId,
    this.stopId,
  });

  @override
  State<RealTimeBusUpdate> createState() => _RealTimeBusUpdateState();
}

class _RealTimeBusUpdateState extends State<RealTimeBusUpdate> {
  late Stream<Bus> _busUpdates;
  final _busService = SupabaseService.instance.busService;
  final _realtimeService = SupabaseService.instance.realtimeService;

  @override
  void initState() {
    super.initState();
    _busUpdates = _realtimeService.busUpdates;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Bus>(
      stream: _busUpdates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final bus = snapshot.data!;
        
        // Filter updates based on route or stop
        if (widget.routeId != null && bus.routeId != widget.routeId) {
          return const SizedBox.shrink();
        }
        if (widget.stopId != null && bus.currentStopId != widget.stopId) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<BusStop?>(
          future: _busService.getStopById(bus.currentStopId),
          builder: (context, stopSnapshot) {
            if (!stopSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final stop = stopSnapshot.data!;
            final updateTime = bus.lastUpdate;
            final timeString = "${updateTime.hour}:${updateTime.minute.toString().padLeft(2, '0')}";

            return Card(
              margin: const EdgeInsets.all(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bus Update',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            timeString,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current Location:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}