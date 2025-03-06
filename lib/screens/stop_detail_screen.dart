import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bus_stop.dart';
import '../models/bus_route.dart';
import '../models/bus.dart';
import 'route_detail_screen.dart';
import '../widgets/real_time_bus_update.dart';

class StopDetailScreen extends StatelessWidget {
  final BusStop stop;
  final List<BusRoute> routes;
  final List<Bus> buses;

  const StopDetailScreen({
    super.key,
    required this.stop,
    required this.routes,
    required this.buses,
  });

  @override
  Widget build(BuildContext context) {
    final stopsRoutes = routes.where((route) => stop.routeIds.contains(route.id)).toList();
    final busesAtStop = buses.where((bus) => bus.currentStopId == stop.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(stop.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement stop notifications toggle
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stop Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stop Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.directions_bus,
                              label: '${busesAtStop.length} Buses',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.route,
                              label: '${stopsRoutes.length} Routes',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Real-time Updates for this stop
                const SizedBox(height: 16),
                RealTimeBusUpdate(stopId: stop.id),
              ],
            ),
          ),
          // Routes and Schedule Tabs
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'ROUTES'),
                      Tab(text: 'SCHEDULE'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Routes List
                        ListView.builder(
                          itemCount: stopsRoutes.length,
                          itemBuilder: (context, index) {
                            final route = stopsRoutes[index];
                            final busesOnRoute = busesAtStop
                                .where((bus) => bus.routeId == route.id)
                                .toList();

                            return ListTile(
                              title: Text(route.name),
                              subtitle: Text(route.description),
                              leading: const Icon(Icons.directions_bus_outlined),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (busesOnRoute.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${busesOnRoute.length}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RouteDetailScreen(
                                      route: route,
                                      stops: [stop],
                                      buses: buses,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        // Schedule List
                        ListView.builder(
                          itemCount: stopsRoutes.length,
                          itemBuilder: (context, index) {
                            final route = stopsRoutes[index];
                            final times = route.schedule[stop.id] ?? [];

                            return ExpansionTile(
                              title: Text(route.name),
                              subtitle: Text(route.scheduleType),
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
                                        trailing: Text(
                                          'Route ${route.name}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
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