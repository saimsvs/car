import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/models.dart';

/// Create a reminder, or edit [reminder] when one is supplied.
Future<void> showReminderEditor(
  BuildContext context, {
  ReminderItem? reminder,
}) async {
  final store = context.read<AppStore>();
  final vehicleId = reminder?.vehicleId ?? store.activeVehicle?.id;
  if (vehicleId == null) return;

  final editing = reminder != null;
  final title = TextEditingController(text: reminder?.title ?? '');
  final dueMileage =
      TextEditingController(text: reminder?.dueMileage?.toString() ?? '');
  var dueDate = reminder?.dueDate ?? DateTime.now().add(const Duration(days: 30));

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(editing ? 'Edit reminder' : 'New reminder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'What needs doing',
                  hintText: 'Oil change',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: dueMileage,
                decoration: const InputDecoration(
                  labelText: 'Due at mileage (optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due date'),
                subtitle: Text(DateFormat.yMMMd().format(dueDate)),
                trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 365)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
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
    ),
  );

  if (ok != true) return;
  final label = title.text.trim();
  if (label.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter what needs doing')),
      );
    }
    return;
  }

  final item = ReminderItem(
    id: reminder?.id ?? store.newId(),
    vehicleId: vehicleId,
    title: label,
    dueDate: dueDate,
    dueMileage: int.tryParse(dueMileage.text.trim()),
    done: reminder?.done ?? false,
  );
  if (editing) {
    await store.updateReminder(item);
  } else {
    await store.addReminder(item);
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editing ? 'Reminder updated' : 'Reminder added')),
    );
  }
}

Future<void> confirmDeleteReminder(
  BuildContext context,
  ReminderItem reminder,
) async {
  final store = context.read<AppStore>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete reminder?'),
      content: Text(reminder.title),
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
  await store.deleteReminder(reminder.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder deleted')),
    );
  }
}
