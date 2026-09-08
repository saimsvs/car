import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

Future<void> showAddEntrySheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddEntrySheet(),
  );
}

class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({super.key});

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  LogKind _kind = LogKind.fuel;
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _mileage = TextEditingController();
  final _liters = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'Fuel';
  bool _saving = false;

  static const _categories = {
    LogKind.fuel: ['Fuel'],
    LogKind.service: ['Service', 'Oil', 'Tires', 'Brakes', 'Inspection'],
    LogKind.expense: ['Parts', 'Care', 'Insurance', 'Parking', 'Tax', 'Other'],
    LogKind.income: ['Rideshare', 'Delivery', 'Other'],
  };

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    final v = store.activeVehicle;
    if (v != null) _mileage.text = '${v.mileage}';
    _title.text = 'Fuel fill-up';
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _mileage.dispose();
    _liters.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onKind(LogKind kind) {
    setState(() {
      _kind = kind;
      _category = _categories[kind]!.first;
      _title.text = switch (kind) {
        LogKind.fuel => 'Fuel fill-up',
        LogKind.service => 'Service',
        LogKind.expense => 'Expense',
        LogKind.income => 'Income',
      };
    });
  }

  Future<void> _save() async {
    final store = context.read<AppStore>();
    final v = store.activeVehicle;
    if (v == null) return;
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    setState(() => _saving = true);
    await store.addLog(
      ExpenseLog(
        id: store.newId(),
        vehicleId: v.id,
        kind: _kind,
        title: _title.text.trim().isEmpty ? _category : _title.text.trim(),
        category: _category,
        amount: amount,
        date: DateTime.now(),
        mileage: int.tryParse(_mileage.text.trim()),
        liters: double.tryParse(_liters.text.trim()),
        notes: _notes.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_kind.name} saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Log entry',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Saved on this device · backup anytime to Drive',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in LogKind.values)
                    ChoiceChip(
                      label: Text(k.name[0].toUpperCase() + k.name.substring(1)),
                      selected: _kind == k,
                      onSelected: (_) => _onKind(k),
                      selectedColor: AppColors.tealSoft,
                      labelStyle: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: _kind == k ? AppColors.tealDeep : AppColors.inkSoft,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _field(_title, 'Title'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _decoration('Category'),
                items: [
                  for (final c in _categories[_kind]!)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field(_amount, 'Amount', keyboard: TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_mileage, 'Mileage', keyboard: TextInputType.number)),
                ],
              ),
              if (_kind == LogKind.fuel) ...[
                const SizedBox(height: 10),
                _field(_liters, 'Liters / gallons', keyboard: TextInputType.numberWithOptions(decimal: true)),
              ],
              const SizedBox(height: 10),
              _field(_notes, 'Notes (optional)', maxLines: 2),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: _decoration(label),
    );
  }
}
