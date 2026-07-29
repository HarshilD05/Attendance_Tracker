import 'dart:math';
import 'package:flutter/material.dart';
import '../models/analytics_data.dart';
import '../config/theme.dart';

// ─── Color Logic ──────────────────────────────────────────────────────────────

Color _attendanceColor(double percentage, double minReq) {
  if (percentage >= minReq + 5) return AppTheme.presentColor;      // 🟢 Safe
  if (percentage >= minReq - 5) return const Color(0xFFFFAB40);     // 🟡 Warning
  return AppTheme.absentColor;                                        // 🔴 Danger
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double percentage;
  final double minReq;
  final Animation<double> animation;

  _DonutPainter({
    required this.percentage,
    required this.minReq,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 12.0;
    final innerRadius = radius - strokeWidth;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white12
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = _attendanceColor(percentage, minReq)
      ..strokeCap = StrokeCap.round;

    // Track (background ring)
    canvas.drawCircle(center, innerRadius, trackPaint);

    // Filled arc
    final sweepAngle = (percentage / 100) * 2 * pi * animation.value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -pi / 2,       // Start at top
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.percentage != percentage || old.animation.value != animation.value;
}

// ─── Animated Donut Widget ────────────────────────────────────────────────────

class _AnimatedDonut extends StatefulWidget {
  final double percentage;
  final double minReq;
  final double size;

  const _AnimatedDonut({
    required this.percentage,
    required this.minReq,
    this.size = 110,
  });

  @override
  State<_AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<_AnimatedDonut>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedDonut old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _attendanceColor(widget.percentage, widget.minReq);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (_, __) => CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _DonutPainter(
                percentage: widget.percentage,
                minReq: widget.minReq,
                animation: _animation,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const _StatTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: valueColor ?? Colors.white54),
          const SizedBox(height: 2),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Main Attendance Card ─────────────────────────────────────────────────────

class AttendanceCard extends StatelessWidget {
  final AttendanceCardData data;

  const AttendanceCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = data.stats;
    final pct = stats.percentage;
    final color = _attendanceColor(pct, data.minReq);
    final isSafe = pct >= data.minReq;

    // Missable or recover label
    final actionValue = isSafe ? data.missable.toString() : data.toRecover.toString();
    final actionLabel = isSafe ? 'Can Miss' : 'To Recover';
    final actionColor = isSafe ? AppTheme.presentColor : AppTheme.absentColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Donut + right-side stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnimatedDonut(percentage: pct, minReq: data.minReq),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attended
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.presentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stats.attended} Present',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Absent
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.absentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stats.absent} Absent',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Total
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stats.total} Total',
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Bottom stat grid
          Row(
            children: [
              // Remaining (shown only if not null)
              if (data.remainingLecs != null) ...[
                Expanded(
                  child: _StatTile(
                    label: 'Remaining',
                    value: data.remainingLecs.toString(),
                    icon: Icons.schedule,
                  ),
                ),
                _divider(),
              ],
              // Can Miss / To Recover
              Expanded(
                child: _StatTile(
                  label: actionLabel,
                  value: actionValue,
                  valueColor: actionColor,
                  icon: isSafe ? Icons.check_circle_outline : Icons.trending_up,
                ),
              ),
              _divider(),
              // Min Req
              Expanded(
                child: _StatTile(
                  label: 'Required',
                  value: '${data.minReq.toStringAsFixed(0)}%',
                  icon: Icons.flag_outlined,
                  valueColor: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.white12,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

// ─── Mini Subject Row (for subject lists in Overall + Monthly tabs) ────────────

class SubjectAttendanceRow extends StatelessWidget {
  final SubjectAnalyticsData data;
  final VoidCallback? onTap;

  const SubjectAttendanceRow({Key? key, required this.data, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pct = data.stats.percentage;
    final color = _attendanceColor(pct, data.minReq);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Subject name + fraction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.subjectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data.stats.attended}/${data.stats.total} lecs',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            // Mini donut
            _AnimatedDonut(percentage: pct, minReq: data.minReq, size: 56),
          ],
        ),
      ),
    );
  }
}
