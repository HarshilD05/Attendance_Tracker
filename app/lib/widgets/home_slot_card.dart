import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/timetable_slot.dart';
import '../models/attendance.dart';
import '../config/theme.dart';
import 'custom_card.dart';

class HomeSlotCard extends StatelessWidget {
  final TimetableSlot slot;
  final String subName;
  final String displayTime;
  final Attendance? existingAttendance;
  final VoidCallback onRemoveExtra;
  final void Function(int isCancelled, String studentStatus) onMarkAttendance;
  final String selectedDateIso;
  final bool isFutureDate;

  const HomeSlotCard({
    super.key,
    required this.slot,
    required this.subName,
    required this.displayTime,
    this.existingAttendance,
    required this.onRemoveExtra,
    required this.onMarkAttendance,
    required this.selectedDateIso,
    this.isFutureDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final isPresent = existingAttendance?.studentStatus == 'P';
    final isAbsent = existingAttendance?.studentStatus == 'A';
    final isCancelled = existingAttendance?.isCancelled == 1;

    return Dismissible(
      key: ValueKey('${slot.slotId}_$selectedDateIso'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (isFutureDate) return false;
        final newStatus = isCancelled ? 0 : 1;
        if (newStatus == 1) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
        final currStudentStatus = existingAttendance?.studentStatus ?? 'U';
        onMarkAttendance(newStatus, currStudentStatus);
        return false; // Toggle, don't dismiss
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.red,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Icon(isCancelled ? Icons.restore : Icons.cancel, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Icon(isCancelled ? Icons.restore : Icons.cancel, color: Colors.white),
      ),
      child: CustomCard(
        borderColor: isCancelled ? Colors.red : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(subName, style: Theme.of(context).textTheme.titleLarge),
                      if (slot.isExtraLec)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('EXTRA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                    ],
                  ),
                ),
                if (isCancelled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'CANCELLED',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                else if (slot.classRoom.isNotEmpty)
                  Chip(label: Text(slot.classRoom, style: const TextStyle(fontSize: 12))),
                
                if (slot.isExtraLec)
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Extra Lecture?'),
                          content: const Text('This will permanently delete this extra lecture and its attendance record.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        onRemoveExtra();
                      }
                    },
                  ),
              ],
            ),
            if (displayTime.isNotEmpty)
              Text(displayTime, style: TextStyle(color: appColors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPresent
                          ? appColors.present
                          : appColors.surface,
                      foregroundColor: isPresent ? Colors.white : appColors.textSecondary,
                      side: BorderSide(
                          color: isPresent
                              ? appColors.present
                              : appColors.textMuted.withValues(alpha: 0.2)),
                    ),
                    onPressed: isFutureDate ? null : () => onMarkAttendance(0, isPresent ? 'U' : 'P'),
                    child: const Text('Present'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAbsent
                          ? appColors.absent
                          : appColors.surface,
                      foregroundColor: isAbsent ? Colors.white : appColors.textSecondary,
                      side: BorderSide(
                          color: isAbsent
                              ? appColors.absent
                              : appColors.textMuted.withValues(alpha: 0.2)),
                    ),
                    onPressed: isFutureDate ? null : () => onMarkAttendance(0, isAbsent ? 'U' : 'A'),
                    child: const Text('Absent'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
