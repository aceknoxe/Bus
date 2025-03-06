import 'package:flutter/material.dart';

class BusDetailsScreen extends StatelessWidget {
  final String busId;
  final String routeName;

  const BusDetailsScreen({
    super.key,
    required this.busId,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus $busId'),
      ),
      body: Column(
        children: [
          // Bus info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route $routeName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: 2 mins ago',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Connected stops timeline
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Demo data
              itemBuilder: (context, index) {
                final isPassed = index < 4;
                final isCurrent = index == 4;
                
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Center(
                          child: Text(
                            '${7 + index}:${30 + index}',
                            style: TextStyle(
                              color: isPassed || isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // Timeline line and dot
                      SizedBox(
                        width: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (index != 0)
                              Container(
                                width: 2,
                                height: double.infinity,
                                color: isPassed || isCurrent
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.primary
                                    : isPassed
                                        ? Colors.grey
                                        : Colors.grey.withOpacity(0.3),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: isCurrent
                                  ? const Icon(
                                      Icons.directions_bus,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      // Stop info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stop ${index + 1}',
                                style: TextStyle(
                                  fontWeight:
                                      isCurrent ? FontWeight.bold : null,
                                  color: isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPassed
                                    ? 'Passed'
                                    : isCurrent
                                        ? 'Current Location'
                                        : 'Upcoming',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isCurrent
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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