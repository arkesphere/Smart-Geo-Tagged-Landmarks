import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../app_state.dart';
import 'helpers.dart';


class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _title = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  File? _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation(quiet: true));
  }

  @override
  void dispose() {
    _title.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation({bool quiet = false}) async {
    setState(() => _busy = true);
    try {
      final position = await getCurrentLocation();
      if (!mounted) return;
      _lat.text = position.latitude.toStringAsFixed(6);
      _lon.text = position.longitude.toStringAsFixed(6);
      if (!quiet) showMessage(context, 'GPS location filled in.');
    } on AppException catch (e) {
      if (mounted && !quiet) await showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80, // keeps it under the 2 MB the API accepts
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _create() async {
    final state = context.read<AppState>();
    final title = _title.text.trim();
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());

    if (title.isEmpty || lat == null || lon == null) {
      await showError(context, 'Enter a title and valid coordinates.');
      return;
    }

    setState(() => _busy = true);
    try {
      final id = await state.createLandmark(
        title: title,
        lat: lat,
        lon: lon,
        image: _image,
      );
      if (!mounted) return;
      showMessage(context, 'Landmark created (id $id).');
      _title.clear();
      setState(() => _image = null);
    } on AppException catch (e) {
      if (mounted) await showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add / View')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('New landmark',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lon,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: _busy ? null : () => _useMyLocation(),
            icon: const Icon(Icons.my_location),
            label: const Text('Use my location'),
          ),

          Row(
            children: [
              if (_image != null)
                Image.file(_image!, width: 60, height: 60, fit: BoxFit.cover),
              if (_image != null) const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_image == null ? 'Pick image' : 'Change image'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _busy ? null : _create,
            child: Text(_busy ? 'Please wait...' : 'Create landmark'),
          ),

          const Divider(height: 40),


          const Text('Deleted landmarks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (state.deleted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing deleted yet.'),
            ),
          for (final d in state.deleted)
            ListTile(
              title: Text(d.title),
              subtitle: Text('id ${d.id}'),
              trailing: TextButton(
                onPressed: () async {
                  try {
                    await state.restoreLandmark(d.id);
                    if (context.mounted) showMessage(context, 'Restored.');
                  } on AppException catch (e) {
                    if (context.mounted) await showError(context, e.message);
                  }
                },
                child: const Text('Restore'),
              ),
            ),
        ],
      ),
    );
  }
}
