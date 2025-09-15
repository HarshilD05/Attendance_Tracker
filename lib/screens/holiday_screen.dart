import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/semester.dart';
import '../services/semester_service.dart';

class HolidayScreen extends StatefulWidget {
  final Semester semester;

  const HolidayScreen({
    Key? key,
    required this.semester,
  }) : super(key: key);

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  final SemesterService _semesterService = SemesterService();
  
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  late Set<DateTime> _holidayDates;
  late Set<DateTime> _originalHolidayDates;
  
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeCalendar();
  }

  void _initializeCalendar() {
    // Set calendar bounds to semester dates
    _firstDay = widget.semester.semStartDate;
    _lastDay = widget.semester.semEndDate;
    _focusedDay = DateTime.now().isAfter(_firstDay) && DateTime.now().isBefore(_lastDay)
        ? DateTime.now()
        : _firstDay;

    // Initialize holiday dates (normalize to date only, no time)
    _holidayDates = widget.semester.holidayList
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    _originalHolidayDates = Set.from(_holidayDates);
  }

  bool _isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year && 
           day1.month == day2.month && 
           day1.day == day2.day;
  }

  bool _isHoliday(DateTime day) {
    return _holidayDates.any((holiday) => _isSameDay(holiday, day));
  }

  void _toggleHoliday(DateTime day) {
    if (!_isEditMode) return;
    
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    setState(() {
      if (_isHoliday(day)) {
        _holidayDates.removeWhere((holiday) => _isSameDay(holiday, day));
      } else {
        _holidayDates.add(normalizedDay);
      }
      _hasChanges = !_holidayDates.containsAll(_originalHolidayDates) ||
                   !_originalHolidayDates.containsAll(_holidayDates);
    });
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode && _hasChanges) {
        // Show unsaved changes dialog
        _showUnsavedChangesDialog();
      } else {
        _isEditMode = !_isEditMode;
        if (!_isEditMode) {
          // Reset changes if cancelled
          _holidayDates = Set.from(_originalHolidayDates);
          _hasChanges = false;
        }
      }
    });
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditMode = false;
                _holidayDates = Set.from(_originalHolidayDates);
                _hasChanges = false;
              });
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert set back to list for the semester model
      final holidayList = _holidayDates.toList();
      holidayList.sort(); // Sort dates chronologically

      // Update the semester with new holiday list
      final updatedSemester = widget.semester.copyWith(
        holidayList: holidayList,
      );

      await _semesterService.updateSemester(updatedSemester);

      setState(() {
        _originalHolidayDates = Set.from(_holidayDates);
        _hasChanges = false;
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Holidays updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating holidays: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.semester.name} - Holidays'),
        actions: [
          if (_isEditMode) ...[
            TextButton(
              onPressed: (_isLoading || !_hasChanges) ? null : _saveHolidays,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: _hasChanges ? null : Colors.grey,
                      ),
                    ),
            ),
            IconButton(
              onPressed: _isLoading ? null : _toggleEditMode,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
            ),
          ] else
            IconButton(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Holidays',
            ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isEditMode ? Colors.orange.withValues( alpha: 0.1) : Colors.blue.withValues( alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  _isEditMode ? Icons.edit : Icons.info_outline,
                  color: _isEditMode ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEditMode
                        ? 'Tap on dates to mark/unmark as holidays. Red overlay indicates holidays.'
                        : 'View semester holidays. Tap the edit button to modify holidays.',
                    style: TextStyle(
                      color: _isEditMode ? Colors.orange.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TableCalendar<DateTime>(
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  
                  // Calendar styling
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red.shade600),
                    holidayTextStyle: TextStyle(color: Colors.red.shade600),
                    
                    // Default day decoration
                    defaultDecoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    
                    // Weekend decoration
                    weekendDecoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    
                    // Today decoration
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues( alpha: 0.5),
                      border: Border.all(color: Theme.of(context).primaryColor),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    
                    // Selected day decoration (for edit mode)
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  
                  // Header styling
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(Icons.chevron_left),
                    rightChevronIcon: Icon(Icons.chevron_right),
                  ),
                  
                  // Calendar builders for custom day rendering
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildDayCell(day, false, false);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildDayCell(day, true, false);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return _buildDayCell(day, false, true);
                    },
                  ),
                  
                  // Calendar event callbacks
                  onDaySelected: _isEditMode ? (selectedDay, focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    _toggleHoliday(selectedDay);
                  } : null,
                  
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                ),
              ),
            ),
          ),
          
          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total Days',
                  widget.semester.durationInDays.toString(),
                  Icons.calendar_today,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Holidays',
                  _holidayDates.length.toString(),
                  Icons.holiday_village,
                  Colors.red,
                ),
                _buildStatCard(
                  'Working Days',
                  widget.semester.totalWorkingDays.toString(),
                  Icons.work,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
      // Floating action button for save when in edit mode
      floatingActionButton: _isEditMode && _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveHolidays,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isOutside) {
    final isHolidayDay = _isHoliday(day);
    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isToday 
              ? Theme.of(context).primaryColor 
              : Colors.grey.shade300,
          width: isToday ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
        color: isOutside 
            ? Colors.grey.shade100
            : isToday 
                ? Theme.of(context).primaryColor.withValues( alpha: 0.1)
                : Colors.white,
      ),
      child: Stack(
        children: [
          // Day number
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isOutside
                    ? Colors.grey.shade400
                    : isWeekend
                        ? Colors.red.shade600
                        : isToday
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          
          // Holiday overlay (red line at top)
          if (isHolidayDay && !isOutside)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
              ),
            ),
          
          // Edit mode tap indicator
          if (_isEditMode && !isOutside)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _toggleHoliday(day),
                  child: Container(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}