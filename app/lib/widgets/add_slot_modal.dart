import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../models/timetable_slot.dart';
import '../config/theme.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/success_snackbar.dart';

/// A reusable bottom sheet for adding a timetable slot.
/// 
/// [semId] and [dayOfWeek] are required.
/// [subjects] is the list of available subjects.
/// [existingSlots] is used for overlap checks (optional).
/// [specificDate] is set for ad-hoc slots (dayOfWeek = 0).
class AddSlotModal extends StatefulWidget {
  final int semId;
  final int dayOfWeek;
  final List<Subject> subjects;
  final List<TimetableSlot> existingSlots;
  final String? specificDate;
  final Future<String?> Function(TimetableSlot) onSave;

  const AddSlotModal({
    super.key,
    required this.semId,
    required this.dayOfWeek,
    required this.subjects,
    required this.existingSlots,
    required this.onSave,
    this.specificDate,
  });

  @override
  State<AddSlotModal> createState() => _AddSlotModalState();
}

class _AddSlotModalState extends State<AddSlotModal> {
  late Subject? _selectedSubject;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _classroomCtrl = TextEditingController();
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.subjects.isNotEmpty ? widget.subjects.first : null;

    // Default start = end of last existing slot (or 8am)
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    for (final slot in widget.existingSlots) {
      final parts = slot.endTime.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        if (h > start.hour || (h == start.hour && m > start.minute)) {
          start = TimeOfDay(hour: h, minute: m);
        }
      }
    }
    _startTime = start;
    _endTime = TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute);
  }

  @override
  void dispose() {
    _classroomCtrl.dispose();
    super.dispose();
  }

  String _formatTod(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String _displayTod(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_selectedSubject == null) return;

    final startStr = _formatTod(_startTime);
    final endStr = _formatTod(_endTime);

    if (startStr.compareTo(endStr) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final slot = TimetableSlot(
      semId: widget.semId,
      subId: _selectedSubject!.id!,
      dayOfWeek: widget.dayOfWeek,
      startTime: startStr,
      endTime: endStr,
      classRoom: _classroomCtrl.text.trim(),
      specificDate: widget.specificDate,
    );

    Navigator.pop(context, slot);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 16, right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.specificDate != null ? 'Add Extra Lecture' : 'Add Timetable Slot',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.specificDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'One-time slot for ${widget.specificDate}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<Subject>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: widget.subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedSubject = val),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(_displayTod(_startTime)),
                  onPressed: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(_displayTod(_endTime)),
                  onPressed: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _classroomCtrl,
            decoration: const InputDecoration(labelText: 'Classroom (Optional)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving ? 'Saving…' : 'Save Slot',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Helper to show the [AddSlotModal] as a bottom sheet.
Future<void> showAddSlotModal({
  required BuildContext context,
  required int semId,
  required int dayOfWeek,
  required List<Subject> subjects,
  required List<TimetableSlot> existingSlots,
  required Future<String?> Function(TimetableSlot) onSave,
  String? specificDate,
}) async {
  final result = await showModalBottomSheet<TimetableSlot>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).extension<AppColorScheme>()!.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AddSlotModal(
      semId: semId,
      dayOfWeek: dayOfWeek,
      subjects: subjects,
      existingSlots: existingSlots,
      onSave: onSave,
      specificDate: specificDate,
    ),
  );

  if (result != null && context.mounted) {
    final error = await onSave(result);
    if (context.mounted) {
      if (error != null) {
        showErrorSnackBar(context, error);
      } else {
        showSuccessSnackBar(context, 'Slot added successfully!');
      }
    }
  }
}
