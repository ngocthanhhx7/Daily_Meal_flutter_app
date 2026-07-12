import 'dart:typed_data';

import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_providers.dart';
import 'package:daily_meal_flutter_app/features/onboarding/application/onboarding_providers.dart';
import 'package:daily_meal_flutter_app/features/onboarding/domain/preference_options.dart';
import 'package:daily_meal_flutter_app/features/post_editor/application/post_editor_providers.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/picked_media.dart';
import 'package:daily_meal_flutter_app/features/profile/application/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const colors = [
    '#8BA58A',
    '#F5B8B5',
    '#9BBAD4',
    '#E9D58E',
    '#EBB390',
    '#CBB5F5',
    '#74746F',
  ];
  static const avatars = {
    'cute_cat': 'Mèo Noodle',
    'cute_dog': 'Cún Chef',
    'cute_rabbit': 'Thỏ Trà Sữa',
    'cute_bear': 'Gấu Bánh',
    'cute_hamster': 'Hamster Dâu',
    'cute_panda': 'Trúc Sữa',
    'cute_dino': 'Dino Xanh',
    'cute_koala': 'Koala Cookie',
    'cute_penguin': 'Cụt Sushi',
    'cute_fox': 'Cáo Cà Phê',
  };
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _birthday = TextEditingController();
  List<String> _interests = [], _eatingStyles = [];
  BirthdayVisibility _visibility = BirthdayVisibility.hidden;
  String _themeColor = colors.first, _avatar = '';
  PickedMedia? _pickedAvatar;
  bool _initialized = false, _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = ref.read(authControllerProvider).state.user;
    if (user != null) {
      _name.text = user.displayName;
      _bio.text = user.bio ?? '';
      _birthday.text = user.birthday?.date ?? '';
      _visibility = user.birthday?.visibility ?? BirthdayVisibility.hidden;
      _themeColor = user.themeColor ?? colors.first;
      _avatar = user.avatarUrl ?? '';
      _interests = [...user.preferences.interests];
      _eatingStyles = [...user.preferences.eatingStyles];
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _birthday.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final values = await ref
        .read(mediaPickerServiceProvider)
        .pickImages(limit: 1);
    if (values.isNotEmpty && mounted) {
      setState(() {
        _pickedAvatar = values.first;
        _avatar = '';
      });
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _name.text.trim();
    final birthday = _birthday.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tên hiển thị không được để trống.');
      return;
    }
    if (birthday.isNotEmpty &&
        (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthday) ||
            DateTime.tryParse(birthday) == null)) {
      setState(() => _error = 'Ngày sinh phải theo định dạng YYYY-MM-DD.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var avatar = _avatar;
      if (_pickedAvatar case final media?) {
        avatar = await ref
            .read(profileRepositoryProvider)
            .uploadImage(
              bytes: media.bytes,
              fileName: media.fileName,
              mimeType: media.mimeType,
              category: 'avatar',
            );
      }
      final current = ref.read(authControllerProvider).state.user!;
      final preferences =
          _same(_interests, current.preferences.interests) &&
              _same(_eatingStyles, current.preferences.eatingStyles)
          ? current.preferences
          : await ref
                .read(onboardingRepositoryProvider)
                .savePreferences(
                  interests: _interests,
                  eatingStyles: _eatingStyles,
                );
      final updated = await ref.read(profileRepositoryProvider).updateMe({
        'displayName': name,
        'bio': _bio.text.trim(),
        'avatarUrl': avatar,
        'themeColor': _themeColor,
        'birthday': {'date': birthday, 'visibility': _visibility.name},
      });
      ref
          .read(authControllerProvider)
          .updateUser(
            AppUser(
              id: current.id,
              email: current.email,
              phone: current.phone,
              displayName: updated.displayName,
              avatarUrl: updated.avatarUrl,
              coverUrl: updated.coverUrl,
              bio: updated.bio,
              birthday: UserBirthday(date: birthday, visibility: _visibility),
              isPremium: current.isPremium,
              premiumTrialUsed: current.premiumTrialUsed,
              premiumTrialStartedAt: current.premiumTrialStartedAt,
              premiumTrialEndsAt: current.premiumTrialEndsAt,
              premiumPaidEndsAt: current.premiumPaidEndsAt,
              streakDays: updated.streakDays,
              themeColor: updated.themeColor,
              preferences: preferences,
              counts: current.counts,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ.')));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể lưu hồ sơ. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DailyMealBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: context.pop,
                        icon: SvgPicture.asset(
                          'assets/icons/Dark/Arrow_Left_circle.svg',
                          width: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Chỉnh sửa cá nhân',
                        style: TextStyle(
                          fontSize: 25,
                          height: 31 / 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _busy ? null : _pickAvatar,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _avatarWidget(76),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Avatar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Chọn ảnh từ máy để làm ảnh đại diện.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Chọn Avatar mẫu dễ thương',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatars.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final entry = avatars.entries.elementAt(i);
                      final value = entry.key;
                      return InkWell(
                        onTap: () => setState(() {
                          _avatar = value;
                          _pickedAvatar = null;
                        }),
                        child: Container(
                          width: 86,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _avatar == value
                                ? AppColors.canvasStrong
                                : AppColors.surface,
                            border: Border.all(
                              color: _avatar == value
                                  ? AppColors.black
                                  : AppColors.line,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/avatar/$value.png',
                                width: 50,
                                height: 50,
                              ),
                              Text(
                                entry.value,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Màu nền bảng tên',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  children: [
                    for (final value in colors)
                      InkWell(
                        onTap: () => setState(() => _themeColor = value),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hex(value),
                            border: Border.all(
                              color: _themeColor == value
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                ),
                TextField(
                  controller: _bio,
                  maxLength: 240,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Giới thiệu'),
                ),
                TextField(
                  controller: _birthday,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Ngày sinh (YYYY-MM-DD)',
                    hintText: '2003-12-31',
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Hiển thị ngày sinh',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final entry in const {
                      BirthdayVisibility.hidden: 'Ẩn',
                      BirthdayVisibility.dayMonth: 'Ngày/tháng',
                      BirthdayVisibility.full: 'Đầy đủ',
                    }.entries) ...[
                      Expanded(
                        child: _SourceSegment(
                          label: entry.value,
                          selected: _visibility == entry.key,
                          onTap: () => setState(() => _visibility = entry.key),
                        ),
                      ),
                      if (entry.key != BirthdayVisibility.full)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sở thích tìm kiếm',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _chips(interestOptions, _interests, (v) => _interests = v),
                const SizedBox(height: 10),
                _chips(
                  eatingStyleOptions,
                  _eatingStyles,
                  (v) => _eatingStyles = v,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(_busy ? 'Đang lưu...' : 'Lưu hồ sơ'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _busy ? null : context.pop,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _avatarWidget(double size) {
    if (_pickedAvatar case final media?) {
      return ClipOval(
        child: Image.memory(
          Uint8List.fromList(media.bytes),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    if (_avatar.startsWith('cute_')) {
      return ClipOval(
        child: Image.asset(
          'assets/avatar/$_avatar.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final uri = ref.read(mediaUrlResolverProvider).resolve(_avatar);
    if (uri != null) {
      return ClipOval(
        child: Image.network(
          uri.toString(),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final initial = _name.text.characters.isEmpty
        ? 'D'
        : _name.text.characters.first.toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _hex(_themeColor),
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _chips(
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> update,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final option in options)
        _SourcePreferenceChip(
          label: option,
          selected: selected.contains(option),
          onTap: () => setState(() {
            final next = [...selected];
            next.contains(option) ? next.remove(option) : next.add(option);
            update(next);
          }),
        ),
    ],
  );
  static Color _hex(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));
  static bool _same(List<String> left, List<String> right) =>
      left.length == right.length && left.every(right.contains);
}

class _SourceSegment extends StatelessWidget {
  const _SourceSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.black : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: selected ? AppColors.black : AppColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 40,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ),
    ),
  );
}

class _SourcePreferenceChip extends StatelessWidget {
  const _SourcePreferenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.black : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: selected ? AppColors.black : AppColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 34),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ),
    ),
  );
}
