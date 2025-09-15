import 'package:flutter/material.dart';
import '../services/semester_service.dart';
import '../models/semester.dart';
import 'package:intl/intl.dart';
import 'holiday_screen.dart';

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
              expandedHeight: 200,
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withValues( alpha: 0.8),
                      ],
                    ),
                  ),
                  child: _buildHeaderContent(),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues( alpha: 0.6),
                  indicatorColor: theme.primaryColor,
                  tabs: const [
                    Tab(icon: Icon(Icons.subject), text: 'Subjects'),
                    Tab(icon: Icon(Icons.schedule), text: 'Timetable'),
                    Tab(icon: Icon(Icons.event_busy), text: 'Holidays'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSubjectsTab(),
            _buildTimetableTab(),
            _buildHolidaysTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
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

  Widget _buildFloatingActionButton() {
    // Only show FAB for subjects and timetable tabs
    if (_tabController.index == 2) return const SizedBox.shrink(); // Hide for holidays tab
    
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 0: // Subjects tab
            _showAddSubjectDialog();
            break;
          case 1: // Timetable tab
            _showEditTimetableDialog();
            break;
        }
      },
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildSubjectsTab() {
    return RefreshIndicator(
      onRefresh: _loadSemester,
      child: _semester!.subjectList.isEmpty
          ? _buildEmptySubjects()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _semester!.subjectList.length,
              itemBuilder: (context, index) {
                final subject = _semester!.subjectList[index];
                return _buildSubjectCard(subject);
              },
            ),
    );
  }

  Widget _buildEmptySubjects() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.subject_outlined,
            size: 80,
            color: theme.colorScheme.primary.withValues( alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Subjects Added',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subjects to start tracking attendance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues( alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddSubjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(dynamic subject) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor,
          child: Text(
            subject.code.isNotEmpty ? subject.code[0].toUpperCase() : 'S',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${subject.code}'),
            Text('Teacher: ${subject.teacherName}'),
            Text('Credits: ${subject.credits}'),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'edit') {
              // TODO: Edit subject
            } else if (value == 'delete') {
              _deleteSubject(subject.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          // TODO: Navigate to subject detail
        },
      ),
    );
  }

  Widget _buildTimetableTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Timetable Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Coming Soon...'),
        ],
      ),
    );
  }

  Widget _buildHolidaysTab() {
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: _loadSemester,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Holiday icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues( alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month,
                  size: 64,
                  color: theme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Holiday Management',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Summary
              Text(
                _semester!.holidayList.isEmpty
                    ? 'No holidays configured yet'
                    : '${_semester!.holidayList.length} holidays configured',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 8),
              
              if (_semester!.holidayList.isNotEmpty)
                Text(
                  'Working days: ${_semester!.totalWorkingDays}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Calendar management button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openHolidayCalendar(),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Open Holiday Calendar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Use the calendar to visually select and manage holidays for this semester.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    // TODO: Implement add subject dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add subject feature coming soon')),
    );
  }

  void _showEditTimetableDialog() {
    // TODO: Implement edit timetable dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit timetable feature coming soon')),
    );
  }

  void _deleteSubject(String subjectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject?'),
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
        await _semesterService.removeSubjectFromSemester(_semester!.id!, subjectId);
        await _loadSemester();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting subject: $e')),
          );
        }
      }
    }
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
