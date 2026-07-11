import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostMedia extends StatelessWidget {
  const PostMedia({required this.post, required this.resolver, super.key});

  final FeedPost post;
  final MediaUrlResolver resolver;

  @override
  Widget build(BuildContext context) {
    final videoUri = resolver.resolve(post.video?.url);
    if (post.mediaType == PostMediaType.video && videoUri != null) {
      return FeedVideoPlayer(uri: videoUri);
    }
    final images = post.images
        .map((image) => resolver.resolve(image.url))
        .whereType<Uri>()
        .toList(growable: false);
    if (images.isEmpty) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: ColoredBox(
          color: Color(0xFFECE9DF),
          child: Center(
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 52,
              color: Color(0xFF8BA58A),
              semanticLabel: 'Bài viết chưa có ảnh',
            ),
          ),
        ),
      );
    }
    return _ImageCarousel(images: images);
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images});
  final List<Uri> images;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) => Image.network(
              widget.images[index].toString(),
              fit: BoxFit.cover,
              semanticLabel: 'Ảnh món ăn ${index + 1}',
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFFECE9DF),
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.all(10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  '${_page + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({required this.uri, super.key});
  final Uri uri;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.uri)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _controller.value.isInitialized
          ? _controller.value.aspectRatio
          : 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller.value.isInitialized)
            VideoPlayer(_controller)
          else
            const ColoredBox(
              color: Colors.black12,
              child: Center(child: CircularProgressIndicator()),
            ),
          Center(
            child: IconButton.filledTonal(
              tooltip: _controller.value.isPlaying ? 'Tạm dừng' : 'Phát video',
              onPressed: _controller.value.isInitialized
                  ? () => setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    })
                  : null,
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
