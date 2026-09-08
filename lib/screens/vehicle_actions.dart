import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/models.dart';

Future<void> showAddVehicleDialog(BuildContext context) async {
  final store = context.read<AppStore>();
  final name = TextEditingController();
  final year = TextEditingController(text: '${DateTime.now().year}');
  final make = TextEditingController();
  final model = TextEditingController();
  final mileage = TextEditingController(text: '0');
  final plate = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add vehicle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Display name'),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: make,
              decoration: const InputDecoration(labelText: 'Make'),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: model,
              decoration: const InputDecoration(labelText: 'Model'),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: year,
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: mileage,
              decoration: const InputDecoration(labelText: 'Mileage'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: plate,
              decoration: const InputDecoration(labelText: 'Plate (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Add'),
        ),
      ],
    ),
  );

  if (ok == true && name.text.trim().isNotEmpty) {
    await store.upsertVehicle(
      Vehicle(
        id: store.newId(),
        name: name.text.trim(),
        year: int.tryParse(year.text) ?? DateTime.now().year,
        make: make.text.trim(),
        model: model.text.trim(),
        plate: plate.text.trim(),
        mileage: int.tryParse(mileage.text) ?? 0,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added')),
      );
    }
  }
}
