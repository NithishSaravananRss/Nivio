part of 'player_screen.dart';

class _WatchPartyStatusOverlay extends StatefulWidget {
  const _WatchPartyStatusOverlay({
    required this.session,
    required this.isHost,
    required this.canControl,
    required this.connectionLabel,
    required this.controllerLabel,
    required this.statusMessage,
    required this.messages,
    required this.reactions,
    required this.onSendMessage,
    required this.onSendReaction,
    required this.onLeaveOrEnd,
  });

  final WatchPartySession? session;
  final bool isHost;
  final bool canControl;
  final String connectionLabel;
  final String controllerLabel;
  final String? statusMessage;
  final List<WatchPartyChatMessage> messages;
  final List<WatchPartyReaction> reactions;
  final ValueChanged<String> onSendMessage;
  final ValueChanged<String> onSendReaction;
  final VoidCallback onLeaveOrEnd;

  @override
  State<_WatchPartyStatusOverlay> createState() =>
      _WatchPartyStatusOverlayState();
}

class _WatchPartyStatusOverlayState extends State<_WatchPartyStatusOverlay> {
  final TextEditingController _chatController = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Positioned(
      right: 18,
      top: 86,
      child: SafeArea(
        left: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xCC101010),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              session == null
                                  ? 'Watch Party'
                                  : 'Room ${session.sessionCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _PartyPill(
                            label: widget.canControl
                                ? (widget.isHost ? 'Host' : 'Controller')
                                : 'Following',
                            color: widget.canControl
                                ? AppColors.primary
                                : Colors.white24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PartyPill(
                          label: widget.connectionLabel,
                          color: widget.connectionLabel == 'Connected'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        _PartyPill(
                          label: '${session?.participantCount ?? 0} members',
                          color: Colors.white24,
                        ),
                        _PartyPill(
                          label: 'Control: ${widget.controllerLabel}',
                          color: Colors.white24,
                        ),
                      ],
                    ),
                    if (widget.statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.statusMessage!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_expanded) ...[
                      const SizedBox(height: 10),
                      _RecentPartyMessages(messages: widget.messages),
                      if (widget.reactions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final reaction
                                in widget.reactions.reversed.take(5))
                              _PartyPill(
                                label:
                                    '${reaction.emoji} ${reaction.senderName}',
                                color: Colors.white24,
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: widget.onLeaveOrEnd,
                            icon: Icon(
                              widget.isHost
                                  ? Icons.power_settings_new
                                  : Icons.logout_rounded,
                              size: 16,
                            ),
                            label: Text(widget.isHost ? 'End' : 'Leave'),
                          ),
                          const Spacer(),
                          for (final emoji in const ['👍', '😂', '🔥', '😮'])
                            IconButton(
                              tooltip: 'Send $emoji',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => widget.onSendReaction(emoji),
                              icon: Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              minLines: 1,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Message party',
                                hintStyle: TextStyle(color: Colors.white38),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Send message',
                            onPressed: _sendMessage,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _chatController.clear();
  }
}

class _RecentPartyMessages extends StatelessWidget {
  const _RecentPartyMessages({required this.messages});

  final List<WatchPartyChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Text(
        'No party messages yet.',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final message in messages.reversed.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${message.senderName}: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: message.text),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _PartyPill extends StatelessWidget {
  const _PartyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DiagnosticsRow extends StatelessWidget {
  const _DiagnosticsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
