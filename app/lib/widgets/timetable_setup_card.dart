import 'package:flutter/material.dart';
import '../models/timetable_slot.dart';
import '../config/theme.dart';
import 'custom_card.dart';

class TimetableSetupCard extends StatelessWidget {
  final TimetableSlot slot;
  final String subName;
  final String displayTime;
  final VoidCallback onTap;

  const TimetableSetupCard({
    Key? key,
    required this.slot,
    required this.subName,
    required this.displayTime,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(displayTime, style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary)),
            ],
          ),
          if (slot.classRoom.isNotEmpty)
            Chip(label: Text(slot.classRoom, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
