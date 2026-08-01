import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/analytics_controller.dart';
import '../controllers/semester_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/analytics_data.dart';
import '../models/subject.dart';
import '../widgets/attendance_card.dart';
import '../config/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAll() {
    final sem = Provider.of<SemesterController>(context, listen: false).activeSemester;
    final subjects = Provider.of<SubjectController>(context, listen: false).subjects;
    final ac = Provider.of<AnalyticsController>(context, listen: false);
    if (sem == null) return;
    ac.loadOverallAnalytics(sem, subjects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overall'),
            Tab(text: 'Subject'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverallTab(),
          _SubjectTab(),
          _MonthlyTab(),
        ],
      ),
    );
  }
}

// ─── Shared Loading / Error / Empty Helpers ───────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView(this.message);
  @override
  Widget build(BuildContext context) => Center(
        child: Text(message, style: TextStyle(color: Theme.of(context).extension<AppColorScheme>()!.textSecondary)),
      );
}

// ─── Tab 1: Overall ───────────────────────────────────────────────────────────

class _OverallTab extends StatelessWidget {
  const _OverallTab();

  @override
  Widget build(BuildContext context) {
    final ac = Provider.of<AnalyticsController>(context);
    final sem = Provider.of<SemesterController>(context).activeSemester;
    final subjects = Provider.of<SubjectController>(context).subjects;

    if (ac.isLoading) return const _LoadingView();
    if (sem == null) return const _EmptyView('No active semester.');
    if (ac.overallCard == null) return const _EmptyView('No data yet. Mark some attendance first.');

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<AnalyticsController>(context, listen: false)
            .loadOverallAnalytics(sem, subjects);
      },
      child: ListView(
        children: [
          const SizedBox(height: 8),
          AttendanceCard(data: ac.overallCard!),
          const SizedBox(height: 16),
          if (ac.overallBarData.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'MONTHLY ATTENDANCE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: Theme.of(context).extension<AppColorScheme>()!.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _MonthlyBarChart(
              data: ac.overallBarData,
              minReq: sem.minAttendanceReq,
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'BY SUBJECT',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: Theme.of(context).extension<AppColorScheme>()!.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...ac.subjectCards.map((subData) => SubjectAttendanceRow(data: subData)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Tab 2: Subject ───────────────────────────────────────────────────────────

class _SubjectTab extends StatefulWidget {
  const _SubjectTab();

  @override
  State<_SubjectTab> createState() => _SubjectTabState();
}

class _SubjectTabState extends State<_SubjectTab> {
  Subject? _selectedSubject;
  bool _firstLoadDone = false;

  @override
  Widget build(BuildContext context) {
    final ac = Provider.of<AnalyticsController>(context);
    final sem = Provider.of<SemesterController>(context).activeSemester;
    final subjects = Provider.of<SubjectController>(context).subjects;

    if (sem == null) return const _EmptyView('No active semester.');
    if (subjects.isEmpty) return const _EmptyView('No subjects added yet.');

    // Default to first subject and auto-load on first open
    if (_selectedSubject == null) {
      _selectedSubject = subjects.first;
    }
    if (!_firstLoadDone) {
      _firstLoadDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AnalyticsController>(context, listen: false)
            .loadSubjectAnalytics(sem, _selectedSubject!);
      });
    }

    return Column(
      children: [
        // Subject dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DropdownButtonFormField<Subject>(
            value: _selectedSubject,
            decoration: InputDecoration(
              labelText: 'Select Subject',
              filled: true,
              fillColor: Theme.of(context).extension<AppColorScheme>()!.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (sub) {
              if (sub == null) return;
              setState(() => _selectedSubject = sub);
              Provider.of<AnalyticsController>(context, listen: false)
                  .loadSubjectAnalytics(sem, sub);
            },
          ),
        ),
        const SizedBox(height: 8),
        if (ac.isLoading)
          const Expanded(child: _LoadingView())
        else if (ac.selectedSubjectCard == null)
          const Expanded(child: _EmptyView('Tap a subject to load data.'))
        else
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 8),
                AttendanceCard(data: ac.selectedSubjectCard!),
                const SizedBox(height: 16),
                if (ac.subjectBarData.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      'MONTHLY ATTENDANCE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: Theme.of(context).extension<AppColorScheme>()!.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MonthlyBarChart(
                    data: ac.subjectBarData,
                    minReq: _selectedSubject!.minAttendanceReq,
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Monthly Bar Chart ────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyBarData> data;
  final double minReq;

  const _MonthlyBarChart({required this.data, required this.minReq});

  @override
  Widget build(BuildContext context) {
    const chartHeight = 160.0;
    const barMaxHeight = 120.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppColorScheme>()!.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final barHeight = (d.percentage / 100) * barMaxHeight;
                final colors = Theme.of(context).extension<AppColorScheme>()!;
                final color = d.percentage >= minReq + 5
                    ? colors.attendanceSafe
                    : d.percentage >= minReq - 5
                        ? colors.attendanceWarning
                        : colors.attendanceDanger;
                final barColor = d.isCurrent ? color.withOpacity(0.65) : color;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${d.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 9,
                            color: barColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: ((d.unmarkedPercentage / 100) * barMaxHeight).clamp(0.0, barMaxHeight),
                          decoration: BoxDecoration(
                            color: colors.unmarked,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: (d.percentage == 0 && d.unmarkedPercentage == 0) ? 4.0 : barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(d.unmarkedPercentage > 0 ? 0 : 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Min req line label
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: data.map((d) {
                return Expanded(
                  child: Text(
                    d.monthLabel.substring(0, 3), // "Jul"
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: d.isCurrent ? Theme.of(context).extension<AppColorScheme>()!.textSecondary : Theme.of(context).extension<AppColorScheme>()!.textMuted,
                      fontWeight: d.isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Monthly ───────────────────────────────────────────────────────────

class _MonthlyTab extends StatefulWidget {
  const _MonthlyTab();

  @override
  State<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<_MonthlyTab> {
  bool _initialLoadDone = false;

  void _loadMonth(BuildContext context, String monthKey) {
    final sem = Provider.of<SemesterController>(context, listen: false).activeSemester;
    final subjects = Provider.of<SubjectController>(context, listen: false).subjects;
    if (sem == null) return;
    Provider.of<AnalyticsController>(context, listen: false)
        .loadMonthlyAnalytics(sem, subjects, monthKey);
  }

  @override
  Widget build(BuildContext context) {
    final ac = Provider.of<AnalyticsController>(context);
    final sem = Provider.of<SemesterController>(context).activeSemester;

    if (sem == null) return const _EmptyView('No active semester.');

    final months = ac.availableMonths;
    if (months.isEmpty) return const _EmptyView('No month data available yet.');

    // Auto-load the default month once
    if (!_initialLoadDone && ac.selectedMonthKey != null) {
      _initialLoadDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMonth(context, ac.selectedMonthKey!);
      });
    }

    return Column(
      children: [
        // Month dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DropdownButtonFormField<String>(
            value: ac.selectedMonthKey,
            decoration: InputDecoration(
              labelText: 'Select Month',
              filled: true,
              fillColor: Theme.of(context).extension<AppColorScheme>()!.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: months
                .map((m) => DropdownMenuItem(value: m.key, child: Text(m.label)))
                .toList(),
            onChanged: (key) {
              if (key == null) return;
              _loadMonth(context, key);
            },
          ),
        ),
        const SizedBox(height: 8),
        if (ac.isLoading)
          const Expanded(child: _LoadingView())
        else if (ac.monthlyCard == null)
          const Expanded(child: _EmptyView('No data for this month yet.'))
        else
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 8),
                AttendanceCard(data: ac.monthlyCard!),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'BY SUBJECT',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: Theme.of(context).extension<AppColorScheme>()!.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...ac.monthlySubjectData.map((subData) => SubjectAttendanceRow(data: subData)),
                const SizedBox(height: 24),
              ],
            ),
          ),
      ],
    );
  }
}
