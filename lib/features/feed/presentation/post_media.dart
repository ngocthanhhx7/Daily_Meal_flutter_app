import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedImageFrame {
  const FeedImageFrame({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.rotation = 0,
  });
  final double left, top, width, height, rotation;
}

List<FeedImageFrame> collapsedFeedImageFrames(
  PostLayout layout,
  int count,
  double width,
  double height,
) {
  final limit = count.clamp(1, 4);
  List<(double, double, double, double, double)> values;
  if (count == 1) {
    values = const [(.04, .06, .92, .88, 0)];
  } else if (layout == PostLayout.grid && limit == 2) {
    values = const [(.02, .14, .55, .72, -2), (.43, .14, .55, .72, 2)];
  } else if (layout == PostLayout.grid && limit == 4) {
    values = const [
      (.05, .13, .52, .42, -2),
      (.47, .15, .48, .42, 2),
      (.12, .55, .44, .34, -1),
      (.54, .58, .38, .30, 1),
    ];
  } else {
    values = const [
      (.02, .09, .82, .82, -6),
      (.12, .04, .82, .82, 3),
      (.06, .11, .82, .82, 0),
      (.17, .17, .72, .72, -2),
    ];
  }
  return [
    for (var i = 0; i < limit; i++)
      FeedImageFrame(
        left: values[i].$1 * width,
        top: values[i].$2 * height,
        width: values[i].$3 * width,
        height: values[i].$4 * height,
        rotation: values[i].$5,
      ),
  ];
}

List<FeedImageFrame> spreadFeedImageFrames(
  int count,
  double width,
  double height,
) {
  final limit = count.clamp(1, 4);
  final gap = (width * .032).clamp(10.0, double.infinity).toDouble();
  final column = (width - gap) / 2;
  if (limit == 2) {
    final h = _bounded(height * .62, column * 1.58);
    return [
      FeedImageFrame(
        left: 0,
        top: _bounded(height * .32, height - h - 48),
        width: column,
        height: h,
      ),
      FeedImageFrame(
        left: column + gap,
        top: height * .22,
        width: column,
        height: h,
      ),
    ];
  }
  if (limit == 3) {
    final top = height * .15, heroW = width * .56, rightW = width - heroW - gap;
    final heroH = _bounded(height * .44, heroW * 1.08),
        rightH = _bounded(height * .4, rightW * 1.28);
    final bottomW = _bounded(heroW * .64, width * .38),
        bottomH = _bounded(bottomW * 1.32, height - (top + heroH + gap) - 24);
    return [
      FeedImageFrame(left: 0, top: top, width: heroW, height: heroH),
      FeedImageFrame(
        left: heroW + gap,
        top: top + heroH * .5,
        width: rightW,
        height: rightH,
      ),
      FeedImageFrame(
        left: heroW * .35,
        top: top + heroH + gap,
        width: bottomW,
        height: bottomH,
      ),
    ];
  }
  final leftW = width * .53, rightW = width - leftW - gap, top = height * .2;
  final leftH = _bounded(height * .42, leftW * 1.08),
      rightH = _bounded(height * .48, rightW * 1.48);
  final bottomLeftW = leftW * .72, bottomRightW = rightW * .72;
  return [
    FeedImageFrame(left: 0, top: top, width: leftW, height: leftH),
    FeedImageFrame(left: leftW + gap, top: top, width: rightW, height: rightH),
    FeedImageFrame(
      left: leftW * .28,
      top: top + leftH + gap,
      width: bottomLeftW,
      height: _bounded(height * .27, bottomLeftW * 1.12),
    ),
    FeedImageFrame(
      left: leftW + gap,
      top: top + rightH + gap,
      width: bottomRightW,
      height: _bounded(height * .26, bottomRightW * 1.2),
    ),
  ];
}

double _bounded(double value, double maximum) =>
    value.clamp(0.0, maximum.clamp(0.0, double.infinity)).toDouble();

bool shouldPlayVisibleVideo(double visibleFraction) => visibleFraction >= 0.65;

int feedImageCacheWidth(double logicalWidth, double devicePixelRatio) =>
    (logicalWidth * devicePixelRatio).round().clamp(320, 2048);

class PostMedia extends StatefulWidget {
  const PostMedia({
    required this.post,
    required this.resolver,
    required this.onDoubleTapLike,
    this.homeStyle = false,
    super.key,
  });

  final FeedPost post;
  final MediaUrlResolver resolver;
  final VoidCallback onDoubleTapLike;
  final bool homeStyle;

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> {
  bool _showHeart = false;
  bool _spreadOpen = false;

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
          : _ImageCarousel(
              images: images,
              layout: widget.post.layout,
              homeStyle: widget.homeStyle,
              spreadOpen: _spreadOpen,
            );
    }
    return GestureDetector(
      key: Key('post-media-${widget.post.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.homeStyle && widget.post.images.length > 1
          ? () => setState(() => _spreadOpen = !_spreadOpen)
          : null,
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
  const _ImageCarousel({
    required this.images,
    required this.layout,
    required this.homeStyle,
    required this.spreadOpen,
  });
  final List<Uri> images;
  final PostLayout layout;
  final bool homeStyle;
  final bool spreadOpen;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  @override
  Widget build(BuildContext context) {
    final images = widget.images.take(4).toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasHeight = widget.homeStyle
            ? (constraints.maxWidth * 4 / 3).clamp(390.0, 510.0).toDouble()
            : 390.0;
        final frames = widget.homeStyle
            ? (widget.spreadOpen
                  ? spreadFeedImageFrames(
                      images.length,
                      constraints.maxWidth,
                      canvasHeight,
                    )
                  : collapsedFeedImageFrames(
                      widget.layout,
                      images.length,
                      constraints.maxWidth,
                      canvasHeight,
                    ))
            : collapsedFeedImageFrames(
                widget.layout,
                images.length,
                constraints.maxWidth,
                canvasHeight,
              );
        return SizedBox(
          height: canvasHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < images.length; index++)
                AnimatedPositioned(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 420),
                  curve: Curves.easeInOutCubic,
                  left: frames[index].left,
                  top: frames[index].top,
                  width: frames[index].width,
                  height: frames[index].height,
                  child: AnimatedRotation(
                    turns: frames[index].rotation / 360,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 420),
                    curve: Curves.easeInOutCubic,
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
                          cacheWidth: feedImageCacheWidth(
                            frames[index].width,
                            MediaQuery.devicePixelRatioOf(context),
                          ),
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
          ),
        );
      },
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
