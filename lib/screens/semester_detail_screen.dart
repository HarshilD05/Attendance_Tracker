import 'package:flutter/material.dart';
import '../services/semester_service.dart';
import '../models/semester.dart';
import 'package:intl/intl.dart';
import 'holiday_screen.dart';
import 'subjects_screen.dart';
import 'timetable_screen.dart';

class SemesterDetailScreen extends StatefulWidget {
  final String semesterId;
  
  const SemesterDetailScreen({
    super.key,
    required this.semesterId,
  });

  @override
  State<SemesterDetailScreen> createState() => _SemesterDetailScreenState();
}

class _SemesterDetailScreenState extends State<SemesterDetailScreen>
    with SingleTickerProviderStateMixin {
  final SemesterService _semesterService = SemesterService();
  Semester? _semester;
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSemester();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSemester() async {
    try {
      final semester = await _semesterService.getSemester(widget.semesterId);
      setState(() {
        _semester = semester;
        _isLoading = false;
        _error = semester == null ? 'Semester not found' : null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _semester!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black26,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  color: theme.primaryColor,
                  child: _buildHeaderContent(),
                ),
              ),
            ),
          ];
        },
        body: _buildCardBasedNavigation(),
      ),
    );
  }

  Widget _buildHeaderContent() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isActive = _semester!.isActive;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40), // Space for app bar
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade400),
              ),
              child: Text(
                'ACTIVE SEMESTER',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white.withValues( alpha: 0.9), size: 16),
              const SizedBox(width: 8),
              Text(
                '${dateFormat.format(_semester!.semStartDate)} - ${dateFormat.format(_semester!.semEndDate)}',
                style: TextStyle(
                  color: Colors.white.withValues( alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBasedNavigation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Days',
                  _semester!.durationInDays.toString(),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Working Days',
                  _semester!.totalWorkingDays.toString(),
                  Icons.work,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Holidays',
                  _semester!.holidayList.length.toString(),
                  Icons.holiday_village,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Navigation Cards
          Text(
            'Manage Semester',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildNavigationCard(
            title: 'Subjects',
            subtitle: '${_semester!.subjectList.length} subjects',
            icon: Icons.subject,
            color: Colors.purple,
            onTap: () {
              // Navigate to subjects screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectsScreen(semesterId: _semester!.id!),
                ),
              ).then((_) => _loadSemester()); // Refresh when returning
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildNavigationCard(
            title: 'Timetable',
            subtitle: 'View and edit schedule',
            icon: Icons.schedule,
            color: Colors.orange,
            onTap: () {
              // Navigate to timetable screen or show timetable bottom sheet
              // Navigate to timetable screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimetableScreen(semesterId: _semester!.id!),
                ),
              ).then((_) => _loadSemester()); // Refresh when returning
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildNavigationCard(
            title: 'Holidays',
            subtitle: 'Manage semester holidays',
            icon: Icons.event_busy,
            color: Colors.red,
            onTap: () => _openHolidayCalendar(),
          ),
          
          const SizedBox(height: 12),
          
          _buildNavigationCard(
            title: 'Attendance',
            subtitle: 'Track your attendance',
            icon: Icons.check_circle,
            color: Colors.green,
            onTap: () {
              // Navigate to attendance screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }









  void _openHolidayCalendar() async {
    if (_semester != null) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => HolidayScreen(semester: _semester!),
        ),
      );
      
      // Refresh the semester data if holidays were updated
      if (result == true || result == null) {
        await _loadSemester();
      }
    }
  }

}


