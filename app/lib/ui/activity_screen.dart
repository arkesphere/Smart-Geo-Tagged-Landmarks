import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../background_sync.dart';
import '../models.dart';
import 'helpers.dart';


class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            tooltip: 'Ask WorkManager to sync now',
            onPressed: () async {
              await BackgroundSync.requestSync();
              await state.loadFromCache();
              if (context.mounted) showMessage(context, 'Sync requested.');
            },
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: state.visits.isEmpty
          ? const Center(child: Text('No visits yet.'))
          : ListView.builder(
              itemCount: state.visits.length,
              itemBuilder: (context, i) {
                final v = state.visits[i];

                final String result = switch (v.status) {
                  VisitStatus.queued => 'Queued - waiting for a connection',
                  VisitStatus.pending => 'Processing... (job ${v.jobId})',
                  VisitStatus.done =>
                    'Distance: ${formatDistance(v.distance ?? 0)}',
                  VisitStatus.failed => v.error ?? 'Failed',
                };

                return ListTile(
                  leading: Icon(
                    v.status == VisitStatus.done
                        ? Icons.check_circle
                        : v.status == VisitStatus.failed
                            ? Icons.error
                            : Icons.hourglass_empty,
                  ),
                  title: Text(v.landmarkTitle),
                  subtitle: Text('${formatTime(v.createdAt)}\n$result'),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
