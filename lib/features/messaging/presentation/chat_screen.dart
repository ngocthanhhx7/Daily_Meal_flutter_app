import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
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
    super.key,
  });
  final String conversationId;
  final ChatUser? otherUser;
  final ChatController? controller;
  final String? currentUserId;
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.otherUser?.displayName ?? 'Tin nhắn',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      body: DailyMealBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                Expanded(
                  child: controller.loading && controller.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.messages.length,
                          itemBuilder: (_, index) {
                            final message = controller.messages[index];
                            final mine = message.sender.id == currentUserId;
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 270,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? AppColors.green
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(mine ? 16 : 2),
                                    bottomRight: Radius.circular(mine ? 2 : 16),
                                  ),
                                  border: mine
                                      ? null
                                      : Border.all(color: AppColors.line),
                                ),
                                child: Text(
                                  message.body,
                                  style: TextStyle(
                                    color: mine
                                        ? AppColors.white
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Material(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _body,
                              minLines: 1,
                              maxLines: 5,
                              maxLength: 2000,
                              decoration: const InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                counterText: '',
                              ),
                              onSubmitted: (_) => _send(controller),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            key: const Key('send-message'),
                            tooltip: 'Gửi',
                            onPressed: controller.sending
                                ? null
                                : () => _send(controller),
                            icon: controller.sending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
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
