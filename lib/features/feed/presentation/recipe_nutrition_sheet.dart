import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/widgets/daily_meal_background.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecipeNutritionSheet extends StatelessWidget {
  const RecipeNutritionSheet({
    required this.post,
    required this.resolver,
    super.key,
  });

  final FeedPost post;
  final MediaUrlResolver resolver;

  List<ImageRecipe> get _recipes {
    if (post.recipes.isNotEmpty) return post.recipes;
    final legacy = post.recipe;
    if (legacy == null ||
        (legacy.title?.isEmpty ?? true) &&
            legacy.ingredients.isEmpty &&
            legacy.steps.isEmpty) {
      return const [];
    }
    return [
      ImageRecipe(
        imageIndex: 0,
        title: legacy.title ?? 'Công thức',
        ingredients: legacy.ingredients,
        steps: legacy.steps,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _recipes;
    return DailyMealBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      tooltip: 'Quay lại',
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left, size: 26),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Công thức',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _AuthorAvatar(post: post, resolver: resolver, size: 36),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (recipes.isEmpty)
                          const _EmptyRecipe()
                        else
                          for (
                            var index = 0;
                            index < recipes.length;
                            index++
                          ) ...[
                            _RecipeCard(
                              recipe: recipes[index],
                              imageUri: _imageUri(recipes[index].imageIndex),
                              stickerUri: resolver.resolve(
                                post.sticker?.assetPath,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        _AuthorChip(post: post, resolver: resolver),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Uri? _imageUri(int index) {
    if (post.images.isEmpty) return null;
    return resolver.resolve(
      post.images[index.clamp(0, post.images.length - 1)].url,
    );
  }
}

class _EmptyRecipe extends StatelessWidget {
  const _EmptyRecipe();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      children: [
        Icon(Icons.content_paste_outlined, size: 40, color: AppColors.muted),
        SizedBox(height: 12),
        Text(
          'Chủ bài viết chưa thêm công thức.',
          style: TextStyle(fontSize: 15, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.imageUri,
    required this.stickerUri,
  });
  final ImageRecipe recipe;
  final Uri? imageUri;
  final Uri? stickerUri;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    elevation: 6,
    shadowColor: Colors.black.withValues(alpha: .2),
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _RecipeArtwork(uri: imageUri),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recipe.title.isEmpty ? 'Công thức' : recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (stickerUri != null)
                Positioned(
                  right: 12,
                  top: 8,
                  child: Image.network(
                    stickerUri.toString(),
                    width: 56,
                    height: 56,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe.ingredients.isNotEmpty) ...[
                const Text(
                  '1. Chuẩn bị nguyên liệu',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final ingredient in recipe.ingredients)
                  Text(
                    '• $ingredient',
                    style: const TextStyle(height: 22 / 14),
                  ),
              ],
              if (recipe.steps.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  '${recipe.ingredients.isEmpty ? 1 : 2}. Cách làm',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < recipe.steps.length; index++)
                  Text(
                    'Bước ${index + 1}: ${recipe.steps[index]}',
                    style: const TextStyle(height: 22 / 14),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecipeArtwork extends StatelessWidget {
  const _RecipeArtwork({this.uri});
  final Uri? uri;
  @override
  Widget build(BuildContext context) {
    const fallback = Image(
      key: Key('recipe-fallback-artwork'),
      image: AssetImage('assets/feed/home-food-main.png'),
      fit: BoxFit.cover,
    );
    if (uri == null) return fallback;
    return Image.network(
      uri.toString(),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.post,
    required this.resolver,
    required this.size,
  });
  final FeedPost post;
  final MediaUrlResolver resolver;
  final double size;
  @override
  Widget build(BuildContext context) {
    final uri = resolver.resolve(post.author.avatarUrl);
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: uri == null
            ? ColoredBox(
                color: AppColors.canvasStrong,
                child: Center(
                  child: Text(
                    post.author.displayName.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : Image.network(
                uri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.canvasStrong,
                  child: Center(
                    child: Text(
                      post.author.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _AuthorChip extends StatelessWidget {
  const _AuthorChip({required this.post, required this.resolver});
  final FeedPost post;
  final MediaUrlResolver resolver;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.center,
    child: Material(
      color: _themeColor(post.author.themeColor),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const Key('recipe-author-chip'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.pushNamed(
          AppRoute.publicProfile.name,
          pathParameters: {'id': post.author.id},
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AuthorAvatar(post: post, resolver: resolver, size: 34),
              const SizedBox(width: 9),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  post.author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  static Color _themeColor(String? value) {
    if (value != null && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      return Color(int.parse('FF${value.substring(1)}', radix: 16));
    }
    return AppColors.green;
  }
}
