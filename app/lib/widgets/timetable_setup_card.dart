import 'package:flutter/material.dart';
import '../models/timetable_slot.dart';
import '../config/theme.dart';
import 'custom_card.dart';

class TimetableSetupCard extends StatelessWidget {
  final TimetableSlot slot;
  final String subName;
  final String displayTime;
  final VoidCallback onDelete;

  const TimetableSetupCard({
    super.key,
    required this.slot,
    required this.subName,
    required this.displayTime,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(displayTime, style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary)),
              ],
            ),
          ),
          if (slot.classRoom.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(label: Text(slot.classRoom, style: const TextStyle(fontSize: 12))),
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
