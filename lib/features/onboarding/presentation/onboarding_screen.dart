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
      backgroundColor: AppColors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390, maxHeight: 844),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/background1.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: SafeArea(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 70, 20, 260),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          interests ? 'Chào bạn!!' : 'Phong cách ăn',
                          style: const TextStyle(
                            fontSize: 30,
                            height: 38 / 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          interests
                              ? 'Bạn là người như thế nào?'
                              : 'Xu hướng ăn của bạn là gì?',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 30),
                        for (
                          var index = 0;
                          index < options.length;
                          index++
                        ) ...[
                          _OnboardingChip(
                            label: options[index],
                            selected: selected.contains(options[index]),
                            alignment: _alignmentFor(index, interests),
                            onPressed: controller.isBusy
                                ? null
                                : () => interests
                                      ? controller.toggleInterest(
                                          options[index],
                                        )
                                      : controller.toggleEatingStyle(
                                          options[index],
                                        ),
                          ),
                          if (index != options.length - 1)
                            const SizedBox(height: 18),
                        ],
                        if (controller.errorMessage case final message?) ...[
                          const SizedBox(height: 16),
                          Text(
                            message,
                            style: const TextStyle(color: AppColors.red),
                          ),
                        ],
                        const SizedBox(height: 30),
                        FilledButton(
                          onPressed: controller.isBusy
                              ? null
                              : interests
                              ? controller.next
                              : () async {
                                  try {
                                    await controller.complete();
                                  } catch (_) {
                                    // Controller exposes the retry message.
                                  }
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: controller.isBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(interests ? 'Tiếp tục' : 'Vào Daily Meal'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, .18),
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(child: Image.asset('assets/logo/logo.png')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Alignment _alignmentFor(int index, bool interests) => switch (index % 5) {
  0 => const Alignment(.9, 0),
  1 => interests ? const Alignment(-.8, 0) : const Alignment(-1, 0),
  2 => const Alignment(.2, 0),
  3 => interests ? Alignment.centerLeft : const Alignment(-.8, 0),
  _ => Alignment.centerRight,
};

class _OnboardingChip extends StatelessWidget {
  const _OnboardingChip({
    required this.label,
    required this.selected,
    required this.alignment,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Alignment alignment;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Material(
        color: selected ? AppColors.green : AppColors.white,
        elevation: 4,
        shadowColor: const Color.fromRGBO(0, 0, 0, .14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 136, minHeight: 31),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 15 / 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
