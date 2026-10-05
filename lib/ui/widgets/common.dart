import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../theme.dart';

void showRumoSnack(ScaffoldMessengerState messenger, String message, {VoidCallback? onUndo}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      action: onUndo == null ? null : SnackBarAction(label: 'Desfazer', onPressed: onUndo),
    ));
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.eyebrow, required this.title, this.trailing, this.leading, this.titleColorDot});

  final String eyebrow;
  final String title;
  final Widget? trailing;
  final Widget? leading;
  final Color? titleColorDot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?leading,
                Text(eyebrow.toUpperCase(), style: context.tt.labelSmall?.copyWith(color: context.rc.muted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (titleColorDot != null) ...[
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: titleColorDot, borderRadius: BorderRadius.circular(5)),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(child: Text(title, style: context.tt.displaySmall)),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.count, this.subtitle, this.color});

  final String title;
  final String? count;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: context.tt.titleSmall?.copyWith(color: color)),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(subtitle!, style: context.tt.bodySmall?.copyWith(color: context.rc.muted, fontSize: 13)),
          ],
          const Spacer(),
          if (count != null) Text(count!, style: monoStyle(context, size: 11.5, color: context.rc.muted)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.check_rounded});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(22)),
            child: Icon(icon, size: 32, color: context.cs.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: context.tt.titleMedium),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.rc.muted, fontSize: 14)),
        ],
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.size, this.stroke = 6, this.color, this.child});

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.cs.primary;
    final track = context.rc.ringTrack;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => CustomPaint(
        painter: _RingPainter(v, color, track, stroke),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(rect.center, rect.width / 2, paint..color = track);
    if (value > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.stroke != stroke;
}

/// O círculo de concluir, na cor da prioridade.
class PriorityCheck extends StatelessWidget {
  const PriorityCheck({
    super.key,
    required this.priority,
    required this.done,
    required this.onTap,
    this.size = 22,
    this.semanticLabel,
  });

  final Priority priority;
  final bool done;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = context.rc.priority(priority);
    return Semantics(
      button: true,
      checked: done,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: size,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              color: done ? color : color.withValues(alpha: 0.09),
            ),
            child: AnimatedScale(
              scale: done ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(Icons.check_rounded, size: size * 0.64, color: context.cs.surface),
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectDot extends StatelessWidget {
  const ProjectDot(this.color, {super.key, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.36)),
      );
}
