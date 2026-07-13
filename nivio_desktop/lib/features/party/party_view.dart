import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/models/watch_party_models.dart';
import '../../shared/theme/index.dart';
import '../../shared/widgets/widgets.dart';
import 'services/watch_party_identity.dart';
import 'services/watch_party_service_supabase.dart';
import 'services/watch_party_supabase_config.dart';

class PartyView extends StatefulWidget {
  const PartyView({super.key});

  @override
  State<PartyView> createState() => _PartyViewState();
}

class _PartyViewState extends State<PartyView> {
  final WatchPartyIdentityStore _identityStore = WatchPartyIdentityStore();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final List<WatchPartyChatMessage> _messages = [];
  final List<WatchPartyReaction> _reactions = [];

  WatchPartyServiceSupabase? _service;
  WatchPartySession? _session;
  StreamSubscription<WatchPartySession?>? _sessionSub;
  StreamSubscription<WatchPartyChatMessage>? _chatSub;
  StreamSubscription<WatchPartyReaction>? _reactionSub;
  StreamSubscription<String>? _errorSub;

  bool _isInitializing = true;
  bool _isLoading = false;
  bool _isControllerUpdating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _chatSub?.cancel();
    _reactionSub?.cancel();
    _errorSub?.cancel();
    _service?.dispose();
    _codeController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: LoadingView(message: 'Loading party...'));
    }

    if (!WatchPartySupabaseConfig.isAvailable || _service == null) {
      return PageContainer(
        child: Center(
          child: EmptyState(
            title: 'Watch Party unavailable',
            message:
                'Add SUPABASE_URL and SUPABASE_ANON_KEY to .env, then restart the desktop app.',
            actionLabel: 'Retry',
            onAction: _initialize,
          ),
        ),
      );
    }

    return DesktopScrollbar(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(
                title: 'Party',
                subtitle: 'Create or join a synchronized watch party',
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_error != null) ...[
                _ErrorBanner(message: _error!, onDismiss: _clearError),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (_session == null) _buildLobby() else _buildSession(_session!),
              const SizedBox(height: AppSpacing.massive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLobby() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.standard;
        final create = _LobbyPanel(
          title: 'Start Watch Party',
          message: 'Create a room and share the party code with friends.',
          child: PrimaryButton(
            label: 'Start Watch Party',
            icon: const Icon(Icons.add),
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _startParty,
          ),
        );
        final join = _LobbyPanel(
          title: 'Join Party',
          message: 'Enter the 6-character invite code from the host.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _codeController,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Party code',
                  counterText: '',
                ),
                onSubmitted: (_) => _joinParty(),
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Join Party',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _joinParty,
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: create),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: join),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            create,
            const SizedBox(height: AppSpacing.xl),
            join,
          ],
        );
      },
    );
  }

  Widget _buildSession(WatchPartySession session) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.standard;
        final info = _SessionInfoPanel(
          session: session,
          service: _service!,
          isControllerUpdating: _isControllerUpdating,
          onCopyCode: () => _copyCode(session.sessionCode),
          onLeaveOrEnd: _leaveOrEndParty,
          onSetController: _setPlaybackController,
          onOpenPlayback: _openPlayback,
        );
        final chat = _ChatPanel(
          messages: _messages,
          reactions: _reactions,
          controller: _chatController,
          onSendMessage: _sendChatMessage,
          onSendReaction: _sendReaction,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: info),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(width: 380, child: chat),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            info,
            const SizedBox(height: AppSpacing.xl),
            chat,
          ],
        );
      },
    );
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      await WatchPartySupabaseConfig.initializeIfConfigured();
      if (!WatchPartySupabaseConfig.isAvailable) {
        return;
      }

      final identity = await _identityStore.load();
      final service = WatchPartyServiceSupabase(
        userId: identity.userId,
        userName: identity.userName,
        userPhotoUrl: identity.userPhotoUrl,
      );

      await _sessionSub?.cancel();
      await _chatSub?.cancel();
      await _reactionSub?.cancel();
      await _errorSub?.cancel();

      _service?.dispose();
      _service = service;
      _sessionSub = service.sessionStream.listen((session) {
        if (!mounted) return;
        setState(() => _session = session);
      });
      _chatSub = service.chatStream.listen((message) {
        if (!mounted) return;
        setState(() => _messages.add(message));
      });
      _reactionSub = service.reactionStream.listen((reaction) {
        if (!mounted) return;
        setState(() {
          _reactions.add(reaction);
          if (_reactions.length > 12) _reactions.removeAt(0);
        });
      });
      _errorSub = service.errorStream.listen((message) {
        if (!mounted) return;
        setState(() => _error = message);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Failed to initialize watch party: $error');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _startParty() async {
    final service = _service;
    if (service == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final code = await service.createSession();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (code == null) {
      setState(() => _error = 'Failed to create watch party.');
      return;
    }

    _showMessage('Party started. Share code $code.');
  }

  Future<void> _joinParty() async {
    final service = _service;
    if (service == null) return;

    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Enter a valid 6-character code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final joined = await service.joinSession(code);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!joined) {
      setState(() => _error = 'No watch party found for this code.');
      return;
    }

    await service.requestStateSync(reason: 'participant_joined_waiting');
    Future.delayed(const Duration(milliseconds: 1200), () {
      final currentService = _service;
      if (!mounted ||
          currentService == null ||
          !currentService.isInSession ||
          currentService.isHost) {
        return;
      }
      unawaited(currentService.requestStateSync(reason: 'participant_retry'));
    });

    _showMessage('Joined. Waiting for host playback sync...');
  }

  Future<void> _leaveOrEndParty() async {
    final service = _service;
    if (service == null) return;

    if (service.isHost) {
      await service.endSession();
      _showMessage('Watch party ended');
    } else {
      await service.leaveSession();
      _showMessage('Left watch party');
    }
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _reactions.clear();
    });
  }

  Future<void> _setPlaybackController(String? participantId) async {
    final service = _service;
    if (service == null || _isControllerUpdating) return;

    setState(() => _isControllerUpdating = true);
    await service.setPlaybackController(participantId);
    if (!mounted) return;
    setState(() => _isControllerUpdating = false);
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code.toUpperCase()));
    _showMessage('Code copied');
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    await _service?.sendChatMessage(text);
    _chatController.clear();
  }

  Future<void> _sendReaction(String emoji) async {
    await _service?.sendReaction(emoji);
  }

  void _openPlayback(WatchPartyPlaybackState playback) {
    _showMessage(
      'Desktop player integration is pending. Media ${playback.mediaId} is synced.',
    );
  }

  void _clearError() {
    setState(() => _error = null);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LobbyPanel extends StatelessWidget {
  const _LobbyPanel({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.body),
            const SizedBox(height: AppSpacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

class _SessionInfoPanel extends StatelessWidget {
  const _SessionInfoPanel({
    required this.session,
    required this.service,
    required this.isControllerUpdating,
    required this.onCopyCode,
    required this.onLeaveOrEnd,
    required this.onSetController,
    required this.onOpenPlayback,
  });

  final WatchPartySession session;
  final WatchPartyServiceSupabase service;
  final bool isControllerUpdating;
  final VoidCallback onCopyCode;
  final VoidCallback onLeaveOrEnd;
  final ValueChanged<String?> onSetController;
  final ValueChanged<WatchPartyPlaybackState> onOpenPlayback;

  @override
  Widget build(BuildContext context) {
    final playback = session.playbackState;
    final controller = session.controllerId == null
        ? null
        : session.participants
              .where((participant) => participant.id == session.controllerId)
              .firstOrNull;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Room ${session.sessionCode}',
                    style: AppTypography.sectionTitle,
                  ),
                ),
                SecondaryButton(label: 'Copy Code', onPressed: onCopyCode),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${session.participantCount} participants',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final participant in session.participants)
                  _ParticipantChip(
                    participant: participant,
                    isController: participant.id == session.controllerId,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              controller == null
                  ? 'Delegated controller: None (host controls)'
                  : 'Delegated controller: ${controller.name} (host also controls)',
              style: AppTypography.caption,
            ),
            if (service.isHost) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SecondaryButton(
                    label: 'Host Controls',
                    onPressed:
                        isControllerUpdating || session.controllerId == null
                        ? null
                        : () => onSetController(null),
                  ),
                  for (final participant in session.participants.where(
                    (p) => !p.isHost,
                  ))
                    SecondaryButton(
                      label: 'Give ${participant.name} Control',
                      onPressed:
                          isControllerUpdating ||
                              session.controllerId == participant.id
                          ? null
                          : () => onSetController(participant.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _PlaybackPanel(playback: playback, onOpenPlayback: onOpenPlayback),
            const SizedBox(height: AppSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: SecondaryButton(
                label: service.isHost ? 'End Party' : 'Leave Party',
                onPressed: onLeaveOrEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  const _ParticipantChip({
    required this.participant,
    required this.isController,
  });

  final WatchPartyParticipant participant;
  final bool isController;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(child: Text(_initials(participant.name))),
      label: Text(
        participant.isHost ? '${participant.name} (Host)' : participant.name,
      ),
      side: BorderSide(
        color: isController ? AppColors.primary : AppColors.borderSubtle,
      ),
      labelStyle: TextStyle(
        color: isController ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _PlaybackPanel extends StatelessWidget {
  const _PlaybackPanel({required this.playback, required this.onOpenPlayback});

  final WatchPartyPlaybackState? playback;
  final ValueChanged<WatchPartyPlaybackState> onOpenPlayback;

  @override
  Widget build(BuildContext context) {
    final state = playback;
    if (state == null) {
      return const EmptyState(
        title: 'Waiting for playback',
        message: 'The host has not started shared playback yet.',
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current media ${state.mediaId}', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${state.mediaType.isEmpty ? 'movie' : state.mediaType} • S${state.season} E${state.episode} • ${state.isPlaying ? 'Playing' : 'Paused'} • ${state.expectedPositionMs ~/ 1000}s',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Go To Playback',
              onPressed: () => onOpenPlayback(state),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.messages,
    required this.reactions,
    required this.controller,
    required this.onSendMessage,
    required this.onSendReaction,
  });

  final List<WatchPartyChatMessage> messages;
  final List<WatchPartyReaction> reactions;
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final ValueChanged<String> onSendReaction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Chat', style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 260,
              child: messages.isEmpty
                  ? const Center(child: Text('No messages yet.'))
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return ListTile(
                          dense: true,
                          title: Text(message.senderName),
                          subtitle: Text(message.text),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Send a message'),
              onSubmitted: (_) => onSendMessage(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Send',
                    onPressed: onSendMessage,
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final emoji in const ['👍', '😂', '🔥', '😮', '❤️'])
                  ActionChip(
                    label: Text(emoji),
                    onPressed: () => onSendReaction(emoji),
                  ),
              ],
            ),
            if (reactions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final reaction in reactions.reversed.take(8))
                    Chip(
                      label: Text('${reaction.emoji} ${reaction.senderName}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
