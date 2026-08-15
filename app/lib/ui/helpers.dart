import 'package:flutter/material.dart';


Color scoreColor(double score, double lowest, double highest) {
  if (highest <= lowest) return Colors.orange;
  final t = ((score - lowest) / (highest - lowest)).clamp(0.0, 1.0);
  return Color.lerp(Colors.red, Colors.green, t)!;
}

String formatDistance(double metres) {
  if (metres < 1000) return '${metres.toStringAsFixed(1)} m';
  return '${(metres / 1000).toStringAsFixed(2)} km';
}

String formatTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '${t.day}/${t.month}/${t.year}  $h:$m';
}

void showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showError(BuildContext context, String message) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Widget landmarkThumbnail(String? url, {double size = 56}) {
  if (url == null) {
    return Icon(Icons.photo, size: size, color: Colors.grey);
  }
  return Image.network(
    url,
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        Icon(Icons.photo, size: size, color: Colors.grey),
  );
}
