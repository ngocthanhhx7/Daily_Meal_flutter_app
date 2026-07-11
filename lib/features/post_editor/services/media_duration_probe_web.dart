import 'package:video_player/video_player.dart';

Future<int?> probeVideoDurationMs(String path) async {
  final controller = VideoPlayerController.networkUrl(Uri.parse(path));
  try {
    await controller.initialize();
    return controller.value.duration.inMilliseconds;
  } finally {
    await controller.dispose();
  }
}
