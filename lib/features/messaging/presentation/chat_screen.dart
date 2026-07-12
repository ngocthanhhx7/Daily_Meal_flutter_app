import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/chat_controller.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/messaging_providers.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.conversationId,
    this.otherUser,
    this.controller,
    this.currentUserId,
    this.mediaResolver,
    super.key,
  });
  final String conversationId;
  final ChatUser? otherUser;
  final ChatController? controller;
  final String? currentUserId;
  final MediaUrlResolver? mediaResolver;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _body = TextEditingController();
  final _scroll = ScrollController();
  ChatController? _owned;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null || _owned != null) return;
    _owned = ChatController(
      ref.read(messagingRepositoryProvider),
      ref.read(realtimeClientProvider),
      conversationId: widget.conversationId,
    )..initialize().catchError((_) {});
  }

  @override
  void dispose() {
    _body.dispose();
    _scroll.dispose();
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? _owned;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => _screen(controller),
    );
  }

  Widget _screen(ChatController controller) {
    final currentUserId =
        widget.currentUserId ??
        ref.watch(authControllerProvider).state.user?.id;
    final MediaUrlResolver resolver =
        widget.mediaResolver ?? ref.watch(mediaUrlResolverProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DailyMealBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _ChatHeader(name: widget.otherUser?.displayName ?? 'Tin nhắn'),
                Expanded(
                  child: controller.loading && controller.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : controller.messages.isEmpty
                      ? const _EmptyChat()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                          itemCount: controller.messages.length,
                          itemBuilder: (_, index) {
                            final message = controller.messages[index];
                            return _ChatMessageRow(
                              message: message,
                              mine: message.sender.id == currentUserId,
                              resolver: resolver,
                            );
                          },
                        ),
                ),
                _Composer(
                  controller: _body,
                  sending: controller.sending,
                  onSend: () => _send(controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send(ChatController controller) async {
    final text = _body.text;
    if (text.trim().isEmpty) return;
    try {
      if (await controller.send(text)) {
        _body.clear();
        await Future<void>.delayed(Duration.zero);
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.'),
          ),
        );
      }
    }
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('source-chat-header'),
    constraints: const BoxConstraints(minHeight: 188),
    padding: const EdgeInsets.fromLTRB(36, 0, 28, 34),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xEB748F73), Color(0xD1748F73), Color(0x00748F73)],
        stops: [0, .62, 1],
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.maybePop(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox.square(
                    dimension: 28,
                    child: Icon(
                      Icons.arrow_back,
                      size: 21,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 42,
                  height: 50 / 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 54,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({
    required this.message,
    required this.mine,
    required this.resolver,
  });
  final ChatMessage message;
  final bool mine;
  final MediaUrlResolver resolver;

  @override
  Widget build(BuildContext context) {
    final time = _time(message.createdAt);
    final avatar = resolver.resolve(message.sender.avatarUrl);
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: EdgeInsets.fromLTRB(mine ? 13 : 8, 9, 13, 9),
      decoration: BoxDecoration(
        color: mine ? AppColors.white : const Color(0xFFC3D0BE),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 7),
          bottomRight: Radius.circular(mine ? 7 : 18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!mine) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: _accent(message.sender.id),
              backgroundImage: avatar == null
                  ? null
                  : NetworkImage(avatar.toString()),
              child: avatar == null
                  ? Text(
                      message.sender.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 9),
          ],
          Flexible(child: Text(message.body)),
        ],
      ),
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (mine) _MessageTime(time),
            if (mine) const SizedBox(width: 7),
            bubble,
            if (!mine) const SizedBox(width: 7),
            if (!mine) _MessageTime(time),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static Color _accent(String seed) {
    const colors = [
      Color(0xFF748F73),
      Color(0xFF9BBAD4),
      Color(0xFFEBB390),
      Color(0xFFCBB5F5),
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }
}

class _MessageTime extends StatelessWidget {
  const _MessageTime(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      value,
      style: const TextStyle(fontSize: 14, color: Color(0x7574746F)),
    ),
  );
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.muted),
          SizedBox(height: 8),
          Text('Gửi lời chào hoặc hỏi công thức món ăn.'),
        ],
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      color: AppColors.white.withValues(alpha: .94),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('send-message'),
              tooltip: 'Gửi',
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    ),
  );
}
