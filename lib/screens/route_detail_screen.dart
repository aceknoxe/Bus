import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/bus.dart';
import '../widgets/real_time_bus_update.dart';

class RouteDetailScreen extends StatelessWidget {
  final BusRoute route;
  final List<BusStop> stops;
  final List<Bus> buses;

  const RouteDetailScreen({
    super.key,
    required this.route,
    required this.stops,
    required this.buses,
  });

  @override
  Widget build(BuildContext context) {
    final busesOnRoute = buses.where((bus) => bus.routeId == route.id).toList();
    final routeStops = stops
        .where((stop) => route.stopIds.contains(stop.id))
        .toList()
      ..sort((a, b) => route.stopIds.indexOf(a.id).compareTo(route.stopIds.indexOf(b.id)));

    return Scaffold(
      appBar: AppBar(
        title: Text(route.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement route notifications toggle
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Route Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          route.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.directions_bus,
                              label: '${busesOnRoute.length} Buses',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.schedule,
                              label: route.scheduleType.toUpperCase(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Real-time Updates
                const SizedBox(height: 16),
                RealTimeBusUpdate(routeId: route.id),
              ],
            ),
          ),
          // Schedule and Stops
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'STOPS'),
                      Tab(text: 'SCHEDULE'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Stops List
                        ListView.builder(
                          itemCount: routeStops.length,
                          itemBuilder: (context, index) {
                            final stop = routeStops[index];
                            final busAtStop = busesOnRoute
                                .where((bus) => bus.currentStopId == stop.id)
                                .toList();
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(stop.name),
                              subtitle: busAtStop.isNotEmpty
                                  ? Text(
                                      '${busAtStop.length} bus(es) at stop',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // TODO: Navigate to stop detail
                              },
                            );
                          },
                        ),
                        // Schedule List
                        ListView.builder(
                          itemCount: routeStops.length,
                          itemBuilder: (context, index) {
                            final stop = routeStops[index];
                            final times = route.schedule[stop.id] ?? [];
                            
                            return ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(stop.name),
                              children: times.isEmpty
                                  ? [
                                      const ListTile(
                                        title: Text('No scheduled times available'),
                                      )
                                    ]
                                  : times.map((time) {
                                      final parsedTime = DateFormat.Hm().parse(time);
                                      return ListTile(
                                        title: Text(
                                          DateFormat.jm().format(parsedTime),
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                      );
                                    }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}