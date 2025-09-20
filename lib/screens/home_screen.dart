import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/theme_manager.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/semester_service.dart';
import '../services/subject_service.dart';
import '../models/attendance.dart';
import '../models/subject.dart';

import '../widgets/auth_wrapper.dart';
import 'profile_screen.dart';
import 'debug/theme_debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum AttendanceFilter { all, unmarked, marked }

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ThemeManager _themeManager = ThemeManager();
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();
  final SemesterService _semesterService = SemesterService();
  final SubjectService _subjectService = SubjectService();
  
  User? _currentUser;
  List<SubjectAttendance> _todaysSubjects = [];
  DailyAttendance? _dailyAttendance;
  Map<String, Subject> _subjectsMap = {};
  AttendanceFilter _currentFilter = AttendanceFilter.all;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentSemesterId;
  bool _isHoliday = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadSubjectsForDate();
  }

  Future<void> _loadSubjectsForDate([DateTime? date]) async {
    final targetDate = date ?? _selectedDate;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get active semester
      final activeSemester = await _semesterService.getActiveSemester();
      if (activeSemester == null) {
        setState(() {
          _errorMessage = 'No active semester found. Please create and activate a semester first.';
          _isLoading = false;
        });
        return;
      }

      _currentSemesterId = activeSemester.id;

      // Format selected date
      final dateString = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      // Check if selected date is a holiday
      final isHoliday = await _attendanceService.isHoliday(_currentSemesterId!, dateString);
      
      // Load subjects and attendance for selected date
      List<SubjectAttendance> subjects;
      if (targetDate.year == DateTime.now().year && 
          targetDate.month == DateTime.now().month && 
          targetDate.day == DateTime.now().day) {
        // For today, use the optimized method
        subjects = await _attendanceService.getTodaysSubjects(_currentSemesterId!);
      } else {
        // For other dates, get daily attendance directly
        final dailyAttendance = await _attendanceService.getDailyAttendance(_currentSemesterId!, dateString);
        subjects = dailyAttendance.subjects.values.toList();
      }
      
      final attendance = await _attendanceService.getDailyAttendance(
        _currentSemesterId!,
        dateString,
      );

      // Load subject details for display
      final subjectsMap = <String, Subject>{};
      for (final subjectAttendance in subjects) {
        final subject = await _subjectService.getSubject(_currentSemesterId!, subjectAttendance.subjectId);
        if (subject != null) {
          subjectsMap[subjectAttendance.subjectId] = subject;
        }
      }

      setState(() {
        _selectedDate = targetDate;
        _todaysSubjects = subjects;
        _dailyAttendance = attendance;
        _subjectsMap = subjectsMap;
        _isHoliday = isHoliday;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading subjects: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAttendance(String subjectId, AttendanceStatus status) async {
    if (_currentSemesterId == null) return;

    try {
      // Format selected date
      final dateString = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      await _attendanceService.markAttendance(
        _currentSemesterId!,
        dateString,
        subjectId,
        status,
      );

      // Reload attendance data
      final attendance = await _attendanceService.getDailyAttendance(
        _currentSemesterId!,
        dateString,
      );

      setState(() {
        _dailyAttendance = attendance;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked as ${status.name}'),
            backgroundColor: status == AttendanceStatus.present 
                ? Colors.green 
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<SubjectAttendance> _getFilteredSubjects() {
    switch (_currentFilter) {
      case AttendanceFilter.all:
        return _todaysSubjects;
      case AttendanceFilter.unmarked:
        return _todaysSubjects.where((subject) {
          return _dailyAttendance?.subjects[subject.subjectId]?.status == AttendanceStatus.unmarked;
        }).toList();
      case AttendanceFilter.marked:
        return _todaysSubjects.where((subject) {
          return _dailyAttendance?.subjects[subject.subjectId]?.status != AttendanceStatus.unmarked;
        }).toList();
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  await _authService.signOut();
                  
                  // Force navigation to login screen and clear all previous routes
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthWrapper()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void _toggleTheme() async {
    await _themeManager.toggleTheme();
    if (mounted) {
      Navigator.of(context).pop(); // Close drawer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_themeManager.isDarkMode 
              ? 'Switched to dark theme' 
              : 'Switched to light theme'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'BunkMate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 120, // Reduced height
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28, // Smaller avatar
                      backgroundColor: Colors.white,
                      backgroundImage: _currentUser?.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : null,
                      child: _currentUser?.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 32,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser?.displayName ?? 'BunkMate User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (_currentUser?.email != null)
                            Text(
                              _currentUser!.email!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues( alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentUser?.emailVerified == true ? 'Verified' : 'Unverified',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: _navigateToProfile,
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Semesters'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.pushNamed(context, '/semesters');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('Subjects'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                if (_currentSemesterId != null) {
                  Navigator.pushNamed(context, '/subjects', arguments: _currentSemesterId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a semester first'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Timetable'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                if (_currentSemesterId != null) {
                  Navigator.pushNamed(context, '/timetable', arguments: _currentSemesterId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a semester first'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Analytics'),
              subtitle: const Text('View attendance stats'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                // TODO: Navigate to analytics screen when implemented
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Analytics feature coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Reminders'),
              subtitle: const Text('Never miss a class'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                // TODO: Navigate to reminders screen when implemented
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminders feature coming soon!'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(_themeManager.isDarkMode 
                  ? Icons.light_mode 
                  : Icons.dark_mode),
              title: Text(_themeManager.isDarkMode 
                  ? 'Light Theme' 
                  : 'Dark Theme'),
              onTap: _toggleTheme,
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Theme Debug'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ThemeDebugScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Log out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                const SizedBox(height: 20),
                Text(
                  'Hello, ${_currentUser?.displayName?.split(' ').first ?? 'Student'}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your attendance and stay on top of your classes',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Classes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isToday() ? 'Today\'s Classes' : 'Classes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _loadSubjectsForDate(),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectDate,
                              child: Text(
                                _formatSelectedDate(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _canGoToPreviousDay() ? _goToPreviousDay : null,
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Previous day',
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                          IconButton(
                            onPressed: _canGoToNextDay() ? _goToNextDay : null,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Next day',
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ],
                      ),
                      if (!_isToday()) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _goToToday,
                          icon: const Icon(Icons.today, size: 16),
                          label: const Text('Go to Today'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Options and Bulk Actions
                Column(
                  children: [
                    // Filter Options
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterButton('All', AttendanceFilter.all),
                          _buildFilterButton('Unmarked', AttendanceFilter.unmarked),
                          _buildFilterButton('Marked', AttendanceFilter.marked),
                        ],
                      ),
                    ),
                    
                    // Bulk Marking Buttons
                    if (_shouldShowBulkMarkingButtons()) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Quick Mark: ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildBulkMarkButton(
                              'All Present',
                              Icons.done_all,
                              Colors.green,
                              () => _markAllUnmarked(AttendanceStatus.present),
                            ),
                            const SizedBox(width: 8),
                            _buildBulkMarkButton(
                              'All Absent',
                              Icons.close,
                              Colors.orange,
                              () => _markAllUnmarked(AttendanceStatus.absent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                
                // Content based on loading state
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadSubjectsForDate(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildSubjectsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, AttendanceFilter filter) {
    final isSelected = _currentFilter == filter;
    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkMarkButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    final filteredSubjects = _getFilteredSubjects();
    
    if (filteredSubjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredSubjects.length,
      itemBuilder: (context, index) {
        final subjectAttendance = filteredSubjects[index];
        final subject = _subjectsMap[subjectAttendance.subjectId];
        final attendanceStatus = _dailyAttendance?.subjects[subjectAttendance.subjectId]?.status;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.getCardShadow(),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject?.subjectName ?? 'Unknown Subject',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subjectAttendance.startTime} - ${subjectAttendance.endTime}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (subjectAttendance.roomNo != null && subjectAttendance.roomNo!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Room: ${subjectAttendance.roomNo}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (attendanceStatus != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: attendanceStatus == AttendanceStatus.present
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          attendanceStatus.name.toUpperCase(),
                          style: TextStyle(
                            color: attendanceStatus == AttendanceStatus.present
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: attendanceStatus == AttendanceStatus.present
                            ? null
                            : () => _markAttendance(subjectAttendance.subjectId, AttendanceStatus.present),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Present'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: attendanceStatus == AttendanceStatus.absent
                            ? null
                            : () => _markAttendance(subjectAttendance.subjectId, AttendanceStatus.absent),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Absent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
           _selectedDate.month == now.month &&
           _selectedDate.day == now.day;
  }

  String _formatSelectedDate() {
    if (_isToday()) {
      return 'Today, ${_formatDate(_selectedDate)}';
    } else {
      final daysDifference = DateTime.now().difference(_selectedDate).inDays;
      if (daysDifference == 1) {
        return 'Yesterday, ${_formatDate(_selectedDate)}';
      } else if (daysDifference == -1) {
        return 'Tomorrow, ${_formatDate(_selectedDate)}';
      } else {
        return _formatDate(_selectedDate);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past year
      lastDate: DateTime.now().add(const Duration(days: 30)), // Allow next 30 days
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      await _loadSubjectsForDate(picked);
    }
  }

  void _goToToday() {
    if (!_isToday()) {
      _loadSubjectsForDate(DateTime.now());
    }
  }

  bool _canGoToPreviousDay() {
    final minDate = DateTime.now().subtract(const Duration(days: 365));
    return _selectedDate.isAfter(minDate);
  }

  bool _canGoToNextDay() {
    final maxDate = DateTime.now().add(const Duration(days: 30));
    return _selectedDate.isBefore(maxDate);
  }

  void _goToPreviousDay() {
    if (_canGoToPreviousDay()) {
      final previousDay = _selectedDate.subtract(const Duration(days: 1));
      _loadSubjectsForDate(previousDay);
    }
  }

  void _goToNextDay() {
    if (_canGoToNextDay()) {
      final nextDay = _selectedDate.add(const Duration(days: 1));
      _loadSubjectsForDate(nextDay);
    }
  }

  bool _shouldShowBulkMarkingButtons() {
    if (_todaysSubjects.isEmpty) return false;
    
    final now = DateTime.now();
    
    // If selected date is in the future, don't show bulk marking
    if (_selectedDate.isAfter(DateTime(now.year, now.month, now.day))) {
      return false;
    }
    
    // If selected date is in the past (not today), always show bulk marking
    if (!_isToday()) {
      return true;
    }
    
    // For today, check if current time is past the last class end time
    String? latestEndTime;
    for (final subject in _todaysSubjects) {
      if (latestEndTime == null || _compareTimeStrings(subject.endTime, latestEndTime) > 0) {
        latestEndTime = subject.endTime;
      }
    }
    
    if (latestEndTime == null) return false;
    
    // Parse the latest end time and check if current time is past it
    final endTimeParts = latestEndTime.split(':');
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);
    final endDateTime = DateTime(now.year, now.month, now.day, endHour, endMinute);
    
    return now.isAfter(endDateTime);
  }

  int _compareTimeStrings(String time1, String time2) {
    final parts1 = time1.split(':');
    final parts2 = time2.split(':');
    
    final hour1 = int.parse(parts1[0]);
    final minute1 = int.parse(parts1[1]);
    final hour2 = int.parse(parts2[0]);
    final minute2 = int.parse(parts2[1]);
    
    if (hour1 != hour2) {
      return hour1.compareTo(hour2);
    }
    return minute1.compareTo(minute2);
  }

  Future<void> _markAllUnmarked(AttendanceStatus status) async {
    if (_currentSemesterId == null) return;

    final unmarkedSubjects = _todaysSubjects.where((subject) {
      return _dailyAttendance?.subjects[subject.subjectId]?.status == AttendanceStatus.unmarked;
    }).toList();

    if (unmarkedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All classes are already marked for this day'),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Bulk Marking'),
          content: Text(
            'Mark ${unmarkedSubjects.length} unmarked ${unmarkedSubjects.length == 1 ? 'class' : 'classes'} as ${status.name}?\n\n'
            'This action cannot be undone, but you can change individual attendance later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == AttendanceStatus.present 
                    ? Colors.green 
                    : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Mark All ${status.name.toUpperCase()}'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final dateString = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      // Mark all unmarked subjects
      for (final subject in unmarkedSubjects) {
        await _attendanceService.markAttendance(
          _currentSemesterId!,
          dateString,
          subject.subjectId,
          status,
        );
      }

      // Reload attendance data
      await _loadSubjectsForDate(_selectedDate);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked ${unmarkedSubjects.length} classes as ${status.name}'),
            backgroundColor: status == AttendanceStatus.present 
                ? Colors.green 
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getEmptyMessage() {
    if (_isHoliday) {
      return _isToday()
          ? 'Today is a holiday! 🎉\nNo classes scheduled. Enjoy your day off!'
          : 'This was a holiday! 🎉\nNo classes were scheduled.';
    }
    
    final dayContext = _isToday() ? 'today' : 'this day';
    
    switch (_currentFilter) {
      case AttendanceFilter.all:
        return 'No classes scheduled for $dayContext.\n${_isToday() ? 'Enjoy your day off!' : ''}';
      case AttendanceFilter.unmarked:
        return _isToday()
            ? 'All classes have been marked.\nGreat job staying on top of your attendance!'
            : 'All classes were marked for this day.';
      case AttendanceFilter.marked:
        return _isToday()
            ? 'No attendance has been marked yet.\nStart marking your classes as you attend them.'
            : 'No attendance was marked for this day.';
    }
  }
}
