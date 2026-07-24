part of 'player_screen.dart';

class _WatchPartyStatusOverlay extends StatefulWidget {
  const _WatchPartyStatusOverlay({
    required this.visible,
    required this.expanded,
    required this.onExpandedChanged,
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

  final bool visible;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
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

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: widget.expanded
                  ? _ExpandedWatchPartyPanel(
                      key: const ValueKey('watch-party-expanded'),
                      session: widget.session,
                      isHost: widget.isHost,
                      canControl: widget.canControl,
                      connectionLabel: widget.connectionLabel,
                      controllerLabel: widget.controllerLabel,
                      statusMessage: widget.statusMessage,
                      messages: widget.messages,
                      reactions: widget.reactions,
                      chatController: _chatController,
                      onToggle: () => widget.onExpandedChanged(false),
                      onSendMessage: _sendMessage,
                      onSendReaction: widget.onSendReaction,
                      onLeaveOrEnd: widget.onLeaveOrEnd,
                    )
                  : _CompactWatchPartyChip(
                      key: const ValueKey('watch-party-compact'),
                      memberCount: widget.session?.participantCount ?? 0,
                      statusMessage: widget.statusMessage,
                      onTap: () => widget.onExpandedChanged(true),
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

class _CompactWatchPartyChip extends StatelessWidget {
  const _CompactWatchPartyChip({
    super.key,
    required this.memberCount,
    required this.statusMessage,
    required this.onTap,
  });

  final int memberCount;
  final String? statusMessage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC101010),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$memberCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      statusMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedWatchPartyPanel extends StatelessWidget {
  const _ExpandedWatchPartyPanel({
    super.key,
    required this.session,
    required this.isHost,
    required this.canControl,
    required this.connectionLabel,
    required this.controllerLabel,
    required this.statusMessage,
    required this.messages,
    required this.reactions,
    required this.chatController,
    required this.onToggle,
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
  final TextEditingController chatController;
  final VoidCallback onToggle;
  final VoidCallback onSendMessage;
  final ValueChanged<String> onSendReaction;
  final VoidCallback onLeaveOrEnd;

  @override
  Widget build(BuildContext context) {
    final memberCount = session?.participantCount ?? 0;

    return DecoratedBox(
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
              onTap: onToggle,
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
                          : 'Room ${session!.sessionCode}',
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
                    label: canControl
                        ? (isHost ? 'Host' : 'Controller')
                        : 'Following',
                    color: canControl ? AppColors.primary : Colors.white24,
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
                  label: connectionLabel,
                  color: connectionLabel == 'Connected'
                      ? Colors.green
                      : Colors.orange,
                ),
                _PartyPill(
                  label: '$memberCount members',
                  color: Colors.white24,
                ),
                _PartyPill(
                  label: 'Control: $controllerLabel',
                  color: Colors.white24,
                ),
              ],
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                statusMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            _RecentPartyMessages(messages: messages),
            if (reactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final reaction in reactions.reversed.take(5))
                    _PartyPill(
                      label: '${reaction.emoji} ${reaction.senderName}',
                      color: Colors.white24,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onLeaveOrEnd,
                  icon: Icon(
                    isHost ? Icons.power_settings_new : Icons.logout_rounded,
                    size: 16,
                  ),
                  label: Text(isHost ? 'End' : 'Leave'),
                ),
                const Spacer(),
                for (final emoji in const ['👍', '😂', '🔥', '😮'])
                  IconButton(
                    tooltip: 'Send $emoji',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onSendReaction(emoji),
                    icon: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Message party',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                    onSubmitted: (_) => onSendMessage(),
                  ),
                ),
                IconButton(
                  tooltip: 'Send message',
                  onPressed: onSendMessage,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
