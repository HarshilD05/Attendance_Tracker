import 'package:flutter/material.dart';
import '../models/timetable.dart';
import '../models/subject.dart';
import '../services/timetable_service.dart';
import '../services/subject_service.dart';
import '../theme/app_colors.dart';

class TimetableScreen extends StatefulWidget {
  final String semesterId;
  
  const TimetableScreen({
    super.key,
    required this.semesterId,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  final SubjectService _subjectService = SubjectService();
  
  TimeTable? _timetable;
  List<Subject> _subjects = [];
  WeekDay _selectedDay = WeekDay.monday;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load timetable and subjects from subcollections
      final timetableFuture = _timetableService.getTimeTable(widget.semesterId);
      final subjectsFuture = _subjectService.getSubjects(widget.semesterId);
      
      final results = await Future.wait([timetableFuture, subjectsFuture]);
      
      setState(() {
        _timetable = results[0] as TimeTable?;
        _subjects = results[1] as List<Subject>;
        
        // Filter out subjects with empty or null IDs to prevent dropdown issues
        _subjects = _subjects.where((subject) => 
          subject.id.isNotEmpty && subject.subjectName.isNotEmpty
        ).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showAddSlotDialog() {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add subjects first')),
      );
      return;
    }
    
    _showSlotDialog();
  }

  void _showEditSlotDialog(TimeSlot slot, int slotIndex) {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subjects available')),
      );
      return;
    }
    _showSlotDialog(slot: slot, slotIndex: slotIndex);
  }

  void _showSlotDialog({TimeSlot? slot, int? slotIndex}) {
    final isEditing = slot != null;
    
    // Check if there are subjects available
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subjects available. Please add subjects first.')),
      );
      return;
    }
    
    // Safely initialize selectedSubjectId
    String? selectedSubjectId;
    if (isEditing) {
      // Check if the slot's subject still exists in the current subjects list
      final subjectExists = _subjects.any((s) => s.id == slot.subjectId && s.id.isNotEmpty);
      selectedSubjectId = subjectExists ? slot.subjectId : _subjects.first.id;
    } else {
      selectedSubjectId = _subjects.first.id;
    }
    
    // Final safety check - ensure selectedSubjectId is valid
    if (selectedSubjectId.isEmpty) {
      selectedSubjectId = _subjects.first.id;
    }

    final startTimeController = TextEditingController(text: slot?.startTime ?? '09:00');
    final endTimeController = TextEditingController(text: slot?.endTime ?? '10:00');
    final roomController = TextEditingController(text: slot?.room ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Time Slot' : 'Add Time Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.subjectName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedSubjectId = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a subject';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Start time
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (HH:mm)',
                    border: OutlineInputBorder(),
                    hintText: '09:00',
                  ),
                  onTap: () => _selectStartTime(context, startTimeController, endTimeController, setDialogState),
                  readOnly: true,
                ),
                
                const SizedBox(height: 16),
                
                // End time
                TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time (HH:mm)',
                    border: OutlineInputBorder(),
                    hintText: '10:00',
                  ),
                  onTap: () => _selectTime(context, endTimeController),
                  readOnly: true,
                ),
                
                const SizedBox(height: 16),
                
                // Room Number (optional)
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedSubjectId == null || selectedSubjectId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a subject')),
                  );
                  return;
                }
                _saveSlot(
                  isEditing,
                  slotIndex,
                  selectedSubjectId!,
                  startTimeController.text,
                  endTimeController.text,
                  roomController.text,
                );
              },
              child: Text(isEditing ? 'Save' : 'Add Slot'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final currentTime = TimeOfDay.now();
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (selectedTime != null) {
      final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  Future<void> _selectStartTime(
    BuildContext context, 
    TextEditingController startController, 
    TextEditingController endController,
    void Function(VoidCallback) setDialogState,
  ) async {
    final currentTime = TimeOfDay(hour: 9, minute: 0); // Default to 9 AM
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (selectedTime != null) {
      final formattedStartTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      // Auto-calculate end time (1 hour after start time)
      final endHour = selectedTime.hour + 1;
      final formattedEndTime = '${endHour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      setDialogState(() {
        startController.text = formattedStartTime;
        endController.text = formattedEndTime;
      });
    }
  }

  Future<void> _saveSlot(
    bool isEditing,
    int? slotIndex,
    String subjectId,
    String startTime,
    String endTime,
    String room,
  ) async {
    if (startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time and end time are required')),
      );
      return;
    }

    // Validate time format and logic
    if (!_isValidTimeRange(startTime, endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time range. End time must be after start time.')),
      );
      return;
    }

    try {
      Navigator.pop(context); // Close dialog

      // Create a new TimeSlot object
      final timeSlot = TimeSlot(
        subjectId: subjectId,
        startTime: startTime,
        endTime: endTime,
        room: room.isNotEmpty ? room : null,
      );

      if (isEditing && slotIndex != null) {
        // For editing, we need to remove the old slot and add the new one
        final daySlots = _timetable!.schedule[_selectedDay] ?? [];
        if (slotIndex < daySlots.length) {
          final oldSlot = daySlots[slotIndex];
          await _timetableService.removeTimeSlot(
            widget.semesterId, 
            _selectedDay, 
            oldSlot.subjectId, 
            oldSlot.startTime
          );
        }
      }
      
      // Add the new time slot
      await _timetableService.addTimeSlot(
        widget.semesterId,
        _selectedDay,
        timeSlot,
      );

      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Time slot updated' : 'Time slot added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving time slot: $e')),
        );
      }
    }
  }

  bool _isValidTimeRange(String startTime, String endTime) {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      
      return endMinutes > startMinutes;
    } catch (e) {
      return false;
    }
  }

  Future<void> _deleteSlot(int slotIndex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: const Text('Are you sure you want to delete this time slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Get the slot to remove
        final slots = _timetable!.schedule[_selectedDay] ?? [];
        if (slotIndex < slots.length) {
          final slot = slots[slotIndex];
          
          await _timetableService.removeTimeSlot(
            widget.semesterId,
            _selectedDay,
            slot.subjectId,
            slot.startTime,
          );
        }
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Time slot deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting time slot: $e')),
          );
        }
      }
    }
  }

  String _getSubjectName(String subjectId) {
    try {
      return _subjects.firstWhere((s) => s.id == subjectId).subjectName;
    } catch (e) {
      return 'Unknown Subject';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        actions: [
          IconButton(
            onPressed: _showAddSlotDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Time Slot',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Day: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<WeekDay>(
                          value: _selectedDay,
                          isExpanded: true,
                          items: WeekDay.values.map((day) {
                            return DropdownMenuItem(
                              value: day,
                              child: Text(day.displayName),
                            );
                          }).toList(),
                          onChanged: (day) {
                            if (day != null) {
                              setState(() => _selectedDay = day);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddSlotDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Slot'),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Timetable for selected day
                Expanded(
                  child: _buildDayTimetable(),
                ),
              ],
            ),
    );
  }

  Widget _buildDayTimetable() {
    if (_timetable == null) {
      return const Center(child: Text('No timetable found'));
    }
    
    final daySlots = _timetable!.schedule[_selectedDay] ?? [];
    
    if (daySlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add time slots for ${_selectedDay.displayName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddSlotDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Time Slot'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: daySlots.length,
        itemBuilder: (context, index) {
          final slot = daySlots[index];
          return _buildTimeSlotCard(slot, index);
        },
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot, int index) {
    final subjectName = _getSubjectName(slot.subjectId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.schedule,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          subjectName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${slot.startTime} - ${slot.endTime}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (slot.room != null && slot.room!.isNotEmpty)
              Text('Room: ${slot.room}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditSlotDialog(slot, index);
            } else if (value == 'delete') {
              _deleteSlot(index);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}