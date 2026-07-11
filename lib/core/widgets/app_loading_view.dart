import 'package:flutter/material.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Đang tải nội dung',
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
