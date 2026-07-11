import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = MediaUrlResolver(Uri.parse('https://api.dailymeal.site/'));

  test('prefixes relative upload paths exactly once', () {
    expect(
      resolver.resolve('/uploads/avatar.jpg').toString(),
      'https://api.dailymeal.site/uploads/avatar.jpg',
    );
    expect(
      resolver.resolve('uploads/avatar.jpg').toString(),
      'https://api.dailymeal.site/uploads/avatar.jpg',
    );
  });

  test('preserves absolute HTTP and HTTPS URLs', () {
    expect(
      resolver.resolve('https://cdn.example.com/a.jpg').toString(),
      'https://cdn.example.com/a.jpg',
    );
    expect(
      resolver.resolve('http://localhost:4000/uploads/a.jpg').toString(),
      'http://localhost:4000/uploads/a.jpg',
    );
  });

  test('returns null for null, empty, or whitespace-only paths', () {
    expect(resolver.resolve(null), isNull);
    expect(resolver.resolve(''), isNull);
    expect(resolver.resolve('   '), isNull);
  });

  test('retains query parameters and fragments in relative URLs', () {
    expect(
      resolver.resolve('/uploads/a.jpg?v=2#preview').toString(),
      'https://api.dailymeal.site/uploads/a.jpg?v=2#preview',
    );
  });
}
