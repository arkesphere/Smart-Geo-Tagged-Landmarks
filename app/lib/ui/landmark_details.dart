import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../app_state.dart';
import '../models.dart';
import 'helpers.dart';

void showLandmarkDetails(BuildContext context, Landmark landmark) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => _Details(landmark: landmark),
  );
}

class _Details extends StatefulWidget {
  const _Details({required this.landmark});

  final Landmark landmark;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  bool _busy = false;

  Future<void> _visit() async {
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {

      final position = await getCurrentLocation();


      await state.visitLandmark(
        widget.landmark,
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context);
      showMessage(
        context,
        state.online
            ? 'Visit sent. The distance will appear in Activity.'
            : 'Offline - the visit is queued and will be sent later.',
      );
    } on AppException catch (e) {
      if (!mounted) return;
      await showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    try {
      await state.deleteLandmark(widget.landmark);
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, 'Landmark deleted. Restore it from the Add tab.');
    } on AppException catch (e) {
      if (!mounted) return;
      await showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.landmark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          landmarkThumbnail(l.imageUrl, size: 100),
          const SizedBox(height: 8),
          Text('Score: ${l.score.toStringAsFixed(1)}'),
          Text('Visits: ${l.visitCount}'),
          Text('Average distance: ${formatDistance(l.avgDistance)}'),
          Text('Location: ${l.lat}, ${l.lon}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _visit,
                  child: Text(_busy ? 'Getting location...' : 'Visit'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _busy ? null : _delete,
                child: const Text('Delete'),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppState>().showOnMap(l);
            },
            icon: const Icon(Icons.map),
            label: const Text('Show on map'),
          ),
        ],
      ),
    );
  }
}
