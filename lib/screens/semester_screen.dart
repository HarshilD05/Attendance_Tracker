import 'package:flutter/material.dart';
import '../services/semester_service.dart';
import '../models/semester.dart';
import 'package:intl/intl.dart';

class SemesterScreen extends StatefulWidget {
  const SemesterScreen({super.key});

  @override
  State<SemesterScreen> createState() => _SemesterScreenState();
}

class _SemesterScreenState extends State<SemesterScreen> {
  final SemesterService _semesterService = SemesterService();
  final Map<String, Map<String, dynamic>> _semesterStats = {};

  Future<Map<String, dynamic>> _getSemesterStats(String semesterId) async {
    if (_semesterStats.containsKey(semesterId)) {
      return _semesterStats[semesterId]!;
    }
    
    try {
      final stats = await _semesterService.getSemesterStats(semesterId);
      _semesterStats[semesterId] = stats;
      return stats;
    } catch (e) {
      // Return default stats on error
      return {
        'subjects': 0,
        'workingDays': 0,
        'holidays': 0,
        'totalDays': 0,
        'daysPassed': 0,
        'progressPercentage': 0,
        'isActive': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Semesters'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<Semester>>(
        stream: _semesterService.getUserSemesters(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading semesters',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final semesters = snapshot.data ?? [];

          if (semesters.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Trigger rebuild
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: semesters.length,
              itemBuilder: (context, index) {
                final semester = semesters[index];
                return FutureBuilder<Map<String, dynamic>>(
                  future: _getSemesterStats(semester.id!),
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? {};
                    return _buildSemesterCard(context, semester, stats, theme);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-semester');
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 120,
              color: theme.colorScheme.primary.withValues( alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Semesters Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first semester to start tracking your attendance',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues( alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add-semester');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Semester'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterCard(BuildContext context, Semester semester, Map<String, dynamic> stats, ThemeData theme) {
    final isActive = stats['isActive'] as bool? ?? false;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context, 
              '/semester-detail',
              arguments: semester.id,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        semester.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade400),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date Range
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues( alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dateFormat.format(semester.semStartDate)} - ${dateFormat.format(semester.semEndDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues( alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatItem(
                      context,
                      Icons.subject,
                      '${stats['subjects'] ?? 0}',
                      'Subjects',
                      theme,
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      context,
                      Icons.schedule,
                      '${stats['workingDays'] ?? 0}',
                      'Working Days',
                      theme,
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      context,
                      Icons.event_busy,
                      '${stats['holidays'] ?? 0}',
                      'Holidays',
                      theme,
                    ),
                  ],
                ),
                
                // Progress indicator
                if (isActive) ...[
                  const SizedBox(height: 16),
                  _buildProgressIndicator(semester, stats, theme),
                ],
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _showDeleteDialog(context, semester);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context, 
                          '/semester-detail',
                          arguments: semester.id,
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues( alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(Semester semester, Map<String, dynamic> stats, ThemeData theme) {
    final progressPercentage = (stats['progressPercentage'] as int? ?? 0);
    final progress = progressPercentage / 100.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semester Progress',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$progressPercentage%',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Semester semester) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text(
          'Are you sure you want to delete "${semester.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        if (semester.id != null) {
          await _semesterService.deleteSemester(semester.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Semester "${semester.name}" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting semester: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
