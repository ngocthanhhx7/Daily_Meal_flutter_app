import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostMedia extends StatefulWidget {
  const PostMedia({
    required this.post,
    required this.resolver,
    required this.onDoubleTapLike,
    super.key,
  });

  final FeedPost post;
  final MediaUrlResolver resolver;
  final VoidCallback onDoubleTapLike;

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> {
  bool _showHeart = false;

  void _doubleTap() {
    if (!widget.post.viewerState.liked) widget.onDoubleTapLike();
    setState(() => _showHeart = true);
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoUri = widget.resolver.resolve(widget.post.video?.url);
    final Widget media;
    if (widget.post.mediaType == PostMediaType.video && videoUri != null) {
      media = FeedVideoPlayer(uri: videoUri);
    } else {
      final images = widget.post.images
          .map((image) => widget.resolver.resolve(image.url))
          .whereType<Uri>()
          .toList(growable: false);
      media = images.isEmpty
          ? const AspectRatio(
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
            )
          : _ImageCarousel(images: images);
    }
    return GestureDetector(
      key: Key('post-media-${widget.post.id}'),
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _doubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          media,
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showHeart ? 1 : 0,
              duration: const Duration(milliseconds: 140),
              child: AnimatedScale(
                scale: _showHeart ? 1 : 0.55,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 88,
                  color: Color(0xE6FFFFFF),
                  shadows: [Shadow(color: Colors.black38, blurRadius: 12)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
