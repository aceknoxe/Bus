import 'package:flutter/material.dart';

class StopsScreen extends StatelessWidget {
  const StopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Demo data
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
          title: Text('Bus Stop ${index + 1}'),
          subtitle: Text('${2 + index} routes • Next bus in ${3 + index} mins'),
          trailing: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          onTap: () {
            // TODO: Navigate to stop details
          },
        );
      },
    );
  }
}