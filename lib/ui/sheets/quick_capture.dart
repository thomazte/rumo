import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../state/scope.dart';
import '../../util/dates.dart';
import '../../util/quick_parser.dart';
import '../theme.dart';
import '../widgets/common.dart';

const wideBreakpoint = 900.0;

/// Abre a captura rápida: folha de baixo no celular, diálogo em tela larga.
Future<Task?> showQuickCapture(BuildContext context, {DateTime? defaultDate, String? defaultProjectId}) {
  final content = QuickCapture(defaultDate: defaultDate, defaultProjectId: defaultProjectId);
  if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
    return showDialog<Task>(
      context: context,
      builder: (_) => Dialog(
        alignment: const Alignment(0, -0.4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 20), child: content),
        ),
      ),
    );
  }
  return showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: content,
    ),
  );
}

class QuickCapture extends StatefulWidget {
  const QuickCapture({super.key, this.defaultDate, this.defaultProjectId});

  final DateTime? defaultDate;
  final String? defaultProjectId;

  @override
  State<QuickCapture> createState() => _QuickCaptureState();
}

class _QuickCaptureState extends State<QuickCapture> {
  static const _tokens = ['hoje', 'amanhã', 'sexta', '18h', '#trabalho', '#casa', '#saúde', '#estudos', '!alta', '!media'];

  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  ParsedTask _parsed() {
    final store = context.store;
    final p = parseQuickEntry(_controller.text, projects: store.projects, today: store.today);
    final usesDefaultDate = p.date == null && p.projectId == null;
    return ParsedTask(
      title: p.title,
      date: usesDefaultDate ? widget.defaultDate : p.date,
      minutes: p.minutes,
      projectId: p.projectId ?? widget.defaultProjectId,
      priority: p.priority,
    );
  }

  void _insert(String token) {
    final text = _controller.text.trimRight();
    _controller.text = text.isEmpty ? '$token ' : '$text $token ';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    _focus.requestFocus();
    setState(() {});
  }

  void _submit() {
    final p = _parsed();
    if (p.title.isEmpty) {
      setState(() => _showError = true);
      _focus.requestFocus();
      return;
    }
    final task = context.store.add(
      title: p.title,
      date: p.date,
      minutes: p.minutes,
      projectId: p.projectId,
      priority: p.priority,
    );
    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final rc = context.rc;
    final p = _parsed();
    final project = store.project(p.projectId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('NOVA TAREFA', style: context.tt.labelSmall?.copyWith(color: rc.muted)),
        TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w500, fontFamily: context.tt.bodyLarge?.fontFamily),
          decoration: InputDecoration(
            hintText: 'pagar aluguel sexta 9h #casa !alta',
            errorText: _showError ? 'Escreva o que precisa fazer' : null,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.cs.primary, width: 2)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.cs.primary, width: 2)),
          ),
          onChanged: (_) => setState(() => _showError = false),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Preview(
              icon: Icons.calendar_today_outlined,
              label: p.date == null ? 'Sem data' : relativeDateLabel(p.date!, store.today),
              on: p.date != null,
            ),
            if (p.minutes != null) _Preview(icon: Icons.schedule_rounded, label: formatMinutes(p.minutes!), on: true),
            _Preview(
              icon: Icons.folder_outlined,
              dot: project == null ? null : rc.project(project),
              label: project?.name ?? 'Sem projeto',
              on: project != null,
            ),
            if (p.priority != Priority.none) _Preview(icon: Icons.flag_outlined, label: p.priority.label, on: true),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    store.destinationOf(date: p.date, projectId: p.projectId),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Atalhos', style: TextStyle(color: rc.muted, fontSize: 12)),
            for (final t in _tokens)
              InkWell(
                onTap: () => _insert(t),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(border: Border.all(color: rc.line), borderRadius: BorderRadius.circular(8)),
                  child: Text(t, style: monoStyle(context, color: rc.muted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Data, hora, #projeto e !prioridade são reconhecidos enquanto você escreve.',
                style: TextStyle(color: rc.muted, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(width: 14),
            FilledButton(onPressed: _submit, child: const Text('Adicionar')),
          ],
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.icon, required this.label, required this.on, this.dot});

  final IconData icon;
  final String label;
  final bool on;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final color = on ? context.cs.primary : context.rc.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: on ? context.cs.primaryContainer : context.rc.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ProjectDot(dot!) else Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12.5, color: color, fontWeight: on ? FontWeight.w600 : null)),
        ],
      ),
    );
  }
}
