import 'package:flutter/material.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today's updates
        _buildSection(
          context,
          'Today',
          [
            _buildUpdateCard(
              context,
              title: 'Bus B1 Status',
              message: 'Currently at Stop 3, running on time',
              time: '2 mins ago',
              icon: Icons.directions_bus,
              color: Colors.green,
            ),
            _buildUpdateCard(
              context,
              title: 'Route R2 Delay',
              message: 'Minor delay due to traffic',
              time: '15 mins ago',
              icon: Icons.warning_outlined,
              color: Colors.orange,
            ),
            _buildUpdateCard(
              context,
              title: 'Bus B3 Location',
              message: 'Arriving at Stop 5 in 3 minutes',
              time: '30 mins ago',
              icon: Icons.location_on,
              color: Colors.blue,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Yesterday's updates
        _buildSection(
          context,
          'Yesterday',
          [
            _buildUpdateCard(
              context,
              title: 'Service Update',
              message: 'All routes operating normally',
              time: '1 day ago',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            _buildUpdateCard(
              context,
              title: 'Route Changes',
              message: 'Route R1 modified due to road work',
              time: '1 day ago',
              icon: Icons.route,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> updates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...updates,
      ],
    );
  }

  Widget _buildUpdateCard(
    BuildContext context, {
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}