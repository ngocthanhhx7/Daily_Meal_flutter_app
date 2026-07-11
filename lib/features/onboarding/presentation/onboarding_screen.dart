import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/features/onboarding/application/onboarding_controller.dart';
import 'package:daily_meal_flutter_app/features/onboarding/application/onboarding_providers.dart';
import 'package:daily_meal_flutter_app/features/onboarding/domain/preference_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({this.controller, super.key});

  final OnboardingController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingController current;
    if (controller case final provided?) {
      current = provided;
    } else {
      current = ref.watch(onboardingControllerProvider);
    }
    return AnimatedBuilder(
      animation: current,
      builder: (context, _) => _OnboardingBody(controller: current),
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final interests = controller.step == OnboardingStep.interests;
    final options = interests ? interestOptions : eatingStyleOptions;
    final selected = interests ? controller.interests : controller.eatingStyles;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: interests
            ? null
            : IconButton(
                tooltip: 'Quay lại',
                onPressed: controller.isBusy ? null : controller.back,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: const Text('Cá nhân hóa Daily Meal'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(value: interests ? 0.5 : 1),
                      const SizedBox(height: 28),
                      Text(
                        interests
                            ? 'Bạn quan tâm điều gì?'
                            : 'Phong cách ăn uống của bạn?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chọn tối đa 10 mục. Bạn có thể thay đổi sau trong hồ sơ.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final option in options)
                            FilterChip(
                              label: Text(option),
                              selected: selected.contains(option),
                              onSelected: controller.isBusy
                                  ? null
                                  : (_) => interests
                                        ? controller.toggleInterest(option)
                                        : controller.toggleEatingStyle(option),
                            ),
                        ],
                      ),
                      if (controller.errorMessage case final message?) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : interests
                            ? controller.next
                            : () async {
                                try {
                                  await controller.complete();
                                } catch (_) {
                                  // The controller exposes a localized retry message.
                                }
                              },
                        icon: controller.isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                interests
                                    ? Icons.arrow_forward_rounded
                                    : Icons.check_rounded,
                              ),
                        label: Text(interests ? 'Tiếp tục' : 'Hoàn tất'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
