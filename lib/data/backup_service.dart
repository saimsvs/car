import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_store.dart';

/// Local-first backup:
/// 1) Writes a full CarTrack JSON snapshot on device
/// 2) Opens the system share sheet so the user can save it to Google Drive
/// 3) Restore picks that same JSON back from Drive / Files
class BackupService {
  static const appId = 'CarTrack';
  static const schemaVersion = 1;

  /// Full snapshot of everything needed to restore the app.
  static Map<String, dynamic> buildPayload(AppStore store) {
    return {
      'app': appId,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'prefs': store.prefs.toJson(),
      'vehicles': store.vehicles.map((e) => e.toJson()).toList(),
      'logs': store.logs.map((e) => e.toJson()).toList(),
      'reminders': store.reminders.map((e) => e.toJson()).toList(),
      'activeVehicleId': store.activeVehicleId,
    };
  }

  static String? validatePayload(Map<String, dynamic> map) {
    if (map['app'] != appId) {
      return 'This file is not a CarTrack backup.';
    }
    final version = map['schemaVersion'] ?? map['version'];
    if (version is! int) {
      return 'Backup file is missing a version.';
    }
    if (version > schemaVersion) {
      return 'This backup was made with a newer app version.';
    }
    if (map['vehicles'] is! List || map['logs'] is! List) {
      return 'Backup file is incomplete or corrupted.';
    }
    return null;
  }

  /// Creates backup JSON, keeps a copy in app documents, then share → Google Drive.
  static Future<void> backupToGoogleDrive(BuildContext context) async {
    final store = context.read<AppStore>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final payload = buildPayload(store);
      final json = const JsonEncoder.withIndent('  ').convert(payload);
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'cartrack_backup_$stamp.json';

      // Keep a local copy in Documents (survives until user clears app data)
      final docs = await getApplicationDocumentsDirectory();
      final localBackup = File('${docs.path}/$fileName');
      await localBackup.writeAsString(json);

      // Also stage in temp/cache for reliable sharing on Android/iOS
      final tmp = await getTemporaryDirectory();
      final shareFile = File('${tmp.path}/$fileName');
      await shareFile.writeAsString(json);

      if (!context.mounted) return;

      // iPad / macOS need an anchor rect for the popover
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              shareFile.path,
              mimeType: 'application/json',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
          subject: 'CarTrack backup $stamp',
          text:
              'CarTrack backup — choose Google Drive to save it. '
              'Includes ${store.vehicles.length} vehicle(s), '
              '${store.logs.length} log(s), '
              '${store.reminders.length} reminder(s).',
          sharePositionOrigin: origin,
        ),
      );

      if (!context.mounted) return;

      switch (result.status) {
        case ShareResultStatus.success:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Backup shared. If you picked Google Drive, your data is saved there.',
              ),
            ),
          );
        case ShareResultStatus.dismissed:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Share closed. A local backup copy was still saved on this device.',
              ),
            ),
          );
        case ShareResultStatus.unavailable:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Share unavailable. Backup file saved at: ${localBackup.path}',
              ),
            ),
          );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  /// Pick a CarTrack JSON backup (from Google Drive / Files) and restore it.
  static Future<void> restoreFromFile(BuildContext context) async {
    final store = context.read<AppStore>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
        dialogTitle: 'Choose CarTrack backup',
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.single;
      String? raw;
      if (file.bytes != null) {
        raw = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        raw = await File(file.path!).readAsString();
      }
      if (raw == null || raw.trim().isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not read that backup file.')),
        );
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Invalid backup format.')),
        );
        return;
      }

      final error = validatePayload(decoded);
      if (error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore backup?'),
          content: Text(
            'This will replace all vehicles, logs, and reminders on this device '
            'with the backup from ${decoded['exportedAt'] ?? 'unknown date'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      await store.replaceAllFromBackup(decoded);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Restored ${(decoded['vehicles'] as List).length} vehicle(s) '
            'and ${(decoded['logs'] as List).length} log(s).',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  /// Settings entry: choose Backup or Restore.
  static Future<void> showBackupSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Backup to Google Drive'),
                subtitle: const Text(
                  'Creates a full JSON backup, then open Drive in the share sheet',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  backupToGoogleDrive(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Restore from Google Drive / Files'),
                subtitle: const Text(
                  'Pick a cartrack_backup_….json you saved earlier',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  restoreFromFile(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
