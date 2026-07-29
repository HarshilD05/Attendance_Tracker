import 'dart:math';
import 'package:flutter/material.dart';
import '../models/analytics_data.dart';
import '../config/theme.dart';

// ─── Zone color helper (context-aware) ────────────────────────────────────────

Color _zoneColor(double percentage, double minReq, AppColorScheme colors) {
  if (percentage >= minReq + 5) return colors.attendanceSafe;
  if (percentage >= minReq - 5) return colors.attendanceWarning;
  return colors.attendanceDanger;
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────
// Receives a pre-resolved Color — no context needed inside the painter.

class _DonutPainter extends CustomPainter {
  final double percentage;
  final Color fillColor;
  final Color trackColor;
  final Animation<double> animation;
  final double strokeWidth;

  _DonutPainter({
    required this.percentage,
    required this.fillColor,
    required this.trackColor,
    required this.animation,
    required this.strokeWidth,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final innerRadius = radius - strokeWidth / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = fillColor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, innerRadius, trackPaint);

    final sweepAngle = (percentage / 100) * 2 * pi * animation.value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.percentage != percentage ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor ||
      old.animation.value != animation.value ||
      old.strokeWidth != strokeWidth;
}

// ─── Animated Donut Widget ────────────────────────────────────────────────────

class _AnimatedDonut extends StatefulWidget {
  final double percentage;
  final double minReq;
  final double size;
  final double strokeWidth;
  final double fontSize;

  const _AnimatedDonut({
    required this.percentage,
    required this.minReq,
    this.size = 110,
    this.strokeWidth = 10.0,
    this.fontSize = 16.0,
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
    // Resolve color from theme here (widget has context; painter does not)
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final color = _zoneColor(widget.percentage, widget.minReq, colors);

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
                fillColor: color,
                trackColor: colors.textMuted.withOpacity(0.15),
                animation: _animation,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
          Text(
            '${widget.percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
          Icon(icon, size: 14, color: valueColor ?? Theme.of(context).extension<AppColorScheme>()!.textSecondary),
          const SizedBox(height: 2),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Theme.of(context).extension<AppColorScheme>()!.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Theme.of(context).extension<AppColorScheme>()!.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Legend Row ───────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final Color? labelColor;

  const _LegendRow({required this.color, required this.label, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: labelColor ?? Theme.of(context).extension<AppColorScheme>()!.textPrimary),
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
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final stats = data.stats;
    final pct = stats.percentage;
    final zoneColor = _zoneColor(pct, data.minReq, colors);
    final isSafe = pct >= data.minReq;

    final actionValue = isSafe ? data.missable.toString() : data.toRecover.toString();
    final actionLabel = isSafe ? 'Can Miss' : 'To Recover';
    final actionColor = isSafe ? colors.attendanceSafe : colors.attendanceDanger;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zoneColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: zoneColor.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnimatedDonut(
                percentage: pct,
                minReq: data.minReq,
                size: 110,
                strokeWidth: 10.0,
                fontSize: 16.0,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(color: colors.present, label: '${stats.attended} Present'),
                    const SizedBox(height: 8),
                    _LegendRow(color: colors.absent, label: '${stats.absent} Absent'),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: colors.textMuted,
                      label: '${stats.total} Total',
                      labelColor: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: colors.textMuted.withOpacity(0.15)),
          const SizedBox(height: 12),

          Row(
            children: [
              if (data.remainingLecs != null) ...[
                Expanded(
                  child: _StatTile(
                    label: 'Remaining',
                    value: data.remainingLecs.toString(),
                    icon: Icons.schedule,
                  ),
                ),
                _divider(context),
              ],
              Expanded(
                child: _StatTile(
                  label: actionLabel,
                  value: actionValue,
                  valueColor: actionColor,
                  icon: isSafe ? Icons.check_circle_outline : Icons.trending_up,
                ),
              ),
              _divider(context),
              Expanded(
                child: _StatTile(
                  label: 'Required',
                  value: '${data.minReq.toStringAsFixed(0)}%',
                  icon: Icons.flag_outlined,
                  valueColor: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: Theme.of(context).extension<AppColorScheme>()!.textMuted.withOpacity(0.15),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

// ─── Mini Subject Row ─────────────────────────────────────────────────────────

class SubjectAttendanceRow extends StatelessWidget {
  final SubjectAnalyticsData data;
  final VoidCallback? onTap;

  const SubjectAttendanceRow({Key? key, required this.data, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final pct = data.stats.percentage;
    final zoneColor = _zoneColor(pct, data.minReq, colors);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: zoneColor.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.subjectName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data.stats.attended}/${data.stats.total} lecs',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            // Mini donut: larger (72), thinner stroke (7), smaller font (12)
            _AnimatedDonut(
              percentage: pct,
              minReq: data.minReq,
              size: 72,
              strokeWidth: 7.0,
              fontSize: 12.0,
            ),
          ],
        ),
      ),
    );
  }
}
