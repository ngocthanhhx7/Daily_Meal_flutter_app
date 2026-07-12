import 'dart:io';

import 'package:video_player/video_player.dart';

Future<int?> probeVideoDurationMs(String path) async {
  final controller = VideoPlayerController.file(File(path));
  try {
    await controller.initialize();
    return controller.value.duration.inMilliseconds;
  } finally {
    await controller.dispose();
  }
}
