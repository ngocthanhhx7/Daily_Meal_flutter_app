import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/recipe_nutrition_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders per-image recipes and nutrition detail', (tester) async {
    final post = FeedPost.fromJson({
      '_id': 'post-1',
      'author': {'id': 'user-1', 'displayName': 'Bếp Nhà'},
      'caption': 'Salad',
      'visibility': 'public',
      'recipes': [
        {
          'imageIndex': 0,
          'title': 'Salad gà',
          'ingredients': ['100g ức gà', 'Xà lách'],
          'steps': ['Luộc gà', 'Trộn salad'],
        },
      ],
      'nutritionDetails': [
        {
          'imageIndex': 0,
          'items': [
            {
              'name': 'Ức gà',
              'portion': '100g',
              'calories': 165,
              'protein': 31,
              'carbs': 0,
              'fat': 4,
            },
          ],
          'total': {'calories': 220, 'protein': 33, 'carbs': 10, 'fat': 5},
          'warnings': ['Giá trị dinh dưỡng là ước tính'],
        },
      ],
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T08:00:00Z',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeNutritionSheet(
            post: post,
            resolver: MediaUrlResolver(Uri.parse('https://api.dailymeal.site')),
          ),
        ),
      ),
    );

    expect(find.text('Salad gà'), findsOneWidget);
    expect(find.textContaining('100g ức gà'), findsOneWidget);
    expect(find.text('Bước 2: Trộn salad'), findsOneWidget);
    expect(find.text('Ức gà'), findsOneWidget);
    expect(find.text('220 kcal'), findsOneWidget);
    expect(find.text('Giá trị dinh dưỡng là ước tính'), findsOneWidget);
  });

  testWidgets('renders a clear empty state when recipe data is absent', (
    tester,
  ) async {
    final post = FeedPost.fromJson({
      '_id': 'post-2',
      'author': {'id': 'user-1', 'displayName': 'Meal'},
      'caption': '',
      'visibility': 'public',
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T08:00:00Z',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: RecipeNutritionSheet(
          post: post,
          resolver: MediaUrlResolver(Uri.parse('https://api.dailymeal.site')),
        ),
      ),
    );
    expect(find.text('Chủ bài viết chưa thêm công thức.'), findsOneWidget);
  });
}
