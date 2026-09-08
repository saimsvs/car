import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/models.dart';

Future<void> showAddVehicleDialog(BuildContext context) =>
    showVehicleEditor(context);

/// Add a vehicle, or edit [vehicle] when one is supplied.
Future<void> showVehicleEditor(BuildContext context, {Vehicle? vehicle}) async {
  final store = context.read<AppStore>();
  final editing = vehicle != null;
  final name = TextEditingController(text: vehicle?.name ?? '');
  final year =
      TextEditingController(text: '${vehicle?.year ?? DateTime.now().year}');
  final make = TextEditingController(text: vehicle?.make ?? '');
  final model = TextEditingController(text: vehicle?.model ?? '');
  final trim = TextEditingController(text: vehicle?.trim ?? '');
  final mileage = TextEditingController(text: '${vehicle?.mileage ?? 0}');
  final plate = TextEditingController(text: vehicle?.plate ?? '');

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(editing ? 'Edit vehicle' : 'Add vehicle'),
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
              controller: trim,
              decoration: const InputDecoration(labelText: 'Trim (optional)'),
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
          child: Text(editing ? 'Save' : 'Add'),
        ),
      ],
    ),
  );

  if (ok != true) return;
  final label = name.text.trim();
  if (label.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name for the vehicle')),
      );
    }
    return;
  }

  await store.upsertVehicle(
    Vehicle(
      id: vehicle?.id ?? store.newId(),
      name: label,
      year: int.tryParse(year.text) ?? DateTime.now().year,
      make: make.text.trim(),
      model: model.text.trim(),
      trim: trim.text.trim(),
      plate: plate.text.trim(),
      mileage: int.tryParse(mileage.text) ?? vehicle?.mileage ?? 0,
    ),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editing ? 'Vehicle updated' : 'Vehicle added')),
    );
  }
}

Future<void> confirmDeleteVehicle(BuildContext context, Vehicle vehicle) async {
  final store = context.read<AppStore>();
  if (store.vehicles.length <= 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Keep at least one vehicle')),
    );
    return;
  }

  final logCount = store.logsForVehicle(vehicle.id).length;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete ${vehicle.name}?'),
      content: Text(
        logCount == 0
            ? 'This removes the vehicle and its reminders.'
            : 'This also deletes $logCount log '
                '${logCount == 1 ? 'entry' : 'entries'} and its reminders.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (ok != true) return;
  await store.deleteVehicle(vehicle.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vehicle.name} deleted')),
    );
  }
}
