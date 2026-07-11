import 'package:daily_meal_flutter_app/core/widgets/app_empty_view.dart';
import 'package:daily_meal_flutter_app/core/widgets/app_error_view.dart';
import 'package:daily_meal_flutter_app/core/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';

enum AsyncContentStatus { loading, data, empty, error }

class AsyncContentState<T> {
  const AsyncContentState.loading()
    : status = AsyncContentStatus.loading,
      value = null,
      message = null;

  const AsyncContentState.data(T this.value)
    : status = AsyncContentStatus.data,
      message = null;

  const AsyncContentState.empty([this.message])
    : status = AsyncContentStatus.empty,
      value = null;

  const AsyncContentState.error(this.message)
    : status = AsyncContentStatus.error,
      value = null;

  final AsyncContentStatus status;
  final T? value;
  final String? message;
}

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    required this.state,
    required this.dataBuilder,
    this.onRetry,
    super.key,
  });

  final AsyncContentState<T> state;
  final Widget Function(BuildContext context, T value) dataBuilder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      AsyncContentStatus.loading => const AppLoadingView(),
      AsyncContentStatus.data => dataBuilder(context, state.value as T),
      AsyncContentStatus.empty => AppEmptyView(
        message: state.message ?? 'Chưa có nội dung.',
      ),
      AsyncContentStatus.error => AppErrorView(
        message: state.message ?? 'Không thể tải dữ liệu.',
        onRetry: onRetry,
      ),
    };
  }
}
