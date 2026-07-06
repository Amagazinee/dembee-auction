import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/formatters.dart';
import '../theme/app_theme.dart';

/// Дуудлага эхлэх цаг сонгох — сар, өдөр, цаг, минут
class AuctionSchedulePicker extends StatefulWidget {
  const AuctionSchedulePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  State<AuctionSchedulePicker> createState() => _AuctionSchedulePickerState();
}

class _AuctionSchedulePickerState extends State<AuctionSchedulePicker> {
  late int _month;
  late int _day;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _syncFromValue(widget.value);
  }

  @override
  void didUpdateWidget(AuctionSchedulePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncFromValue(widget.value);
    }
  }

  void _syncFromValue(DateTime dt) {
    _month = dt.month;
    _day = dt.day;
    _hour = dt.hour;
    _minute = dt.minute;
  }

  int get _daysInMonth {
    return DateTime(widget.value.year, _month + 1, 0).day;
  }

  void _emit() {
    final day = _day.clamp(1, _daysInMonth);
    final next = DateTime(
      widget.value.year,
      _month,
      day,
      _hour.clamp(0, 23),
      _minute.clamp(0, 59),
    );
    widget.onChanged(next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Эхлэх огноо',
      cancelText: 'Болих',
      confirmText: 'Сонгох',
    );
    if (picked == null) return;

    final next = DateTime(
      picked.year,
      picked.month,
      picked.day,
      _hour,
      _minute,
    );
    setState(() {
      _month = next.month;
      _day = next.day;
    });
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          formatScheduledStart(widget.value),
          textAlign: TextAlign.center,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 13,
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ScheduleField(
                label: 'Сар',
                value: _month,
                max: 12,
                min: 1,
                onChanged: (v) {
                  setState(() {
                    _month = v;
                    if (_day > _daysInMonth) _day = _daysInMonth;
                  });
                  _emit();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScheduleField(
                label: 'Өдөр',
                value: _day,
                max: _daysInMonth,
                min: 1,
                onChanged: (v) {
                  setState(() => _day = v);
                  _emit();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScheduleField(
                label: 'Цаг',
                value: _hour,
                max: 23,
                min: 0,
                onChanged: (v) {
                  setState(() => _hour = v);
                  _emit();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScheduleField(
                label: 'Мин',
                value: _minute,
                max: 59,
                min: 0,
                onChanged: (v) {
                  setState(() => _minute = v);
                  _emit();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month, size: 18),
          label: const Text('Календарьгаас огноо сонгох'),
        ),
      ],
    );
  }
}

class _ScheduleField extends StatelessWidget {
  const _ScheduleField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 11,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: ValueKey('$label-$value'),
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTheme.monoStyle.copyWith(
            fontSize: 16,
            color: AppTheme.foreground,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.inputBackground,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          onChanged: (text) {
            final parsed = int.tryParse(text);
            if (parsed == null) return;
            onChanged(parsed.clamp(min, max));
          },
        ),
      ],
    );
  }
}
