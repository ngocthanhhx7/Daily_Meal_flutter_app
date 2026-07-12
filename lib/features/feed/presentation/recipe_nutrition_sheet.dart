import 'package:daily_meal_flutter_app/app/theme/app_colors.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/material.dart';

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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  'Công thức & dinh dưỡng',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                          ),
                          const SizedBox(height: 16),
                        ],
                      if (post.nutritionDetails.isNotEmpty) ...[
                        Text(
                          'Chi tiết dinh dưỡng',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        for (final detail in post.nutritionDetails) ...[
                          _NutritionCard(detail: detail),
                          const SizedBox(height: 12),
                        ],
                      ] else if (post.nutritionSummary case final summary?) ...[
                        _NutritionSummaryCard(summary: summary),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Uri? _imageUri(int index) {
    if (post.images.isEmpty) return null;
    final safeIndex = index.clamp(0, post.images.length - 1);
    return resolver.resolve(post.images[safeIndex].url);
  }
}

class _EmptyRecipe extends StatelessWidget {
  const _EmptyRecipe();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 46, color: AppColors.muted),
          SizedBox(height: 12),
          Text('Chủ bài viết chưa thêm công thức.'),
        ],
      ),
    ),
  );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.imageUri});
  final ImageRecipe recipe;
  final Uri? imageUri;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUri != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              imageUri.toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: AppColors.canvasStrong,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title.isEmpty ? 'Công thức' : recipe.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (recipe.ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '1. Chuẩn bị nguyên liệu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                for (final ingredient in recipe.ingredients)
                  Text('• $ingredient'),
              ],
              if (recipe.steps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${recipe.ingredients.isEmpty ? 1 : 2}. Cách làm',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                for (var index = 0; index < recipe.steps.length; index++)
                  Text('Bước ${index + 1}: ${recipe.steps[index]}'),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.detail});
  final NutritionDetail detail;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Món ăn ${detail.imageIndex + 1}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final item in detail.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(item.name)),
                  Text(item.portion),
                  const SizedBox(width: 12),
                  Text('${item.calories.round()} kcal'),
                ],
              ),
            ),
          const Divider(),
          Text(
            '${detail.total.calories.round()} kcal',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final warning in detail.warnings)
            Text(warning, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    ),
  );
}

class _NutritionSummaryCard extends StatelessWidget {
  const _NutritionSummaryCard({required this.summary});
  final NutritionSummary summary;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '${summary.calories.round()} kcal • '
        'Protein ${summary.protein.round()}g • '
        'Carb ${summary.carbs.round()}g • Fat ${summary.fat.round()}g',
      ),
    ),
  );
}
