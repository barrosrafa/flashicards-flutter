import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/models/socratic_session.dart';
import '../../core/theme/flashi_color_tokens.dart';
import '../../core/theme/flashi_typography.dart';
import '../../core/widgets/cyber_primary_button.dart';

/// Interactive Socratic AI Tutor bottom sheet that guides the user to rediscover
/// the answer to a lapsed card without immediately spoiling it.
///
/// Mirrors `src/components/study/socratic-remediation-modal.tsx` from `app-flashi`.
class SocraticTutorSheet extends StatefulWidget {
  const SocraticTutorSheet({
    super.key,
    required this.cardId,
    required this.cardFront,
    required this.cardBack,
  });

  final String cardId;
  final String cardFront;
  final String cardBack;

  @override
  State<SocraticTutorSheet> createState() => _SocraticTutorSheetState();
}

class _SocraticTutorSheetState extends State<SocraticTutorSheet> {
  final TextEditingController _inputController = TextEditingController();
  SocraticSession? _session;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startOrContinueSession();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _startOrContinueSession({String? userMessage}) async {
    setState(() => _sending = true);
    final ServiceLocator locator = ServiceLocator.instance;
    final SocraticSession updated =
        await locator.socraticRepository.sendTurn(
      userId: locator.activeUserId,
      cardId: widget.cardId,
      cardFront: widget.cardFront,
      cardBack: widget.cardBack,
      sessionId: _session?.id,
      userMessage: userMessage,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _session = updated;
      _sending = false;
    });
  }

  void _handleSend() {
    final String text = _inputController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    _inputController.clear();
    _startOrContinueSession(userMessage: text);
  }

  @override
  Widget build(BuildContext context) {
    final FlashiColorTokens colors = context.flashiColors;
    final List<SocraticMessage> messages =
        _session?.messages ?? const <SocraticMessage>[];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 540),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.borderSpecular),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.psychology_alt_rounded,
                      color: colors.accentViolet,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TUTOR SOCRATICO IA',
                      style: FlashiTypography.monoMetric(
                        color: colors.accentViolet,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final SocraticMessage msg = messages[index];
                  return Align(
                    alignment: msg.isAi
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: msg.isAi
                            ? colors.surfaceGlassPrimary
                            : colors.accentCyan.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: msg.isAi
                              ? colors.borderSpecular
                              : colors.accentCyan.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_session?.status == SocraticStatus.resolved)
              CyberPrimaryButton(
                label: 'Concluir Remediacao Socratica',
                icon: Icons.check_circle_rounded,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: (_) => _handleSend(),
                      decoration: const InputDecoration(
                        hintText: 'Explique seu raciocinio ou pista...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _sending ? null : _handleSend,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
