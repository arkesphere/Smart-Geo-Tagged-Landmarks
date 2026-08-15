import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'helpers.dart';
import 'landmark_details.dart';


class LandmarksScreen extends StatelessWidget {
  const LandmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.visibleLandmarks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Landmarks'),
        actions: [

          IconButton(
            tooltip: state.sortHighToLow ? 'Score: high first' : 'Score: low first',
            onPressed: () => state.setSort(!state.sortHighToLow),
            icon: Icon(state.sortHighToLow
                ? Icons.arrow_downward
                : Icons.arrow_upward),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!state.online)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text('Offline - showing cached data'),
            ),
          if (state.error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Text(state.error!),
            ),

          // Requirement 4: filter by minimum score.
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'Minimum score',
                border: const OutlineInputBorder(),
                helperText: '${items.length} of ${state.landmarks.length} shown',
              ),
              onChanged: (value) => state.setMinScore(
                value.trim().isEmpty ? null : double.tryParse(value.trim()),
              ),
            ),
          ),

          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: state.refresh,
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final l = items[i];
                        return ListTile(
                          leading: landmarkThumbnail(l.imageUrl),
                          title: Text(l.title),
                          subtitle: Text(
                            'Score: ${l.score.toStringAsFixed(1)}   '
                            'Visits: ${l.visitCount}',
                          ),
                          onTap: () => showLandmarkDetails(context, l),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
