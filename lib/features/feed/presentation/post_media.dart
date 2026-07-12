import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

bool shouldPlayVisibleVideo(double visibleFraction) => visibleFraction >= 0.65;

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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Future<void>.delayed(
      reduceMotion ? Duration.zero : const Duration(milliseconds: 550),
      () {
        if (mounted) setState(() => _showHeart = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoUri = widget.resolver.resolve(widget.post.video?.url);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              child: AnimatedScale(
                scale: _showHeart ? 1 : 0.55,
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
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
  @override
  Widget build(BuildContext context) {
    final images = widget.images.take(3).toList(growable: false);
    return SizedBox(
      height: 390,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth * 0.72;
          final cardHeight = 330.0;
          final offsets = switch (images.length) {
            1 => [Offset((constraints.maxWidth - cardWidth) / 2, 22)],
            2 => [
              const Offset(8, 35),
              Offset(constraints.maxWidth - cardWidth - 8, 10),
            ],
            _ => [
              const Offset(4, 42),
              Offset((constraints.maxWidth - cardWidth) / 2, 4),
              Offset(constraints.maxWidth - cardWidth - 4, 48),
            ],
          };
          final rotations = switch (images.length) {
            1 => [0.0],
            2 => [-0.055, 0.045],
            _ => [-0.075, 0.02, 0.07],
          };
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < images.length; index++)
                Positioned(
                  left: offsets[index].dx,
                  top: offsets[index].dy,
                  width: cardWidth,
                  height: cardHeight,
                  child: Transform.rotate(
                    angle: rotations[index],
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.34),
                            offset: Offset(0, 16),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          images[index].toString(),
                          fit: BoxFit.cover,
                          semanticLabel: 'Ảnh món ăn ${index + 1}',
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                                color: Color(0xFFECE9DF),
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({required this.uri, super.key});
  final Uri uri;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _visible = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.networkUrl(widget.uri)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller
          ..setLooping(true)
          ..setVolume(0);
        if (_visible) _controller.play();
        setState(() {});
      });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller.pause();
    } else if (_visible && _controller.value.isInitialized) {
      _controller.play();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visible = shouldPlayVisibleVideo(info.visibleFraction);
    if (_visible == visible) return;
    _visible = visible;
    if (!_controller.value.isInitialized) return;
    visible ? _controller.play() : _controller.pause();
  }

  void _toggleMute() {
    if (!_controller.value.isInitialized) return;
    setState(() => _muted = !_muted);
    _controller.setVolume(_muted ? 0 : 1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video-visibility-${widget.uri}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Semantics(
        button: true,
        label: _muted ? 'Video đang tắt tiếng' : 'Video đang bật tiếng',
        child: GestureDetector(
          onTap: _toggleMute,
          child: AspectRatio(
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
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Chip(
                    avatar: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      size: 18,
                    ),
                    label: const Text('Video'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
