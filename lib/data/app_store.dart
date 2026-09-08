import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'notification_service.dart';

class AppStore extends ChangeNotifier {
  static const _key = 'car_track_v1';

  bool ready = false;
  AppPrefs prefs = AppPrefs();
  List<Vehicle> vehicles = [];
  List<ExpenseLog> logs = [];
  List<ReminderItem> reminders = [];
  String? activeVehicleId;

  Vehicle? get activeVehicle {
    if (vehicles.isEmpty) return null;
    return vehicles.cast<Vehicle?>().firstWhere(
          (v) => v!.id == activeVehicleId,
          orElse: () => vehicles.first,
        );
  }

  Future<void> load() async {
    final prefsStore = await SharedPreferences.getInstance();
    final raw = prefsStore.getString(_key);
    if (raw == null) {
      _seed();
    } else {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        prefs = AppPrefs.fromJson(map['prefs'] as Map<String, dynamic>? ?? {});
        vehicles = (map['vehicles'] as List? ?? [])
            .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
            .toList();
        logs = (map['logs'] as List? ?? [])
            .map((e) => ExpenseLog.fromJson(e as Map<String, dynamic>))
            .toList();
        reminders = (map['reminders'] as List? ?? [])
            .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
            .toList();
        activeVehicleId = map['activeVehicleId'] as String?;
        if (vehicles.isEmpty) _seed();
      } catch (_) {
        _seed();
      }
    }
    activeVehicleId ??= vehicles.first.id;
    ready = true;
    notifyListeners();
    await syncNotifications();
  }

  /// Rebuilds the scheduled notifications from the current reminders.
  Future<void> syncNotifications() async {
    await NotificationService.instance.syncReminders(
      reminders: reminders,
      vehicleNames: {for (final v in vehicles) v.id: v.name},
      enabled: prefs.remindersEnabled,
    );
  }

  Future<void> _persist() async {
    final prefsStore = await SharedPreferences.getInstance();
    await prefsStore.setString(
      _key,
      jsonEncode({
        'prefs': prefs.toJson(),
        'vehicles': vehicles.map((e) => e.toJson()).toList(),
        'logs': logs.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toJson()).toList(),
        'activeVehicleId': activeVehicleId,
      }),
    );
  }

  String _id() =>
      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  void _seed() {
    final vId = _id();
    vehicles = [
      Vehicle(
        id: vId,
        name: 'Toyota Camry',
        year: 2021,
        make: 'Toyota',
        model: 'Camry',
        trim: 'SE',
        plate: 'ABC-4821',
        mileage: 42180,
      ),
    ];
    activeVehicleId = vId;
    final now = DateTime.now();
    logs = [
      ExpenseLog(
        id: _id(),
        vehicleId: vId,
        kind: LogKind.fuel,
        title: 'Shell Fuel',
        category: 'Fuel',
        amount: 62.40,
        date: now,
        mileage: 42180,
        liters: 12.5,
      ),
      ExpenseLog(
        id: _id(),
        vehicleId: vId,
        kind: LogKind.expense,
        title: 'AutoZone Filters',
        category: 'Parts',
        amount: 38.90,
        date: now.subtract(const Duration(days: 1)),
      ),
      ExpenseLog(
        id: _id(),
        vehicleId: vId,
        kind: LogKind.expense,
        title: 'Wash & Detail',
        category: 'Care',
        amount: 25.00,
        date: now.subtract(const Duration(days: 5)),
      ),
      ExpenseLog(
        id: _id(),
        vehicleId: vId,
        kind: LogKind.service,
        title: 'Brake inspection',
        category: 'Service',
        amount: 120.00,
        date: now.subtract(const Duration(days: 28)),
        mileage: 41800,
      ),
      ExpenseLog(
        id: _id(),
        vehicleId: vId,
        kind: LogKind.fuel,
        title: 'Chevron',
        category: 'Fuel',
        amount: 58.20,
        date: now.subtract(const Duration(days: 8)),
        mileage: 41950,
        liters: 11.8,
      ),
    ];
    reminders = [
      ReminderItem(
        id: _id(),
        vehicleId: vId,
        title: 'Oil change',
        dueDate: now.add(const Duration(days: 12)),
        dueMileage: 45000,
      ),
      ReminderItem(
        id: _id(),
        vehicleId: vId,
        title: 'Tire rotation',
        dueDate: now.add(const Duration(days: 28)),
      ),
    ];
    prefs = AppPrefs(
      displayName: 'Alex',
      email: 'alex@cartrack.app',
      currency: 'USD',
      useMiles: true,
      remindersEnabled: true,
    );
  }

  Future<void> setActiveVehicle(String id) async {
    activeVehicleId = id;
    notifyListeners();
    await _persist();
  }

  Future<void> upsertVehicle(Vehicle v) async {
    final i = vehicles.indexWhere((e) => e.id == v.id);
    if (i >= 0) {
      vehicles[i] = v;
    } else {
      vehicles.add(v);
      activeVehicleId = v.id;
    }
    notifyListeners();
    await _persist();
    // Reminder notifications name the vehicle, so a rename changes their text.
    await syncNotifications();
  }

  /// Removes a vehicle along with everything logged against it.
  /// The last vehicle is kept so the app always has something to show.
  Future<bool> deleteVehicle(String id) async {
    if (vehicles.length <= 1) return false;
    vehicles.removeWhere((e) => e.id == id);
    logs.removeWhere((e) => e.vehicleId == id);
    reminders.removeWhere((e) => e.vehicleId == id);
    if (activeVehicleId == id) activeVehicleId = vehicles.first.id;
    notifyListeners();
    await _persist();
    await syncNotifications();
    return true;
  }

  Future<void> addLog(ExpenseLog log) async {
    logs.insert(0, log);
    final i = vehicles.indexWhere((e) => e.id == log.vehicleId);
    if (i >= 0 && log.mileage != null && log.mileage! > vehicles[i].mileage) {
      vehicles[i].mileage = log.mileage!;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> updateLog(ExpenseLog log) async {
    final i = logs.indexWhere((e) => e.id == log.id);
    if (i < 0) return;
    logs[i] = log;
    final v = vehicles.indexWhere((e) => e.id == log.vehicleId);
    if (v >= 0 && log.mileage != null && log.mileage! > vehicles[v].mileage) {
      vehicles[v].mileage = log.mileage!;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteLog(String id) async {
    logs.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> addReminder(ReminderItem r) async {
    reminders.add(r);
    notifyListeners();
    await _persist();
    await syncNotifications();
  }

  Future<void> updateReminder(ReminderItem r) async {
    final i = reminders.indexWhere((e) => e.id == r.id);
    if (i < 0) return;
    reminders[i] = r;
    notifyListeners();
    await _persist();
    await syncNotifications();
  }

  Future<void> deleteReminder(String id) async {
    reminders.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
    await syncNotifications();
  }

  Future<void> completeReminder(String id) async {
    await _setReminderDone(id, true);
  }

  Future<void> reopenReminder(String id) async {
    await _setReminderDone(id, false);
  }

  Future<void> _setReminderDone(String id, bool done) async {
    final r = reminders.cast<ReminderItem?>().firstWhere(
          (e) => e!.id == id,
          orElse: () => null,
        );
    if (r == null) return;
    r.done = done;
    notifyListeners();
    await _persist();
    await syncNotifications();
  }

  Future<void> updatePrefs(AppPrefs p) async {
    prefs = p;
    notifyListeners();
    await _persist();
  }

  Future<void> setRemindersEnabled(bool value) async {
    prefs.remindersEnabled = value;
    notifyListeners();
    await _persist();
    await syncNotifications();
  }

  List<ExpenseLog> logsForVehicle([String? vehicleId]) {
    final id = vehicleId ?? activeVehicleId;
    return logs.where((e) => e.vehicleId == id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<ReminderItem> openReminders([String? vehicleId]) {
    final id = vehicleId ?? activeVehicleId;
    return reminders
        .where((e) => e.vehicleId == id && !e.done)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  double spendInMonth(DateTime month, [String? vehicleId]) {
    final id = vehicleId ?? activeVehicleId;
    return logs
        .where(
          (e) =>
              e.vehicleId == id &&
              e.kind != LogKind.income &&
              e.date.year == month.year &&
              e.date.month == month.month,
        )
        .fold(0.0, (s, e) => s + e.amount);
  }

  double spendInRange(DateTime start, DateTime end, [String? vehicleId]) {
    final id = vehicleId ?? activeVehicleId;
    return logs
        .where(
          (e) =>
              e.vehicleId == id &&
              e.kind != LogKind.income &&
              !e.date.isBefore(start) &&
              !e.date.isAfter(end),
        )
        .fold(0.0, (s, e) => s + e.amount);
  }

  Map<String, double> categoryTotals(DateTime start, DateTime end) {
    final map = <String, double>{};
    for (final e in logsForVehicle()) {
      if (e.kind == LogKind.income) continue;
      if (e.date.isBefore(start) || e.date.isAfter(end)) continue;
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<double> lastSixMonthTotals() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return spendInMonth(m);
    });
  }

  /// Distance per unit of fuel, both in the user's chosen units
  /// (miles per gallon, or kilometers per liter).
  double? averageMpg() {
    final fuel = logsForVehicle()
        .where((e) => e.kind == LogKind.fuel && e.liters != null && e.mileage != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (fuel.length < 2) return null;
    var totalDistance = 0.0;
    var totalVolume = 0.0;
    for (var i = 1; i < fuel.length; i++) {
      final prev = fuel[i - 1];
      final cur = fuel[i];
      final distance = (cur.mileage! - prev.mileage!).toDouble();
      if (distance <= 0 || cur.liters == null || cur.liters! <= 0) continue;
      totalDistance += distance;
      totalVolume += cur.liters!;
    }
    if (totalVolume <= 0) return null;
    return totalDistance / totalVolume;
  }

  double? costPerDistance() {
    final v = activeVehicle;
    if (v == null) return null;
    final spent = logsForVehicle()
        .where((e) => e.kind != LogKind.income)
        .fold(0.0, (s, e) => s + e.amount);
    final withMiles = logsForVehicle().where((e) => e.mileage != null).toList()
      ..sort((a, b) => a.mileage!.compareTo(b.mileage!));
    if (withMiles.length < 2) return null;
    final dist = (withMiles.last.mileage! - withMiles.first.mileage!).toDouble();
    if (dist <= 0) return null;
    return spent / dist;
  }

  String money(double amount) {
    final s = prefs.currencySymbol;
    return '$s${amount.toStringAsFixed(2)}';
  }

  Future<void> replaceAllFromBackup(Map<String, dynamic> map) async {
    prefs = AppPrefs.fromJson(map['prefs'] as Map<String, dynamic>? ?? {});
    vehicles = (map['vehicles'] as List? ?? [])
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
    logs = (map['logs'] as List? ?? [])
        .map((e) => ExpenseLog.fromJson(e as Map<String, dynamic>))
        .toList();
    reminders = (map['reminders'] as List? ?? [])
        .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
        .toList();
    activeVehicleId = map['activeVehicleId'] as String?;
    if (vehicles.isEmpty) {
      _seed();
    } else {
      activeVehicleId ??= vehicles.first.id;
    }
    notifyListeners();
    await _persist();
    await syncNotifications();
  }

  String newId() => _id();
}
