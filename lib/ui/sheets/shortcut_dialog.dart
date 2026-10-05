import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../platform/desktop.dart';
import '../theme.dart';

Future<void> showShortcutDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _ShortcutDialog());

class _ShortcutDialog extends StatefulWidget {
  const _ShortcutDialog();

  @override
  State<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<_ShortcutDialog> {
  bool _busy = false;
  bool _done = false;
  String? _error;

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await installGnomeShortcut();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _done = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final muted = TextStyle(color: rc.muted, fontSize: 13.5, height: 1.45);
    return AlertDialog(
      title: const Text('Atalho global'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperte $gnomeShortcutLabel em qualquer programa para abrir a captura do Rumo. '
              'O botão abaixo cria esse atalho nas configurações de teclado do GNOME.',
              style: muted,
            ),
            const SizedBox(height: 14),
            Text('Para criar à mão: Configurações › Teclado › Atalhos personalizados, com o comando:', style: muted),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              decoration: BoxDecoration(color: rc.surface2, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(child: SelectableText(captureCommand, style: monoStyle(context, size: 12))),
                  IconButton(
                    tooltip: 'Copiar',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => Clipboard.setData(ClipboardData(text: captureCommand)),
                  ),
                ],
              ),
            ),
            if (_done) ...[
              const SizedBox(height: 14),
              Text('Atalho criado. Experimente $gnomeShortcutLabel.', style: TextStyle(color: rc.low, fontWeight: FontWeight.w600)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: rc.high)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_done ? 'Fechar' : 'Agora não')),
        if (!_done)
          FilledButton(
            onPressed: _busy ? null : _install,
            child: Text(_busy ? 'Criando…' : 'Criar atalho $gnomeShortcutLabel'),
          ),
      ],
    );
  }
}
