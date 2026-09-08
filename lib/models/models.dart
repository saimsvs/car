enum LogKind { fuel, service, expense, income }

class Vehicle {
  Vehicle({
    required this.id,
    required this.name,
    required this.year,
    required this.make,
    required this.model,
    required this.mileage,
    this.plate = '',
    this.trim = '',
  });

  final String id;
  String name;
  int year;
  String make;
  String model;
  String trim;
  String plate;
  int mileage;

  String get subtitle {
    final parts = <String>[
      '$year',
      if (trim.isNotEmpty) trim,
      if (plate.isNotEmpty) plate,
    ];
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'year': year,
        'make': make,
        'model': model,
        'trim': trim,
        'plate': plate,
        'mileage': mileage,
      };

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        name: j['name'] as String,
        year: j['year'] as int,
        make: j['make'] as String? ?? '',
        model: j['model'] as String? ?? '',
        trim: j['trim'] as String? ?? '',
        plate: j['plate'] as String? ?? '',
        mileage: j['mileage'] as int? ?? 0,
      );
}

class ReminderItem {
  ReminderItem({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.dueDate,
    this.dueMileage,
    this.done = false,
  });

  final String id;
  final String vehicleId;
  String title;
  DateTime dueDate;
  int? dueMileage;
  bool done;

  int get daysLeft => dueDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'dueMileage': dueMileage,
        'done': done,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> j) => ReminderItem(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        title: j['title'] as String,
        dueDate: DateTime.parse(j['dueDate'] as String),
        dueMileage: j['dueMileage'] as int?,
        done: j['done'] as bool? ?? false,
      );
}

class ExpenseLog {
  ExpenseLog({
    required this.id,
    required this.vehicleId,
    required this.kind,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.mileage,
    this.notes = '',
    this.liters,
  });

  final String id;
  final String vehicleId;
  final LogKind kind;
  String title;
  String category;
  double amount;
  DateTime date;
  int? mileage;
  String notes;
  double? liters;

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'kind': kind.name,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'mileage': mileage,
        'notes': notes,
        'liters': liters,
      };

  factory ExpenseLog.fromJson(Map<String, dynamic> j) => ExpenseLog(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        kind: LogKind.values.firstWhere(
          (e) => e.name == j['kind'],
          orElse: () => LogKind.expense,
        ),
        title: j['title'] as String,
        category: j['category'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        mileage: j['mileage'] as int?,
        notes: j['notes'] as String? ?? '',
        liters: (j['liters'] as num?)?.toDouble(),
      );
}

class AppPrefs {
  AppPrefs({
    this.displayName = 'Driver',
    this.email = '',
    this.currency = 'USD',
    this.useMiles = true,
    this.remindersEnabled = true,
  });

  String displayName;
  String email;
  String currency;
  bool useMiles;
  bool remindersEnabled;

  String get currencySymbol => switch (currency) {
        'EUR' => '€',
        'GBP' => '£',
        'PKR' => 'Rs ',
        'INR' => '₹',
        _ => '\$',
      };

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'currency': currency,
        'useMiles': useMiles,
        'remindersEnabled': remindersEnabled,
      };

  factory AppPrefs.fromJson(Map<String, dynamic> j) => AppPrefs(
        displayName: j['displayName'] as String? ?? 'Driver',
        email: j['email'] as String? ?? '',
        currency: j['currency'] as String? ?? 'USD',
        useMiles: j['useMiles'] as bool? ?? true,
        remindersEnabled: j['remindersEnabled'] as bool? ?? true,
      );
}
