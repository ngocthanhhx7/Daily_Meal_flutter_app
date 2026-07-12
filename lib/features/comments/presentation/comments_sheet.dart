import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/comments/application/comments_controller.dart';
import 'package:daily_meal_flutter_app/features/comments/application/comments_providers.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({this.postId, this.controller, super.key})
    : assert(postId != null || controller != null);

  static const inputKey = Key('comment-input');
  static const sendKey = Key('comment-send');

  final String? postId;
  final CommentsController? controller;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _input = TextEditingController();
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
            const Divider(height: 1),
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
                16,
                10,
                16,
                12 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: CommentsSheet.inputKey,
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        errorText: _validationMessage,
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: CommentsSheet.sendKey,
                    tooltip: 'Gửi bình luận',
                    onPressed: state.isSending ? null : () => _send(controller),
                    icon: state.isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
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
        itemBuilder: (context, index) =>
            _CommentTile(comment: state.comments[index]),
      ),
    };
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final author = comment.author.displayName;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.green,
          child: Text(
            author.characters.first.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.canvasStrong,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 3),
                  Text(comment.body),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
