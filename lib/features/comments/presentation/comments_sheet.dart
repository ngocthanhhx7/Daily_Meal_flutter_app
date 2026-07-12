import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/comments/application/comments_controller.dart';
import 'package:daily_meal_flutter_app/features/comments/application/comments_providers.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({
    this.postId,
    this.controller,
    this.mediaResolver,
    this.currentUserId,
    this.embedded = false,
    super.key,
  }) : assert(postId != null || controller != null);

  static const inputKey = Key('comment-input');
  static const sendKey = Key('comment-send');

  final String? postId;
  final CommentsController? controller;
  final MediaUrlResolver? mediaResolver;
  final String? currentUserId;
  final bool embedded;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null &&
        widget.controller!.state.status == CommentsStatus.idle) {
      widget.controller!.load().catchError((_) {});
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(CommentsController controller) async {
    final body = _input.text.trim();
    if (body.isEmpty || body.length > 500) {
      setState(() {
        _validationMessage = body.isEmpty
            ? 'Vui lòng nhập nội dung bình luận.'
            : 'Bình luận tối đa 500 ký tự.';
      });
      return;
    }
    try {
      await controller.send(body);
      if (!mounted) return;
      _input.clear();
      setState(() => _validationMessage = null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      // Controller state renders the retryable server error.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller case final provided?) {
      return AnimatedBuilder(
        animation: provided,
        builder: (context, _) => _buildBody(provided),
      );
    }
    return _buildBody(ref.watch(commentsControllerProvider(widget.postId!)));
  }

  Widget _buildBody(CommentsController controller) {
    final state = controller.state;
    return DailyMealBackground(
      child: SafeArea(
        child: Column(
          children: [
            if (!widget.embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Text(
                      'Bình luận',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    if (Navigator.canPop(context))
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            if (!widget.embedded) const Divider(height: 1),
            Expanded(child: _commentsBody(state, controller)),
            if (state.errorMessage case final error?)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                10 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: .92),
                  border: const Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        key: CommentsSheet.inputKey,
                        controller: _input,
                        focusNode: _inputFocus,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận...',
                          errorText: _validationMessage,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: CommentsSheet.sendKey,
                      tooltip: 'Gửi bình luận',
                      onPressed: state.isSending
                          ? null
                          : () => _send(controller),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.canvasStrong,
                        foregroundColor: AppColors.greenDark,
                      ),
                      icon: state.isSending
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
          ],
        ),
      ),
    );
  }

  Widget _commentsBody(CommentsState state, CommentsController controller) {
    return switch (state.status) {
      CommentsStatus.idle || CommentsStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      CommentsStatus.failure => Center(
        child: FilledButton.tonalIcon(
          onPressed: () => controller.load().catchError((_) {}),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
        ),
      ),
      CommentsStatus.empty => const Center(
        child: Text('Chưa có bình luận. Hãy là người đầu tiên!'),
      ),
      CommentsStatus.ready => ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: state.comments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _CommentTile(
          comment: state.comments[index],
          resolver: widget.mediaResolver,
          isMine: state.comments[index].author.id == widget.currentUserId,
          onReply: _inputFocus.requestFocus,
        ),
      ),
    };
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.resolver,
    required this.isMine,
    required this.onReply,
  });
  final PostComment comment;
  final MediaUrlResolver? resolver;
  final bool isMine;
  final VoidCallback onReply;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  late int likes = widget.comment.likes;

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final author = comment.author.displayName;
    final avatar = widget.resolver?.resolve(comment.author.avatarUrl);
    final accent = _color(comment.author.themeColor) ?? AppColors.green;
    return Row(
      mainAxisAlignment: widget.isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: widget.isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  author,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: widget.isMine
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onDoubleTap: () => setState(() => likes += 1),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                          padding: EdgeInsets.fromLTRB(
                            widget.isMine ? 14 : 28,
                            11,
                            14,
                            11,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isMine
                                ? AppColors.surface
                                : accent.withValues(alpha: .78),
                            border: widget.isMine
                                ? Border.all(color: AppColors.line)
                                : null,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(comment.body),
                        ),
                      ),
                      if (!widget.isMine)
                        Positioned(
                          left: -10,
                          top: 5,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: accent,
                            backgroundImage: avatar == null
                                ? null
                                : NetworkImage(avatar.toString()),
                            child: avatar == null
                                ? Text(
                                    author.characters.first.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      if (likes > 0)
                        Positioned(
                          right: widget.isMine ? null : 10,
                          left: widget.isMine ? 10 : null,
                          bottom: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (likes > 1)
                                  Text(
                                    '$likes',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                const Icon(
                                  Icons.favorite,
                                  size: 12,
                                  color: AppColors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _relativeTime(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              TextButton(
                onPressed: widget.onReply,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.muted,
                ),
                child: const Text('trả lời', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Color? _color(String? value) {
    if (value == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      return null;
    }
    return Color(int.parse('FF${value.substring(1)}', radix: 16));
  }

  static String _relativeTime(DateTime value) {
    final difference = DateTime.now().toUtc().difference(value.toUtc());
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút';
    if (difference.inDays < 1) return '${difference.inHours} giờ';
    if (difference.inDays < 30) return '${difference.inDays} ngày';
    return '${value.day}/${value.month}/${value.year}';
  }
}
